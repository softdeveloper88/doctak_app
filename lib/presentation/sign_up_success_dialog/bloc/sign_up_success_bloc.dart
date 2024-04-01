import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '/core/app_export.dart';
import 'package:doctak_app/presentation/sign_up_success_dialog/models/sign_up_success_model.dart';
part 'sign_up_success_event.dart';
part 'sign_up_success_state.dart';

/// A bloc that manages the state of a SignUpSuccess according to the event that is dispatched to it.
class SignUpSuccessBloc extends Bloc<SignUpSuccessEvent, SignUpSuccessState> {
  SignUpSuccessBloc(SignUpSuccessState initialState) : super(initialState) {
    on<SignUpSuccessInitialEvent>(_onInitialize);
  }

  _onInitialize(
    SignUpSuccessInitialEvent event,
    Emitter<SignUpSuccessState> emit,
  ) async {
    NavigatorService.pushNamed(
      AppRoutes.homeContainerScreen,
    );
  }
}
