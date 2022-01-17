import 'package:flutter/material.dart';

class DisclaimerView extends StatelessWidget {
  const DisclaimerView({Key? key}) : super(key: key);

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
