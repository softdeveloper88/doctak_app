//
//  SampleHandler.swift
//  BroadcastUploadExtension
//
//  Screen sharing extension using Agora's AgoraReplayKitHandler
//  for proper screen capture and streaming.
//

import ReplayKit
import AgoraReplayKitExtension

class SampleHandler: AgoraReplayKitHandler {
    
    // App group identifier - must match the main app's app group
    private let appGroupIdentifier = "group.com.doctak.screenshare"
    
    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        NSLog("📺 ScreenShare: Broadcast started with Agora handler")
        
        // Mark broadcast as active in shared UserDefaults
        if let defaults = UserDefaults(suiteName: appGroupIdentifier) {
            defaults.set(true, forKey: "BROADCAST_ACTIVE")
            defaults.synchronize()
        }
        
        // Call super to let AgoraReplayKitHandler initialize
        super.broadcastStarted(withSetupInfo: setupInfo)
        
        NSLog("📺 ScreenShare: Agora handler initialized")
    }
    
    override func broadcastPaused() {
        NSLog("📺 ScreenShare: Paused")
        super.broadcastPaused()
    }
    
    override func broadcastResumed() {
        NSLog("📺 ScreenShare: Resumed")
        super.broadcastResumed()
    }
    
    override func broadcastFinished() {
        NSLog("📺 ScreenShare: Finished")
        
        // Mark broadcast as inactive
        if let defaults = UserDefaults(suiteName: appGroupIdentifier) {
            defaults.set(false, forKey: "BROADCAST_ACTIVE")
            defaults.synchronize()
        }
        
        super.broadcastFinished()
    }
    
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        // Let AgoraReplayKitHandler process and stream the sample buffer
        super.processSampleBuffer(sampleBuffer, with: sampleBufferType)
    }
}
