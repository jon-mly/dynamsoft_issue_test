import 'package:dynamsoft_test/scanner_widget/code_scanner_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:stacked/stacked.dart';

class CodeScannerModel extends BaseViewModel {
  CodeScannerModel(this._controller, this._onScannerReady);

  final CodeScannerController _controller;
  final VoidCallback? _onScannerReady;

  final List<String> _scannedCodes = [];
  List<String> get scannedCodes => _scannedCodes;

  //
  // Lifecycle
  //

  void init() async {
    _controller.addListener(_onScannedCodes);
    await _controller.init(() {
      if (_onScannerReady != null) {
        _onScannerReady!();
      }
      notifyListeners();
    });
    notifyListeners();
  }

  @override
  void dispose() {
    _controller.removeListener(_onScannedCodes);
    super.dispose();
  }

  //
  // Actions
  //

  void _onScannedCodes(List<String> codes) {
    for (String code in codes) {
      if (!_scannedCodes.contains(code)) {
        _scannedCodes.add(code);
        notifyListeners();
      }
    }
  }
}
