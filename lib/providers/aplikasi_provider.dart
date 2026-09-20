import 'package:flutter/foundation.dart';

class AplikasiProvider extends ChangeNotifier {
  bool modeOffline = true;

  void ubahModeOffline(bool nilai) {
    modeOffline = nilai;
    notifyListeners();
  }
}
