import 'package:doctak_app/meeting_module/services/agora_service.dart';
import 'package:doctak_app/meeting_module/services/api_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/app/AppData.dart';
import 'meeting_event.dart';
import 'meeting_state.dart';

class MeetingBloc extends Bloc<MeetingEvent, MeetingState> {
  final ApiService _apiService;
  final AgoraService _agoraService;
  String? _currentMeetingId;
  String? userId;

  MeetingBloc({
    required ApiService apiService,
    required AgoraService agoraService,
    String? userId = '123',
  })  : _apiService = apiService,
        _agoraService = agoraService,
        super(MeetingInitial()) {
    on<CreateMeetingEvent>(_onCreateMeeting);
    on<JoinMeetingEvent>(_onJoinMeeting);
    on<AskToJoinMeetingEvent>(_onAskToJoinMeeting);
    on<LeaveMeetingEvent>(_onLeaveMeeting);
    on<EndMeetingEvent>(_onEndMeeting);
    on<GetMeetingDetailsEvent>(_onGetMeetingDetails);
    on<ToggleMicrophoneEvent>(_onToggleMicrophone);
    on<ToggleCameraEvent>(_onToggleCamera);
    on<ToggleScreenShareEvent>(_onToggleScreenShare);
    on<ToggleHandRaiseEvent>(_onToggleHandRaise);
    on<StartRecordingEvent>(_onStartRecording);
    on<StopRecordingEvent>(_onStopRecording);
    on<MakeAnnouncementEvent>(_onMakeAnnouncement);
    on<MuteAllParticipantsEvent>(_onMuteAllParticipants);
    on<MeetingEndedEvent>(_onMeetingEnded);
  }

  String? get currentMeetingId => _currentMeetingId;

  Future<void> _onCreateMeeting(
      CreateMeetingEvent event,
      Emitter<MeetingState> emit,
      ) async {
    emit(MeetingLoading());
    try {
      final meeting = await _apiService.createMeeting(meetingTitle: event.meetingTitle);
      _currentMeetingId = meeting.id;
      print(meeting);
      emit(MeetingCreated(meeting));
    } catch (e) {
      emit(MeetingError('Failed to create meeting: $e'));
    }
  }

  Future<void> _onJoinMeeting(
      JoinMeetingEvent event,
      Emitter<MeetingState> emit,
      ) async {
    emit(MeetingLoading());
    try {
      await _apiService.joinMeeting(event.meetingCode);
      // In a real implementation, we would get the meeting details after joining
      // For simplicity, we're creating a dummy meeting object
      final meeting = await _apiService.getMeeting(event.meetingCode);
      _currentMeetingId = meeting.id;

      // Initialize and join Agora channel
      await _agoraService.initialize();
      await _agoraService.joinChannel(
        meeting.meetingToken,
        meeting.meetingChannel,
        int.parse(meeting.userId), // This should be the actual user ID
      );

      emit(MeetingJoined(meeting));
    } catch (e) {
      emit(MeetingError('Failed to join meeting: $e'));
    }
  }

  Future<void> _onAskToJoinMeeting(
      AskToJoinMeetingEvent event,
      Emitter<MeetingState> emit,
      ) async {
    emit(MeetingLoading());
    try {
      await _apiService.askToJoin(event.meetingId, event.userId);
      _currentMeetingId = event.meetingId;
      emit(MeetingJoinRequested());
    } catch (e) {
      emit(MeetingError('Failed to request joining meeting: $e'));
    }
  }

  Future<void> _onLeaveMeeting(
      LeaveMeetingEvent event,
      Emitter<MeetingState> emit,
      ) async {
    emit(MeetingLoading());
    try {
      await _apiService.leaveMeeting(event.meetingId);
      await _agoraService.leaveChannel();
      _currentMeetingId = null;
      emit(MeetingLeft());
    } catch (e) {
      emit(MeetingError('Failed to leave meeting: $e'));
    }
  }

  Future<void> _onEndMeeting(
      EndMeetingEvent event,
      Emitter<MeetingState> emit,
      ) async {
    emit(MeetingLoading());
    try {
      await _apiService.endMeeting(event.meetingId);
      await _agoraService.leaveChannel();
      _currentMeetingId = null;
      emit(MeetingEnded());
    } catch (e) {
      emit(MeetingError('Failed to end meeting: $e'));
    }
  }

