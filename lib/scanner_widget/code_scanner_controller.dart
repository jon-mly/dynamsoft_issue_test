import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:dynamsoft_capture_vision_flutter/dynamsoft_capture_vision_flutter.dart';

enum BarcodeScannerSource { dynamsoft, pictureOnly }

class CodeScannerController {
  CodeScannerController({
    this.onCameraPermissionDenied,
    this.onCameraSetupEnded,
  });

  static const String _licenseKey =
      "DLS2eyJoYW5kc2hha2VDb2RlIjoiMTAxMzcxNzgyLVRYbE5iMkpwYkdWUWNtOXFYMlJpY2ciLCJvcmdhbml6YXRpb25JRCI6IjEwMTM3MTc4MiIsIm1haW5TZXJ2ZXJVUkwiOiJodHRwczovL21sdHMuZHluYW1zb2Z0LmNvbS8iLCJzdGFuZGJ5U2VydmVyVVJMIjoiaHR0cHM6Ly9zbHRzLmR5bmFtc29mdC5jb20vIiwiY2hlY2tDb2RlIjo2NTY3NDA0ODl9";

  final VoidCallback? onCameraPermissionDenied;
  final VoidCallback? onCameraSetupEnded;

  final List<Function(List<String>)> _listeners = [];

  DCVBarcodeReader? _captureBarcodeReader;
  DCVCameraEnhancer? _captureCameraEnhancer;
  DCVCameraView? _captureCameraView;
  DCVCameraView? get captureCameraView => _captureCameraView;

  StreamSubscription? _mobileScannerSubscription;

  bool _isComputingResults = false;

  bool _isPaused = false;

  final List<String> _scannedCodes = [];

  Map<String, dynamic> _dynamsoftRuntimeSettingsMap = {};
  String get _dynamsoftRuntimeSettingsJson =>
      json.encode(_dynamsoftRuntimeSettingsMap);

  //
  // Lifecycle
  //

  // Callback is for a workaround on Android : when requesting the camera
  // permission, the widget does not start to show the camera feed. The widget
  // is recreated periodically afterward.
  // The Callback should be used to call "notifyListeners"
  Future<void> init(VoidCallback onDynamsoftSetup) async {
    try {
      _dynamsoftRuntimeSettingsMap = await rootBundle
          .loadString("assets/dynamsoft_badges.json")
          .then((String jsonString) => json.decode(jsonString));
      await _initMobileDynamsoftCamera(onDynamsoftSetup);
    } catch (e) {
      print("Init : ${e.toString()}");
    }

    if (onCameraSetupEnded != null) {
      onCameraSetupEnded!();
    }
  }

  void dispose() {
    _mobileScannerSubscription?.cancel();
    _captureCameraEnhancer?.close();
    _captureBarcodeReader?.stopScanning();
    _captureBarcodeReader = null;
  }

  //
  // Init
  //

