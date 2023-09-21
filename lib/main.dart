import 'package:dynamsoft_test/scanner_view/scanner_view.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dynamsoft Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routes: {
        "/": (context) => const HomePage(),
        "/scanner": (context) => const ScannerView(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Text(
              "Dynamsoft Demo",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Expanded(
              child: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pushNamed("/scanner"),
                  child: const Text("Open Scanner View"),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
