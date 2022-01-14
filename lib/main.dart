import 'package:domacod/home_page.dart';
import 'package:flutter/material.dart';
import 'objectbox.dart';
import 'image_data_models.dart';

/// Provides access to the ObjectBox Store throughout the app.
late ObjectBox objectbox;

Future<void> main() async {
  // This is required so ObjectBox can get the application directory
  // to store the database in.
  WidgetsFlutterBinding.ensureInitialized();

  objectbox = await ObjectBox.create();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final assetBox = objectbox.store.box<ImageData>();
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Domacod',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainPage(
        assetBox: assetBox,
      ),
    );
  }
}