  Future<void> _initMobileDynamsoftCamera(VoidCallback onDynamsoftSetup,
      {bool isSecondInit = false}) async {
    // Permission is handled with permission_handler before presenting
    // [ScannerWidget] to ensure that Dynamsoft is always initialized with
    // permission already allowed.

    // On iOS only :
    // The app will crash if Dynamsoft tries to start with a permanently
    // denied camera access. So the permission is requested manually prior to
    // starting the configuration of Dynamsoft.
    // if (Platform.isIOS) {
    //   if (!(await _requestCameraPermission())) return;
    // }

    // On Android, requesting the permission before makes that Dynamsoft does
    // not start. An exception about a native permission handler is triggered.
    // if (!(await _requestCameraPermission())) return;

    // /!\ ensure that this part is called once the Widget is displayed
    _captureCameraView = DCVCameraView();

    await DCVBarcodeReader.initLicense(_licenseKey);

    _captureBarcodeReader = await DCVBarcodeReader.createInstance();
    _captureCameraEnhancer = await DCVCameraEnhancer.createInstance();
    _captureCameraEnhancer?.selectCamera(EnumCameraPosition.CP_BACK);

    // Using JSON to apply more parameters than only the ones exposed in Flutter
    await _captureBarcodeReader!
        .updateRuntimeSettingsFromJson(_dynamsoftRuntimeSettingsJson);

    // Configuration in
    // final DBRRuntimeSettings barcodeSettings =
    //     await _captureBarcodeReader!.getRuntimeSettings();
    // barcodeSettings.barcodeFormatIds = _type == CodeScannerExpectedType.qr
    //     ? EnumBarcodeFormat.BF_QR_CODE
    //     : (EnumBarcodeFormat.BF_CODE_128 | EnumBarcodeFormat.BF_DATAMATRIX);
    // barcodeSettings.barcodeFormatIds_2 = EnumBarcodeFormat2.BF2_NULL;
    // barcodeSettings.expectedBarcodeCount = 0;
    // barcodeSettings.timeout = 500;
    // barcodeSettings.localizationModes = [
    //   EnumLocalizationMode.LM_SCAN_DIRECTLY,
    //   EnumLocalizationMode.LM_CONNECTED_BLOCKS,
    // ];
    // _captureBarcodeReader?.updateRuntimeSettings(barcodeSettings);

    _captureBarcodeReader?.enableResultVerification(true);

    _captureCameraEnhancer?.open();

    _captureCameraEnhancer?.setScanRegion(
      Region(
        regionTop: 40,
        regionLeft: 0,
        regionBottom: 60,
        regionRight: 100,
        regionMeasuredByPercentage: 1,
      ),
    );

    _captureCameraView?.overlayVisible = true;
    _captureCameraView?.torchButton = TorchButton(visible: true);

    _captureBarcodeReader?.startScanning();

    if (isSecondInit) {
      _mobileScannerSubscription = _captureBarcodeReader
          ?.receiveResultStream()
          .listen(_onScannerResults);
      onDynamsoftSetup();
      print("Camera configured second time");
      return;
    }

    // On iOS, when requesting authorization, the camera does not start.
    // Workaround to recreate the full Dynamsoft setup after permission is
    // given if the stream does not return any event avter a while
    if (!Platform.isAndroid) {
      _captureBarcodeReader?.receiveResultStream().first.then((event) {
        _mobileScannerSubscription = _captureBarcodeReader
            ?.receiveResultStream()
            .listen(_onScannerResults);
        onDynamsoftSetup();
        print("Camera configured and starts streaming");
      }).timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          print(
              "Camera setup timeout. Killing and recreating Dynamsoft config");
          _mobileScannerSubscription?.cancel();
          _captureCameraEnhancer?.close();
          _captureBarcodeReader?.stopScanning();
          _initMobileDynamsoftCamera(onDynamsoftSetup, isSecondInit: true);
          return null;
        },
      );
    } else {
      _mobileScannerSubscription = _captureBarcodeReader
          ?.receiveResultStream()
          .listen(_onScannerResults);
      onDynamsoftSetup();
      print("Camera configured");
    }
  }

  //
  // Detection
  //

  Future<void> _onScannerResults(List<BarcodeResult>? results) async {
    if (_isComputingResults || _isPaused || results == null) {
      return;
    }
    _isComputingResults = true;
    final List<String> codes =
        results.map((BarcodeResult result) => result.barcodeText).toList();

    print("Code found : $codes");

    final List<String> newCodes =
        codes.where((newCode) => !_scannedCodes.contains(newCode)).toList();
    if (newCodes.isEmpty) return;
    _scannedCodes.addAll(newCodes);

    // On each new scanned codes event, the runtime settings of Dynamsoft are
    // updated : the match test regex is updated to exclude the newly scanned
    // codes so that they are scanned only once each session.
    final String exclusionRegex = _generateExclusionRegex(_scannedCodes);
    _dynamsoftRuntimeSettingsMap["FormatSpecificationArray"] = [
      {
        "Name": "ExcludeScannedCodes",
        "BarcodeTextRegExPattern": exclusionRegex,
      }
    ];

    await _captureBarcodeReader
        ?.updateRuntimeSettingsFromJson(_dynamsoftRuntimeSettingsJson);
    _notifyListeners(newCodes);

    // Avoids too many analysis
    await Future.delayed(const Duration(milliseconds: 500));
  }

  //
  // Runtime settings exclusion
  //

  /// Generates a Regex matching all Strings tested, except the ones matching
  /// the given [scannedCodes].
  /// This will allow to not scan multiple times the same code
  String _generateExclusionRegex(List<String> scannedCodes) {
    List<String> negativeLookaheadsList = [];
    for (String code in scannedCodes) {
      negativeLookaheadsList.add("(?!$code)");
    }
    final String joinedNegativeLookaheads = negativeLookaheadsList.join();
    return "^$joinedNegativeLookaheads.*\$";
  }

  //
  // Listeners
  //

  void _notifyListeners(List<String> codes) {
    _listeners.forEach((listener) => listener(codes));
  }

  void addListener(Function(List<String>) listener) {
    _listeners.add(listener);
  }

  void removeListener(Function(List<String>) listener) {
    _listeners.remove(listener);
  }

  //
  // Scanner actions
  //

  void pauseScanning() {
    _isPaused = true;
  }

  void resumeScanning() {
    _isPaused = false;
  }
}
