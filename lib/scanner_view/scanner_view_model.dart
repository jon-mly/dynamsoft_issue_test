import 'package:dynamsoft_test/scanner_widget/code_scanner_controller.dart';
import 'package:stacked/stacked.dart';
import 'package:permission_handler/permission_handler.dart';

class ScannerViewModel extends BaseViewModel {
  CodeScannerController? _scannerController;
  CodeScannerController? get scannerController => _scannerController;

  //
  // Lifecycle
  //

  Future<void> init() async {
    // Permission check performed before creating the widget containing the
    // scanner to ensure that Dynamsoft is initialized only when permission
    // is already granted.
    final PermissionStatus requestStatus = await Permission.camera.request();
    print(requestStatus);
    if (requestStatus != PermissionStatus.granted) return;

    _scannerController = CodeScannerController();
    notifyListeners();
  }
}
