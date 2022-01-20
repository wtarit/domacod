import 'package:domacod/home_page.dart';
import 'package:flutter/material.dart';
import 'objectbox.dart';
import 'image_data_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_page.dart';

/// Provides access to the ObjectBox Store throughout the app.
late ObjectBox objectbox;
// for open onBoarding page one time
int? initScreen;

Future<void> main() async {
  // This is required so ObjectBox can get the application directory
  // to store the database in.
  WidgetsFlutterBinding.ensureInitialized();

  objectbox = await ObjectBox.create();

  // for open onBoarding page one time
  SharedPreferences preferences = await SharedPreferences.getInstance();
  initScreen = preferences.getInt("initScreen");
  await preferences.setInt("initScreen", 1);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

final assetBox = objectbox.store.box<ImageData>();

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Domacod',
      theme: ThemeData.dark(),
      initialRoute: initScreen == 0 || initScreen == null ? 'onboard' : 'home',
      routes: {
        'home': (context) => MainPage(
              assetBox: assetBox,
            ),
        'onboard': (context) => OnBoardingPage(),
      },
    );
  }
}
