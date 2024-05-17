import 'dart:io';

import 'package:flutter/material.dart';
import 'package:jam_app/pages/home/home.dart';
import 'package:jam_app/providers/JammerStateProvider.dart';
import 'package:jam_app/providers/ProfileProvider.dart';
import 'package:jam_app/providers/ScriptsProvider.dart';
import 'package:jam_app/providers/WaveformsProvider.dart';
import 'package:jam_app/providers/WaveformsProviderV2.dart';
import 'package:jam_app/services/jammer_services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

const String JAMMER_API_HOST = "fedora:8000";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  JammerService service = JammerService(JAMMER_API_HOST);
  late Directory storage_dir;

  if(Platform.isAndroid || Platform.isIOS){
    storage_dir = (await getExternalStorageDirectory())!;
  }
  else if(Platform.isLinux){
    storage_dir = Directory("${Platform.environment['HOME']}/.local/share/jam_app");
    storage_dir.createSync();
  }
  else {
    storage_dir = Directory("");

    storage_dir.createSync();
  }

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (context) => JammerStateProvider(service),
      ),
      ChangeNotifierProxyProvider<JammerStateProvider, WaveformsProviderV2>(
          create: (context) =>
              WaveformsProviderV2(service, storage_dir),
          update: (context, jsp, wpv2) => wpv2!..update_with_state_provider(jsp),

      ),
      ChangeNotifierProxyProvider<WaveformsProviderV2, ProfileProvider>(
        create: (context) =>
            ProfileProvider(service, Provider.of<WaveformsProviderV2>(context, listen: false),storage_dir),
        update: (context, prov, pp) => pp!..wf_provider=prov,
      ),

      ChangeNotifierProvider(
        create: (context) => ScriptsProvider(service, storage_dir),
      ),

      ChangeNotifierProvider(
        create: (context) => WaveformsProvider(service),
      )
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          appBarTheme: AppBarTheme(elevation: 4)
      ),
      home: MyHomePage(),
        debugShowCheckedModeBanner: false
    );
  }
}
