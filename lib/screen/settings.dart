import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:domacod/providers/database_provider.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

bool useOCR = true;

class _SettingsScreenState extends State<SettingsScreen> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  @override
  void initState() {
    _prefs.then((SharedPreferences prefs) async {
      setState(() {
        useOCR = prefs.getBool('useOCR') ?? true;
      });
    });
    super.initState();
  }

  Future<void> toggleOCR(bool value) async {
    final SharedPreferences prefs = await _prefs;
    prefs.setBool("useOCR", value);
    setState(() {
      useOCR = value;
    });
    context.read<DatabaseProvider>().useOCR = value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: SettingsList(
        sections: [
          SettingsSection(tiles: [
            SettingsTile.switchTile(
              initialValue: useOCR,
              onToggle: (value) {
                toggleOCR(value);
              },
              title: const Text("Use OCR"),
              description: const Text(
                  "Use online OCR service for charactor recognition."),
              leading: const Icon(Icons.search),
            ),
          ])
        ],
      ),
    );
  }
}
