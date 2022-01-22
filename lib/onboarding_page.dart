import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'home_page.dart';
import 'main.dart';

class OnBoardingPage extends StatelessWidget {
  const OnBoardingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => SafeArea(
        child: IntroductionScreen(
          pages: [
            PageViewModel(
              title: 'License Agreement',
              body:
                  'This software is a work developed by Tarit Witworrasakul and Pemika Chongkwanyuen from Assumption College Thonburi under the provision of Ms. Phitchaphorn Prayoon-Anutep under Domacod - Image categorizing, indexing and search based on image content, which has been supported by the National Science and Technology Development Agency (NSTDA), in order to encourage pupils and students to learn and practice their skills in developing software. Therefore, the intellectual property of this software shall belong to the developer and the developer gives NSTDA a permission to distribute this software as an "as is" and non-modified software for a temporary and non-exclusive use without remuneration to anyone for his or her own purpose or academic purpose, which are not commercial purposes. In this connection, NSTDA shall not be responsible to the user for taking care, maintaining, training or developing the efficiency of this software. Moreover, NSTDA shall not be liable for any error, software efficiency and damages in connection with or arising out of the use of the software.',
              decoration: getPageDecoration(),
            ),
          ],
          done: const Text('Agree',
              style: TextStyle(fontWeight: FontWeight.w500)),
          onDone: () => goTohome(context),
          next: const Icon(Icons.arrow_forward_ios_rounded),
          dotsDecorator: getDotDecoration(),
          // onChange: (index) => print('Page $index selected'),
        ),
      );

  void goTohome(context) => Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MainPage(
            assetsBox: assetsBox,
          ),
        ),
      );

  DotsDecorator getDotDecoration() => DotsDecorator(
        color: const Color(0xFFBDBDBD),
        size: const Size(10, 10),
        activeSize: const Size(15, 15),
        activeColor: Colors.teal,
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      );

  PageDecoration getPageDecoration() => const PageDecoration(
        titleTextStyle: TextStyle(
            fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
        bodyTextStyle: TextStyle(fontSize: 20, color: Colors.black),
        //descriptionPadding: EdgeInsets.all(16).copyWith(bottom: 0),
        pageColor: Colors.white,
      );
}
