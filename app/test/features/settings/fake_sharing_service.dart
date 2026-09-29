import 'package:calorias_ia/infra/sharing/sharing_service.dart';

class FakeSharingService implements SharingService {
  String? sharedPath;
  String? sharedSubject;

  /// Simula que el share sheet del SO falla o el usuario lo cancela
  /// (Edge Case documentado en SPEC-006).
  bool shouldThrow;

  FakeSharingService({this.shouldThrow = false});

  @override
  Future<void> shareFile(String path, {String? subject}) async {
    if (shouldThrow) {
      throw Exception('share sheet no disponible (simulado en el test)');
    }
    sharedPath = path;
    sharedSubject = subject;
  }
}
