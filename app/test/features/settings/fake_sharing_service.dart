import 'package:calorias_ia/infra/sharing/sharing_service.dart';

class FakeSharingService implements SharingService {
  String? sharedPath;
  String? sharedSubject;

  @override
  Future<void> shareFile(String path, {String? subject}) async {
    sharedPath = path;
    sharedSubject = subject;
  }
}
