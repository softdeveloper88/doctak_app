import 'package:equatable/equatable.dart';

abstract class CmeCertificatesEvent extends Equatable {}

class CmeLoadCertificatesEvent extends CmeCertificatesEvent {
  @override
  List<Object?> get props => [];
}

class CmeDownloadCertificateEvent extends CmeCertificatesEvent {
  final String certificateId;
  CmeDownloadCertificateEvent({required this.certificateId});
  @override
  List<Object?> get props => [certificateId];
}
