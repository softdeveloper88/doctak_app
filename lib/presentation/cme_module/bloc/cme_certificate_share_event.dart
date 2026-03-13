import 'package:equatable/equatable.dart';

abstract class CmeCertificateShareEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CmeLoadCertificateDetailEvent extends CmeCertificateShareEvent {
  final String certificateId;
  CmeLoadCertificateDetailEvent({required this.certificateId});

  @override
  List<Object?> get props => [certificateId];
}

class CmeShareCertificateEvent extends CmeCertificateShareEvent {
  final String certificateId;
  CmeShareCertificateEvent({required this.certificateId});

  @override
  List<Object?> get props => [certificateId];
}

class CmeVerifyCertificateEvent extends CmeCertificateShareEvent {
  final String certificateNumber;
  CmeVerifyCertificateEvent({required this.certificateNumber});

  @override
  List<Object?> get props => [certificateNumber];
}
