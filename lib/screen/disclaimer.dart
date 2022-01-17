import 'package:flutter/material.dart';

class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Disclaimer"),
      ),
      body: Column(
        children: const [Text("ข้อตกลงในการใช้ซอฟต์แวร์"), Text("data")],
      ),
    );
  }
}
