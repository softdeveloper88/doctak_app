import 'package:doctak_app/data/apiClient/cme/cme_api_service.dart';
import 'package:doctak_app/data/models/cme/cme_certificate_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cme_certificates_event.dart';
import 'cme_certificates_state.dart';

class CmeCertificatesBloc
    extends Bloc<CmeCertificatesEvent, CmeCertificatesState> {
  List<CmeCertificateData> certificatesList = [];

  CmeCertificatesBloc() : super(CmeCertificatesInitialState()) {
    on<CmeLoadCertificatesEvent>(_onLoadCertificates);
    on<CmeDownloadCertificateEvent>(_onDownloadCertificate);
  }

  Future<void> _onLoadCertificates(
      CmeLoadCertificatesEvent event, Emitter<CmeCertificatesState> emit) async {
    emit(CmeCertificatesLoadingState());
    try {
      final response = await CmeApiService.getCertificates();
      certificatesList = response.certificates ?? [];
      emit(CmeCertificatesLoadedState());
    } catch (e) {
      emit(CmeCertificatesErrorState('$e'));
    }
  }

  Future<void> _onDownloadCertificate(
      CmeDownloadCertificateEvent event,
      Emitter<CmeCertificatesState> emit) async {
    try {
      final url =
          await CmeApiService.getCertificateDownloadUrl(event.certificateId);
      emit(CmeCertificateDownloadState(url));
      emit(CmeCertificatesLoadedState());
    } catch (e) {
      emit(CmeCertificatesErrorState('$e'));
      emit(CmeCertificatesLoadedState());
    }
  }
}