  Future<void> _onGetMeetingDetails(
      GetMeetingDetailsEvent event,
      Emitter<MeetingState> emit,
      ) async {
    emit(MeetingLoading());
    try {
      final meeting = await _apiService.getMeeting(event.meetingId);
      emit(MeetingDetailsLoaded(meeting));
    } catch (e) {
      emit(MeetingError('Failed to get meeting details: $e'));
    }
  }

  Future<void> _onToggleMicrophone(
      ToggleMicrophoneEvent event,
      Emitter<MeetingState> emit,
      ) async {
    try {
      // Update Agora
      await _agoraService.setMicrophoneEnabled(event.enabled);
        print("hello mic");
      // Update server status
      if (_currentMeetingId != null) {
        await _apiService.updateMeetingStatus(
          userId: AppData.logInUserId,
          meetingId: _currentMeetingId!,
          action: 'mic',
          status: event.enabled,
        );
      }

      emit(MicrophoneToggled(event.enabled));
    } catch (e) {
      emit(MeetingError('Failed to toggle microphone: $e'));
    }
  }

  Future<void> _onToggleCamera(
      ToggleCameraEvent event,
      Emitter<MeetingState> emit,
      ) async {
    try {
      // Update Agora
      await _agoraService.setCameraEnabled(event.enabled);

      // Update server status
      if (_currentMeetingId != null) {
        await _apiService.updateMeetingStatus(
          userId: AppData.logInUserId.toString(),
          meetingId: _currentMeetingId!,
          action: 'cam',
          status: event.enabled,
        );
      }

      emit(CameraToggled(event.enabled));
    } catch (e) {
      emit(MeetingError('Failed to toggle camera: $e'));
    }
  }

  Future<void> _onToggleScreenShare(
      ToggleScreenShareEvent event,
      Emitter<MeetingState> emit,
      ) async {
    try {
      // Update Agora
      if (event.enabled) {
        await _agoraService.startScreenSharing();
      } else {
        await _agoraService.stopScreenSharing();
      }

      // Update server status
      if (_currentMeetingId != null) {
        await _apiService.updateMeetingStatus(
          userId: AppData.logInUserId.toString(),
          meetingId: _currentMeetingId!,
          action: 'screen',
          status: event.enabled,
        );
      }

      emit(ScreenShareToggled(event.enabled));
    } catch (e) {
      emit(MeetingError('Failed to toggle screen share: $e'));
    }
  }

  Future<void> _onToggleHandRaise(
      ToggleHandRaiseEvent event,
      Emitter<MeetingState> emit,
      ) async {
    try {
      // Update server status
      if (_currentMeetingId != null) {
        await _apiService.updateMeetingStatus(
          userId: AppData.logInUserId.toString(),
          meetingId: _currentMeetingId!,
          action: 'hands',
          status: event.raised,
        );
      }

      emit(HandRaiseToggled(event.raised));
    } catch (e) {
      emit(MeetingError('Failed to toggle hand raise: $e'));
    }
  }

  Future<void> _onStartRecording(
      StartRecordingEvent event,
      Emitter<MeetingState> emit,
      ) async {
    try {
      await _apiService.startRecording(event.meetingId);
      emit(RecordingStarted());
    } catch (e) {
      emit(MeetingError('Failed to start recording: $e'));
    }
  }

  Future<void> _onStopRecording(
      StopRecordingEvent event,
      Emitter<MeetingState> emit,
      ) async {
    try {
      await _apiService.stopRecording(event.meetingId);
      emit(RecordingStopped());
    } catch (e) {
      emit(MeetingError('Failed to stop recording: $e'));
    }
  }

  Future<void> _onMakeAnnouncement(
      MakeAnnouncementEvent event,
      Emitter<MeetingState> emit,
      ) async {
    try {
      await _apiService.makeAnnouncement(event.meetingId, event.message);
      emit(AnnouncementSent());
    } catch (e) {
      emit(MeetingError('Failed to send announcement: $e'));
    }
  }

  Future<void> _onMuteAllParticipants(
      MuteAllParticipantsEvent event,
      Emitter<MeetingState> emit,
      ) async {
    try {
      await _apiService.muteAllParticipants(event.meetingId);
      emit(AllParticipantsMuted());
    } catch (e) {
      emit(MeetingError('Failed to mute all participants: $e'));
    }
  }

  void _onMeetingEnded(
      MeetingEndedEvent event,
      Emitter<MeetingState> emit,
      ) {
    _agoraService.leaveChannel();
    _currentMeetingId = null;
    emit(MeetingEnded());
  }

  @override
  Future<void> close() {
    _agoraService.dispose();
    return super.close();
  }
}