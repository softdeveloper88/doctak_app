import UIKit
import Flutter
import UserNotifications
import AVKit
import AVFoundation
import CoreMedia
import ReplayKit

// MARK: - AgoraPiPController for native iOS PiP with AVPlayer
@available(iOS 15.0, *)
class AgoraPiPController: NSObject, AVPictureInPictureControllerDelegate {
    
    static let shared = AgoraPiPController()
    
    private var pipController: AVPictureInPictureController?
    private var sampleBufferDisplayLayer: AVSampleBufferDisplayLayer?
    private var pipView: UIView?
    private var pipObservation: NSKeyValueObservation?
    private var appStateObserver: NSObjectProtocol?
    
    // For AVPlayer fallback
    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?
    private var playerLooper: AVPlayerLooper?
    private var queuePlayer: AVQueuePlayer?
    private var playerStatusObservation: NSKeyValueObservation?
    
    // Track user intent and state
    private var userWantsPiP = false
    private var isRestoringUI = false
    private var needsReset = false
    private var videoURL: URL?
    private var pendingStart = false
    private var isStartingPiP = false
    private var isAutoPiPEnabled = false
    
    // Frame update timer for live widget capture
    private var frameUpdateTimer: Timer?
    private var lastFrameData: Data?
    private var useSampleBufferMode = false  // Whether to use live widget frames
    
    // Callback to Flutter
    var onStateChanged: ((String) -> Void)?
    
    private override init() {
        super.init()
        setupAppStateObserver()
    }
    
