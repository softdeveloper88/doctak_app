import 'package:doctak_app/data/apiClient/cme/cme_api_service.dart';
import 'package:doctak_app/data/apiClient/cme/cme_node_api_service.dart';
import 'package:doctak_app/data/models/cme/cme_certificate_model.dart';
import 'package:doctak_app/presentation/cme_module/utils/cme_certificate_pdf_service.dart';
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
      try {
        certificatesList = await CmeNodeApiService.getCertificates();
      } catch (_) {
        final response = await CmeApiService.getCertificates();
        certificatesList = response.certificates ?? [];
      }
      emit(CmeCertificatesLoadedState());
    } catch (e) {
      emit(CmeCertificatesErrorState('$e'));
    }
  }

  Future<void> _onDownloadCertificate(
      CmeDownloadCertificateEvent event,
      Emitter<CmeCertificatesState> emit) async {
    emit(CmeCertificateDownloadingState());
    try {
      CmeCertificateData detail;
      try {
        detail = await CmeNodeApiService.getCertificateDetail(event.certificateId);
      } catch (_) {
        CmeCertificateData? cached;
        for (final c in certificatesList) {
          if (c.id == event.certificateId) {
            cached = c;
            break;
          }
        }
        if (cached != null) {
          detail = cached;
        } else {
          detail = await CmeApiService.getCertificateDetail(event.certificateId);
        }
      }

      final file = await CmeCertificatePdfService.saveCertificatePdf(detail);
      emit(CmeCertificateDownloadState(file.path));
      emit(CmeCertificatesLoadedState());
    } catch (e) {
      emit(CmeCertificatesErrorState('$e'));
      emit(CmeCertificatesLoadedState());
    }
  }
}
