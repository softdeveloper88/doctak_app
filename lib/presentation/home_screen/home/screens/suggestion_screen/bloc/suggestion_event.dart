
import 'package:equatable/equatable.dart';

abstract class SuggestionEvent extends Equatable{}

class LoadDataValues extends SuggestionEvent {
  @override
  List<Object?> get props => [];
}

class SaveSuggestion extends SuggestionEvent {
  final String name;
  final String phone;
  final String email;
  final String message;

  SaveSuggestion({required this.name,required this.phone,required this.email,required this.message});
  @override
  List<Object> get props => [name,phone,email,message];
}