    private func setupAppStateObserver() {
        appStateObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            print("📺 AgoraPiP: App entered background, pendingStart=\(self.pendingStart), userWantsPiP=\(self.userWantsPiP)")
            if self.pendingStart && self.userWantsPiP {
                self.pendingStart = false
                self.attemptStartPiP()
            }
        }
    }
    
    deinit {
        if let observer = appStateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        frameUpdateTimer?.invalidate()
    }
    
    var isSupported: Bool {
        return AVPictureInPictureController.isPictureInPictureSupported()
    }
    
    var isActive: Bool {
        return pipController?.isPictureInPictureActive ?? false
    }
    
    // MARK: - Update PiP with Flutter Widget Frame
    func updateFrame(_ imageData: Data, width: Int, height: Int) {
        guard useSampleBufferMode else { return }
        lastFrameData = imageData
        
        // Convert image data to sample buffer and enqueue
        if let sampleBuffer = createSampleBuffer(from: imageData, width: width, height: height) {
            DispatchQueue.main.async { [weak self] in
                guard let layer = self?.sampleBufferDisplayLayer else { return }
                
                if layer.status == .failed {
                    layer.flush()
                }
                
                layer.enqueue(sampleBuffer)
            }
        }
    }
    
    private func createSampleBuffer(from imageData: Data, width: Int, height: Int) -> CMSampleBuffer? {
        guard let image = UIImage(data: imageData),
              let cgImage = image.cgImage else {
            return nil
        }
        
        // Create pixel buffer
        var pixelBuffer: CVPixelBuffer?
        let attrs: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]
        
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attrs as CFDictionary,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        
        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else {
            return nil
        }
        
        // Draw image into context
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Create format description
        var formatDescription: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: buffer,
            formatDescriptionOut: &formatDescription
        )
        
        guard let format = formatDescription else { return nil }
        
        // Create timing info
        var timing = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: 30),
            presentationTimeStamp: CMTime(value: Int64(CACurrentMediaTime() * 1000), timescale: 1000),
            decodeTimeStamp: .invalid
        )
        
        // Create sample buffer
        var sampleBuffer: CMSampleBuffer?
        CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: buffer,
            formatDescription: format,
            sampleTiming: &timing,
            sampleBufferOut: &sampleBuffer
        )
        
        return sampleBuffer
    }
    
    func setup() -> Bool {
        // All UIView operations MUST be on main thread
        guard Thread.isMainThread else {
            print("📺 AgoraPiP: setup() called off main thread, dispatching to main")
            var result = false
            DispatchQueue.main.sync {
                result = self.setup()
            }
            return result
        }
        
        guard isSupported else {
            print("📺 AgoraPiP: PiP not supported on this device")
            return false
        }
        
        // If we need a reset, do a full cleanup first
        if needsReset {
            print("📺 AgoraPiP: Performing full reset")
            cleanup()
            needsReset = false
        }
        
        // If already setup and no reset needed, just return
        if pipController != nil && pipController?.isPictureInPicturePossible == true {
            print("📺 AgoraPiP: Already setup and ready")
            return true
        }
        
        // Clean up any existing setup
        cleanup()
        
        // Reset state flags
        isRestoringUI = false
        
        // Create placeholder video for PiP content
        guard let url = createPlaceholderVideo() else {
            print("📺 AgoraPiP: Failed to create placeholder video")
            return false
        }
        videoURL = url
        
        let asset = AVAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        
        // Create a queue player for looping
        queuePlayer = AVQueuePlayer(playerItem: item)
        queuePlayer?.isMuted = true
        queuePlayer?.preventsDisplaySleepDuringVideoPlayback = false
        
        // Create player looper for infinite loop
        playerLooper = AVPlayerLooper(player: queuePlayer!, templateItem: item)
        
        // Start playing immediately so the player becomes ready
        queuePlayer?.play()
        
        // Create player layer
        playerLayer = AVPlayerLayer(player: queuePlayer)
        playerLayer?.videoGravity = .resizeAspectFill
        playerLayer?.backgroundColor = UIColor(red: 0.06, green: 0.12, blue: 0.2, alpha: 1.0).cgColor
        
        // Set the layer's frame before adding
        playerLayer?.frame = CGRect(x: 0, y: 0, width: 180, height: 320)
        
        // Create view to host player layer (9:16 aspect ratio)
        // IMPORTANT: For PiP to work, the view MUST be on-screen with proper dimensions
        // and the player layer must match the view size
        let pipWidth: CGFloat = 180
        let pipHeight: CGFloat = 320
        pipView = UIView(frame: CGRect(x: 0, y: 0, width: pipWidth, height: pipHeight))
        pipView?.backgroundColor = UIColor(red: 0.06, green: 0.12, blue: 0.2, alpha: 1.0)
        
        if let layer = playerLayer {
            layer.frame = CGRect(x: 0, y: 0, width: pipWidth, height: pipHeight)
            pipView?.layer.addSublayer(layer)
        }
        
        // Add view on-screen in a visible but non-intrusive position
        // PiP REQUIRES the player layer to be truly visible in the view hierarchy
        if let window = UIApplication.shared.windows.first {
            let screenBounds = UIScreen.main.bounds
            
            // Position the view full-screen but at the very bottom of the view stack
            // This ensures it's "visible" to the system but covered by the Flutter UI
            pipView?.frame = window.bounds
            pipView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            pipView?.clipsToBounds = true
            pipView?.alpha = 1.0  // Fully opaque (but hidden behind Flutter)
            pipView?.isUserInteractionEnabled = false
            pipView?.isHidden = false
            
            // Insert at index 0 (behind FlutterViewController's view)
            window.insertSubview(pipView!, at: 0)
            
            // Adjust player layer to match
            playerLayer?.frame = window.bounds
            
            print("📺 AgoraPiP: PiP view inserted at back of window hierarchy")
        }
        
        // Create PiP controller from player layer
        guard let layer = playerLayer else {
            print("📺 AgoraPiP: Failed to create player layer")
            return false
        }
        
        // Player layer must have a valid player
        guard layer.player != nil else {
            print("📺 AgoraPiP: Player layer has no player attached")
            return false
        }
        
        // Check if PiP is supported before creating controller
        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            print("📺 AgoraPiP: PiP not supported")
            return false
        }
        
        // Defer PiP controller creation until player is ready
        // This prevents crash on some devices where player isn't ready immediately
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self, let playerLayer = self.playerLayer else { return }
            
            // Double check player is still valid
            guard playerLayer.player != nil else {
                print("📺 AgoraPiP: Player became nil before PiP setup")
                return
            }
            
            print("📺 AgoraPiP: Creating PiP controller (deferred)")
            self.pipController = AVPictureInPictureController(playerLayer: playerLayer)
            self.pipController?.delegate = self
            self.pipController?.canStartPictureInPictureAutomaticallyFromInline = self.isAutoPiPEnabled
            
            // Observe when PiP becomes possible
            self.pipObservation = self.pipController?.observe(\.isPictureInPicturePossible, options: [.new, .initial]) { [weak self] controller, change in
                let isPossible = change.newValue ?? false
                print("📺 AgoraPiP: isPictureInPicturePossible changed to \(isPossible)")
                
                if isPossible && self?.pendingStart == true {
                    self?.pendingStart = false
                    DispatchQueue.main.async {
                        controller.startPictureInPicture()
                        print("📺 AgoraPiP: Starting PiP after becoming possible")
                    }
                }
            }
            
            print("📺 AgoraPiP: PiP controller created successfully")
        }
        
        // Log status after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            let isPossible = self?.pipController?.isPictureInPicturePossible ?? false
            print("📺 AgoraPiP: Setup complete, isPossible after delay: \(isPossible)")
        }
        
        print("📺 AgoraPiP: Setup initiated (PiP controller will be created after player is ready)")
        return true
    }
    
    // Create a placeholder video programmatically
    private func createPlaceholderVideo() -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let videoURL = tempDir.appendingPathComponent("pip_call_placeholder.mp4")
        
        // Check if we already have a cached video
        if FileManager.default.fileExists(atPath: videoURL.path) {
            print("📺 AgoraPiP: Using cached placeholder video")
            return videoURL
        }
        
        // Create the video
        guard createAnimatedVideo(at: videoURL) else {
            print("📺 AgoraPiP: Failed to create animated video")
            return nil
        }
        
        return videoURL
    }
    
    private func createAnimatedVideo(at url: URL) -> Bool {
        let width = 360
        let height = 640
        let duration: Double = 3.0  // 3 second loop
        let fps: Int32 = 30
        let totalFrames = Int(duration * Double(fps))
        
        // Delete existing file
        try? FileManager.default.removeItem(at: url)
        
        guard let writer = try? AVAssetWriter(outputURL: url, fileType: .mp4) else {
            return false
        }
        
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height
        ]
        
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = false
        
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: width,
                kCVPixelBufferHeightKey as String: height
            ]
        )
        
        writer.add(input)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
        
        // Generate frames
        for frameIndex in 0..<totalFrames {
            while !input.isReadyForMoreMediaData {
                Thread.sleep(forTimeInterval: 0.01)
            }
            
            let time = CMTime(value: CMTimeValue(frameIndex), timescale: fps)
            let progress = Double(frameIndex) / Double(totalFrames)
            
            if let pixelBuffer = createVideoFrame(width: width, height: height, progress: progress) {
                adaptor.append(pixelBuffer, withPresentationTime: time)
            }
        }
        
        input.markAsFinished()
        
        let semaphore = DispatchSemaphore(value: 0)
        writer.finishWriting {
            semaphore.signal()
        }
        semaphore.wait()
        
        let success = writer.status == .completed
        print("📺 AgoraPiP: Video creation \(success ? "succeeded" : "failed")")
        return success
    }
    
    private func createVideoFrame(width: Int, height: Int, progress: Double) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let attrs: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        
        CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, attrs as CFDictionary, &pixelBuffer)
        
        guard let buffer = pixelBuffer else { return nil }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        
        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else { return nil }
        
        // Dark blue gradient background
        context.setFillColor(UIColor(red: 0.04, green: 0.1, blue: 0.18, alpha: 1.0).cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        
        // Lighter gradient at bottom
        context.setFillColor(UIColor(red: 0.06, green: 0.14, blue: 0.25, alpha: 0.7).cgColor)
        context.fill(CGRect(x: 0, y: height * 2 / 3, width: width, height: height / 3))
        
        // Animated pulsing circle
        let centerX = CGFloat(width) / 2
        let centerY = CGFloat(height) / 2 - 50
        let pulse = CGFloat(sin(progress * .pi * 2) * 0.1 + 0.9)
        let baseRadius: CGFloat = 55
        let radius = baseRadius * pulse
        
        // Outer glow rings
        context.setFillColor(UIColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 0.15).cgColor)
        let glow1 = radius + 25
        context.fillEllipse(in: CGRect(x: centerX - glow1, y: centerY - glow1, width: glow1 * 2, height: glow1 * 2))
        
        context.setFillColor(UIColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 0.3).cgColor)
        let glow2 = radius + 12
        context.fillEllipse(in: CGRect(x: centerX - glow2, y: centerY - glow2, width: glow2 * 2, height: glow2 * 2))
        
        // Main blue circle
        context.setFillColor(UIColor(red: 0.12, green: 0.45, blue: 0.95, alpha: 1.0).cgColor)
        context.fillEllipse(in: CGRect(x: centerX - radius, y: centerY - radius, width: radius * 2, height: radius * 2))
        
        // Video camera icon
        context.setFillColor(UIColor.white.cgColor)
        let iconW: CGFloat = 38
        let iconH: CGFloat = 26
        let iconX = centerX - iconW / 2 - 5
        let iconY = centerY - iconH / 2
        
        // Camera body
        context.fill(CGRect(x: iconX, y: iconY, width: iconW * 0.68, height: iconH))
        
        // Camera lens (triangle)
        context.move(to: CGPoint(x: iconX + iconW * 0.68, y: iconY + 3))
        context.addLine(to: CGPoint(x: iconX + iconW + 2, y: centerY))
        context.addLine(to: CGPoint(x: iconX + iconW * 0.68, y: iconY + iconH - 3))
        context.closePath()
        context.fillPath()
        
        // Animated dots
        let dotsY = centerY + radius + 40
        for i in 0..<3 {
            let dotPhase = progress + Double(i) * 0.12
            let dotPulse = CGFloat(sin(dotPhase * .pi * 2) * 0.4 + 0.6)
            let dotX = centerX - 16 + CGFloat(i) * 16
            let r: CGFloat = 5 * dotPulse
            context.setFillColor(UIColor.white.withAlphaComponent(0.9).cgColor)
            context.fillEllipse(in: CGRect(x: dotX - r, y: dotsY - r, width: r * 2, height: r * 2))
        }
        
        // "In Call" text line
        context.setFillColor(UIColor.white.withAlphaComponent(0.6).cgColor)
        context.fill(CGRect(x: centerX - 35, y: dotsY + 25, width: 70, height: 4))
        
        return buffer
    }
    
    func setAutoEnabled(_ enabled: Bool) {
        print("📺 AgoraPiP: setAutoEnabled(\(enabled))")
        isAutoPiPEnabled = enabled
        
        if enabled {
            if pipController == nil {
                _ = setup()
            }
            pipController?.canStartPictureInPictureAutomaticallyFromInline = true
        } else {
            pipController?.canStartPictureInPictureAutomaticallyFromInline = false
        }
    }
    
    func start() -> Bool {
        print("📺 AgoraPiP: start() called")
        
        // Check if app is actually in background - PiP only works when backgrounded
        let appState = UIApplication.shared.applicationState
        print("📺 AgoraPiP: App state = \(appState == .background ? "background" : appState == .inactive ? "inactive" : "active")")
        
        // Only proceed if app is not active (must be inactive or background)
        if appState == .active {
            print("📺 AgoraPiP: App is in foreground - PiP will not start. Waiting for background...")
            // Set pending so it can start when app actually goes to background
            userWantsPiP = true
            pendingStart = true
            return true
        }
        
        if isRestoringUI {
            print("📺 AgoraPiP: Ignoring start - UI is being restored")
            return false
        }
        
        userWantsPiP = true
        
        // Ensure we're on main thread
        guard Thread.isMainThread else {
            print("📺 AgoraPiP: start() called off main thread, dispatching to main")
            var result = false
            DispatchQueue.main.sync {
                result = self.start()
            }
            return result
        }
        
        if pipController == nil || needsReset {
            print("📺 AgoraPiP: Setting up...")
            if !setup() {
                return false
            }
            // Give setup time to complete (PiP controller is created async)
            // Return true immediately - the pending start mechanism will handle it
            pendingStart = true
            print("📺 AgoraPiP: Setup initiated, will start via pending mechanism")
            return true
        }
        
        // Ensure player is playing
        queuePlayer?.play()
        
        // Check player status and wait if needed
        let playerStatus = queuePlayer?.currentItem?.status
        let isPossible = pipController?.isPictureInPicturePossible ?? false
        print("📺 AgoraPiP: start() playerStatus = \(String(describing: playerStatus?.rawValue)), isPictureInPicturePossible = \(isPossible)")
        
        // If player is not ready yet, mark pending
        if playerStatus != .readyToPlay {
            print("📺 AgoraPiP: Player not ready yet, marking pending start...")
            pendingStart = true
            playerStatusObservation?.invalidate()
            playerStatusObservation = queuePlayer?.currentItem?.observe(\.status, options: [.new]) { [weak self] item, change in
                guard let self = self else { return }
                if item.status == .readyToPlay {
                    print("📺 AgoraPiP: Player became ready, attempting PiP start")
                    self.playerStatusObservation?.invalidate()
                    self.playerStatusObservation = nil
                    DispatchQueue.main.async {
                        self.attemptStartPiP()
                    }
                } else if item.status == .failed {
                    print("📺 AgoraPiP: Player failed: \(String(describing: item.error?.localizedDescription))")
                    self.onStateChanged?("failed:Player failed to load video")
                }
            }
            return true
        }
        
        // Player is ready, attempt to start PiP immediately (don't use delay for responsive start)
        if isPossible && appState != .active {
            isStartingPiP = true
            pipController?.startPictureInPicture()
            print("📺 AgoraPiP: startPictureInPicture() called immediately")
            // Reset flag after a delay (in case callback doesn't fire)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.isStartingPiP = false
            }
        } else {
            pendingStart = true
            print("📺 AgoraPiP: PiP not possible yet or app still active, waiting...")
        }
        
        return true
    }
    
    private func attemptStartPiP() {
        guard userWantsPiP else {
            print("📺 AgoraPiP: User no longer wants PiP, cancelling")
            return
        }
        
        // Prevent concurrent start attempts
        guard !isStartingPiP else {
            print("📺 AgoraPiP: Already starting PiP, skipping")
            return
        }
        
        // Check if PiP is already active
        guard !isActive else {
            print("📺 AgoraPiP: PiP already active, skipping")
            return
        }
        
        // Ensure we're on main thread
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.attemptStartPiP()
            }
            return
        }
        
        // Check app state - only start if not in foreground
        let appState = UIApplication.shared.applicationState
        if appState == .active {
            print("📺 AgoraPiP: App still active, deferring PiP start")
            pendingStart = true
            return
        }
        
        // Note: Don't change audio session here - Agora manages it for video calls
        // Just ensure the player is ready and playing
        
        // Ensure player is playing
        if queuePlayer?.rate == 0 {
            queuePlayer?.play()
        }
        
        // Check if PiP is currently possible
        let isPossible = pipController?.isPictureInPicturePossible ?? false
        print("📺 AgoraPiP: attemptStartPiP() isPictureInPicturePossible = \(isPossible), appState = \(appState.rawValue)")
        
        if isPossible {
            pendingStart = false
            isStartingPiP = true
            pipController?.startPictureInPicture()
            print("📺 AgoraPiP: startPictureInPicture() called")
            // Reset flag after a delay (in case delegate callback doesn't fire)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.isStartingPiP = false
            }
        } else {
            // Set pending flag - the KVO observer will start PiP when possible
            pendingStart = true
            print("📺 AgoraPiP: PiP not yet possible, waiting via KVO...")
            
            // Also try with a delay as fallback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self, self.pendingStart, self.userWantsPiP else { return }
                guard !self.isStartingPiP else { return }  // Prevent concurrent starts
                
                // Check app state again
                let currentAppState = UIApplication.shared.applicationState
                if currentAppState == .active {
                    print("📺 AgoraPiP: App still active in delayed check, waiting for background")
                    return
                }
                
                let isPossibleNow = self.pipController?.isPictureInPicturePossible ?? false
                print("📺 AgoraPiP: Delayed check - isPictureInPicturePossible = \(isPossibleNow)")
                
                if isPossibleNow {
                    self.pendingStart = false
                    self.isStartingPiP = true
                    self.pipController?.startPictureInPicture()
                    print("📺 AgoraPiP: startPictureInPicture() called after delay")
                    // Reset flag after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                        self?.isStartingPiP = false
                    }
                }
            }
        }
    }
    
    func stop() -> Bool {
            userWantsPiP = false
            pendingStart = false  // Also cancel any pending start
            isStartingPiP = false
            pipController?.stopPictureInPicture()
            print("📺 AgoraPiP: Stop requested")
            return true
        }
    
    /// Cancel any pending PiP start operations
    /// Call this when app resumes to prevent PiP from starting after user returns
    func cancelPending() {
        userWantsPiP = false
        pendingStart = false
        isStartingPiP = false
        print("📺 AgoraPiP: Cancelled pending PiP operations")
    }
        
        func cleanup() {
            userWantsPiP = false
            isRestoringUI = false
            pendingStart = false
            isStartingPiP = false
            pipObservation?.invalidate()
            pipObservation = nil
            playerStatusObservation?.invalidate()
            playerStatusObservation = nil
            pipController?.stopPictureInPicture()
            pipController = nil
            playerLooper = nil
            queuePlayer?.pause()
            queuePlayer = nil
            playerLayer?.removeFromSuperlayer()
            playerLayer = nil
            pipView?.removeFromSuperview()
            pipView = nil
            print("📺 AgoraPiP: Cleanup complete")
        }
        
        // MARK: - AVPictureInPictureControllerDelegate
        
        func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
            print("📺 AgoraPiP: Will start PiP")
            isRestoringUI = false
            isStartingPiP = false  // Start succeeded
            onStateChanged?("willStart")
        }
        
        func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
            print("📺 AgoraPiP: Did start PiP")
            isRestoringUI = false
            isStartingPiP = false
            onStateChanged?("started")
        }
        
        func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
            print("📺 AgoraPiP: Will stop PiP")
            isStartingPiP = false
            onStateChanged?("willStop")
        }
        
        func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
            print("📺 AgoraPiP: Did stop PiP")
            userWantsPiP = false
            needsReset = true
            isStartingPiP = false
            onStateChanged?("stopped")
        }
        
        func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
            print("📺 AgoraPiP: Failed to start PiP: \(error.localizedDescription)")
            userWantsPiP = false
            needsReset = true
            isStartingPiP = false
            pendingStart = false
            onStateChanged?("failed:\(error.localizedDescription)")
        }
        
        func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
            print("📺 AgoraPiP: Restore UI requested")
            isRestoringUI = true
            userWantsPiP = false
            needsReset = true
            isStartingPiP = false
            onStateChanged?("restoreUI")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.isRestoringUI = false
                completionHandler(true)
            }
        }
    }
    
    // MARK: - AppDelegate
    
    @main
    @objc class AppDelegate: FlutterAppDelegate {
        
        private var pipChannel: FlutterMethodChannel?
        private var screenShareChannel: FlutterMethodChannel?
        private let screenShareAppGroup = "group.com.doctak.screenshare"
        
        override func application(
            _ application: UIApplication,
            didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
        ) -> Bool {
            
            GeneratedPluginRegistrant.register(with: self)
            
            // Setup native PiP method channel for iOS 15+
            setupNativePiPChannel()
            
            // Setup screen share method channel
            setupScreenShareChannel()
            
            // Configure audio session for PiP and background audio - do this AFTER Flutter is ready
            // and on a slight delay to avoid blocking app launch
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.configureAudioSession()
            }
            
            // Pre-create PiP placeholder video - the video creation can be in background
            // but the actual PiP controller setup must happen on main thread when needed
            if #available(iOS 15.0, *) {
                // Just log - actual setup will happen when PiP is first requested
                print("📺 AgoraPiP: PiP support available, will setup on demand")
            }
            
            // Request notification authorization
            if #available(iOS 10.0, *) {
                UNUserNotificationCenter.current().delegate = self
                let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
                UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
                    print(granted ? "✅ Notification permission granted" : "❌ Notification permission denied")
                }
            }
            
            application.registerForRemoteNotifications()
            
            return super.application(application, didFinishLaunchingWithOptions: launchOptions)
        }
        
        private func configureAudioSession() {
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.playAndRecord, mode: .videoChat, options: [.allowBluetooth, .allowBluetoothA2DP, .defaultToSpeaker, .mixWithOthers])
                try audioSession.setActive(true)
                print("📺 Audio session configured for PiP")
            } catch {
                print("❌ Failed to configure audio session: \(error)")
            }
        }
        
        private func setupNativePiPChannel() {
            guard let controller = window?.rootViewController as? FlutterViewController else {
                return
            }
            
            pipChannel = FlutterMethodChannel(
                name: "com.doctak.app/agora_pip",
                binaryMessenger: controller.binaryMessenger
            )
            
            if #available(iOS 15.0, *) {
                AgoraPiPController.shared.onStateChanged = { [weak self] state in
                    DispatchQueue.main.async {
                        self?.pipChannel?.invokeMethod("onPiPStateChanged", arguments: ["state": state])
                    }
                }
            }
            
            pipChannel?.setMethodCallHandler { [weak self] call, result in
                self?.handlePiPMethodCall(call: call, result: result)
            }
            
            print("📺 PiP: Native method channel registered")
        }
        
        private func handlePiPMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
            switch call.method {
            case "isSupported":
                if #available(iOS 15.0, *) {
                    result(AgoraPiPController.shared.isSupported)
                } else {
                    result(false)
                }
                
            case "setup":
                if #available(iOS 15.0, *) {
                    result(AgoraPiPController.shared.setup())
                } else {
                    result(false)
                }
                
            case "start":
                if #available(iOS 15.0, *) {
                    result(AgoraPiPController.shared.start())
                } else {
                    result(false)
                }
                
            case "stop":
                if #available(iOS 15.0, *) {
                    result(AgoraPiPController.shared.stop())
                } else {
                    result(true)
                }
            
            case "cancelPending":
                // Cancel any pending PiP start - call this when app resumes
                if #available(iOS 15.0, *) {
                    AgoraPiPController.shared.cancelPending()
                    result(true)
                } else {
                    result(true)
                }
                
            case "isActive":
                if #available(iOS 15.0, *) {
                    result(AgoraPiPController.shared.isActive)
                } else {
                    result(false)
                }
                
            case "setAutoEnabled":
                if #available(iOS 15.0, *) {
                    let enabled = (call.arguments as? [String: Any])?["enabled"] as? Bool ?? false
                    AgoraPiPController.shared.setAutoEnabled(enabled)
                    result(true)
                } else {
                    result(false)
                }
                
            case "getStatus":
                if #available(iOS 15.0, *) {
                    let controller = AgoraPiPController.shared
                    result([
                        "isSupported": controller.isSupported,
                        "isActive": controller.isActive,
                        "iosVersion": UIDevice.current.systemVersion
                    ])
                } else {
                    result(["isSupported": false, "iosVersion": UIDevice.current.systemVersion])
                }
                
            case "dispose":
                if #available(iOS 15.0, *) {
                    AgoraPiPController.shared.cleanup()
                }
                result(true)
                
            case "updateFrame":
                if #available(iOS 15.0, *) {
                    guard let args = call.arguments as? [String: Any],
                          let imageData = (args["imageData"] as? FlutterStandardTypedData)?.data,
                          let width = args["width"] as? Int,
                          let height = args["height"] as? Int else {
                        result(false)
                        return
                    }
                    AgoraPiPController.shared.updateFrame(imageData, width: width, height: height)
                    result(true)
                } else {
                    result(false)
                }
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
            print("📱 Registered for remote notifications")
        }
        
        override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
            print("❌ Failed to register for notifications: \(error)")
        }
        
        override func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
            if #available(iOS 14.0, *) {
                completionHandler([[.banner, .sound, .badge]])
            } else {
                completionHandler([[.alert, .sound, .badge]])
            }
        }
        
        override func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
            completionHandler()
        }
        
        // MARK: - Screen Share Channel
        
        private func setupScreenShareChannel() {
            guard let controller = window?.rootViewController as? FlutterViewController else {
                return
            }
            
            screenShareChannel = FlutterMethodChannel(
                name: "com.doctak.app/screen_share",
                binaryMessenger: controller.binaryMessenger
            )
            
            screenShareChannel?.setMethodCallHandler { [weak self] call, result in
                self?.handleScreenShareMethodCall(call: call, result: result)
            }
            
            print("📺 ScreenShare: Native method channel registered")
        }
        
        private func handleScreenShareMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
            switch call.method {
            case "saveChannelConfig":
                guard let args = call.arguments as? [String: Any],
                      let appId = args["appId"] as? String,
                      let channelName = args["channelName"] as? String else {
                    result(false)
                    return
                }
                
                let token = args["token"] as? String ?? ""
                let uid = args["uid"] as? Int ?? 0
                
                guard let defaults = UserDefaults(suiteName: screenShareAppGroup) else {
                    print("📺 ScreenShare: Cannot access app group")
                    result(false)
                    return
                }
                
                defaults.set(appId, forKey: "AGORA_APP_ID")
                defaults.set(channelName, forKey: "AGORA_CHANNEL_NAME")
                defaults.set(token, forKey: "AGORA_TOKEN")
                defaults.set(uid, forKey: "AGORA_UID")
                defaults.synchronize()
                
                print("📺 ScreenShare: Saved config for channel: \(channelName)")
                result(true)
                
            case "clearChannelConfig":
                guard let defaults = UserDefaults(suiteName: screenShareAppGroup) else {
                    result(false)
                    return
                }
                
                defaults.removeObject(forKey: "AGORA_APP_ID")
                defaults.removeObject(forKey: "AGORA_CHANNEL_NAME")
                defaults.removeObject(forKey: "AGORA_TOKEN")
                defaults.removeObject(forKey: "AGORA_UID")
                defaults.synchronize()
                
                print("📺 ScreenShare: Cleared config")
                result(true)
                
            case "startBroadcast":
                // Show the RPSystemBroadcastPickerView to let user select the extension
                showBroadcastPicker()
                result(true)
                
            case "stopBroadcast":
                // The broadcast can only be stopped from Control Center or the extension itself
                result(true)
                
            case "isBroadcasting":
                // We can't directly check if extension is broadcasting from main app
                // This would need to be communicated via app group or Darwin notifications
                result(false)
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        private func showBroadcastPicker() {
            // Create broadcast picker
            let broadcastPicker = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
            broadcastPicker.preferredExtension = "com.doctak.ios.BroadcastUploadExtension"
            broadcastPicker.showsMicrophoneButton = false
            
            // Add to view temporarily and trigger tap
            if let window = UIApplication.shared.windows.first,
               let rootView = window.rootViewController?.view {
                broadcastPicker.alpha = 0.01  // Nearly invisible but still interactive
                broadcastPicker.center = CGPoint(x: rootView.bounds.midX, y: rootView.bounds.midY)
                rootView.addSubview(broadcastPicker)
                
                print("📺 ScreenShare: Showing broadcast picker")
                
                // Find and tap the button inside the picker
                func findButton(in view: UIView) -> UIButton? {
                    if let button = view as? UIButton {
                        return button
                    }
                    for subview in view.subviews {
                        if let button = findButton(in: subview) {
                            return button
                        }
                    }
                    return nil
                }
                
                if let button = findButton(in: broadcastPicker) {
                    button.sendActions(for: .touchUpInside)
                    print("📺 ScreenShare: Triggered broadcast picker button")
                } else {
                    print("📺 ScreenShare: Could not find button in broadcast picker")
                }
                
                // Remove after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    broadcastPicker.removeFromSuperview()
                }
            } else {
                print("📺 ScreenShare: Could not find root view for broadcast picker")
            }
        }
        
        // MARK: - Deep Link Handling (Universal Links)
        
        /// Handle Universal Links (https://doctak.net/...) when app is launched or brought to foreground
        override func application(
            _ application: UIApplication,
            continue userActivity: NSUserActivity,
            restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
        ) -> Bool {
            // Handle Universal Links
            if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
               let url = userActivity.webpageURL {
                print("🔗 DeepLink: Universal Link received: \(url)")
                // Let Flutter's app_links package handle the URL
                return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
            }
            
            return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
        }
        
        /// Handle custom URL scheme (doctak://...) when app is launched from URL
        override func application(
            _ app: UIApplication,
            open url: URL,
            options: [UIApplication.OpenURLOptionsKey: Any] = [:]
        ) -> Bool {
            print("🔗 DeepLink: Custom URL scheme received: \(url)")
            // Let Flutter's app_links package handle the URL
            return super.application(app, open: url, options: options)
        }
    }
