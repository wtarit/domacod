import 'package:flutter/material.dart';

class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Disclaimer"),
      ),
      body: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: const Center(
          child: Text(
              'License Agreement\n\nThis software is a work developed by Tarit Witworrasakul and Pemika Chongkwanyuen from Assumption College Thonburi under the provision of Ms. Phitchaphorn Prayoon-Anutep under Domacod - Image categorizing, indexing and search based on image content, which has been supported by the National Science and Technology Development Agency (NSTDA), in order to encourage pupils and students to learn and practice their skills in developing software. Therefore, the intellectual property of this software shall belong to the developer and the developer gives NSTDA a permission to distribute this software as an "as is" and non- modified software for a temporary and non-exclusive use without remuneration to anyone for his or her own purpose or academic purpose, which are not commercial purposes. In this connection, NSTDA shall not be responsible to the user for taking care, maintaining, training or developing the efficiency of this software. Moreover, NSTDA shall not be liable for any error, software efficiency and damages in connection with or arising out of the use of the software.'),
        ),
      ),
    );
  }
}
