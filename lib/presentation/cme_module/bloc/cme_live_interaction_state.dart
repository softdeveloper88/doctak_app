abstract class CmeLiveInteractionState {}

class CmeLiveInteractionInitialState extends CmeLiveInteractionState {}

class CmeChatLoadingState extends CmeLiveInteractionState {}

class CmeChatLoadedState extends CmeLiveInteractionState {}

class CmeChatMessageSentState extends CmeLiveInteractionState {}

class CmePollsLoadingState extends CmeLiveInteractionState {}

class CmePollsLoadedState extends CmeLiveInteractionState {}

class CmePollVotedState extends CmeLiveInteractionState {
  final String message;
  CmePollVotedState({this.message = 'Vote recorded'});
}

class CmePollCreatedState extends CmeLiveInteractionState {
  final String message;
  CmePollCreatedState({this.message = 'Poll created'});
}

class CmePollCreatingState extends CmeLiveInteractionState {}

class CmeParticipantsLoadedState extends CmeLiveInteractionState {}

class CmeEventJoinedState extends CmeLiveInteractionState {}

class CmeEventLeftState extends CmeLiveInteractionState {}

class CmeLiveInteractionErrorState extends CmeLiveInteractionState {
  final String message;
  CmeLiveInteractionErrorState(this.message);
}
