import 'package:dynamsoft_test/scanner_view/scanner_view_model.dart';
import 'package:dynamsoft_test/scanner_widget/code_scanner.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

class ScannerView extends StatelessWidget {
  const ScannerView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ScannerViewModel>.reactive(
      viewModelBuilder: () => ScannerViewModel(),
      onViewModelReady: (model) => model.init(),
      builder: (context, model, child) {
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: Navigator.of(context).pop,
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const Expanded(child: Text("Scanner View"))
                    ],
                  ),
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: (model.scannerController != null)
                            ? CodeScannerWidget(
                                controller: model.scannerController!,
                              )
                            : Container(color: Colors.grey),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
