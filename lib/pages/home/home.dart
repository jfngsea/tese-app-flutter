import 'package:flutter/material.dart';
import 'package:jam_app/pages/home/tabs/main_tab.dart';
import 'package:jam_app/pages/home/tabs/profiles_tab.dart';
import 'package:jam_app/pages/home/tabs/scripts_tab.dart';
import 'package:jam_app/pages/home/tabs/tbd.dart';
import 'package:jam_app/pages/home/tabs/waveforms_tab.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentTab =0;

  static const List<Widget> _widgetOptions = <Widget>[
    MainTab(),
    WaveformsTab(),
    ProfilesTab(),
    ScriptsTab()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_currentTab),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentTab,
        onTap: (idx){
          setState(() {
            _currentTab=idx;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.wifi_channel), label: "Waveforms"),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: "Profiles"),
          BottomNavigationBarItem(icon: Icon(Icons.code), label: "Scripts"),
        ],
      ),
    );
  }
}