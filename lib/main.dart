import 'package:domacod/home_page.dart';
import 'package:domacod/providers/database_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

final assetsBox = objectbox.store.box<ImageData>();

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (BuildContext context) {
          return DatabaseProvider();
        }),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Domacod',
        theme: ThemeData.dark(),
        initialRoute:
            initScreen == 0 || initScreen == null ? 'onboard' : 'home',
        routes: {
          'home': (context) => MainPage(
                assetsBox: assetsBox,
              ),
          'onboard': (context) => const OnBoardingPage(),
        },
      ),
    );
  }

  @override
  void dispose() {
    objectbox.store.close();
    super.dispose();
  }
}
