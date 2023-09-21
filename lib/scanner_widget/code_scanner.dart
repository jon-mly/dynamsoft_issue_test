import 'package:dynamsoft_test/scanner_widget/code_scanner_controller.dart';
import 'package:dynamsoft_test/scanner_widget/code_scanner_model.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

enum CodeScannerExpectedType { qr, badges, card }

class CodeScannerWidget extends StatelessWidget {
  const CodeScannerWidget(
      {Key? key, required this.controller, this.onScannerReady})
      : super(key: key);

  final CodeScannerController controller;
  final VoidCallback? onScannerReady;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<CodeScannerModel>.reactive(
      viewModelBuilder: () => CodeScannerModel(controller, onScannerReady),
      onViewModelReady: (model) => model.init(),
      builder: (context, model, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            controller.captureCameraView ?? Container(),
            Padding(
              padding: const EdgeInsets.only(left: 50),
              child: SingleChildScrollView(
                child: Column(
                  children: model.scannedCodes
                      .map(
                        (String code) => Padding(
                          padding: const EdgeInsets.all(8),
                          child: Container(
                            color: Colors.white.withOpacity(0.2),
                            padding: const EdgeInsets.all(8),
                            child: Text(code),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            )
          ],
        );
      },
    );
  }
}
