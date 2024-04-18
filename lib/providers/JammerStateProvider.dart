import 'dart:async';
import 'dart:io';

import 'package:jam_app/models/JammerProfileModel.dart';
import 'package:jam_app/models/JammerSettingsModel.dart';
import 'package:flutter/foundation.dart';
import 'package:jam_app/models/WaveformEntry.dart';
import 'package:jam_app/services/jammer_services.dart';

enum JammerConnectionState {ok, warning, fail}

class JammerStateProvider extends ChangeNotifier {
  late JammerService _service;
  void set host_url(String url){
    _service.host_url= url;
  }
  String get host_url => _service.host_url;

  late Timer _state_timer;
  int _failed_attemps=6;
  JammerConnectionState get connection_state {
    if(_failed_attemps==0){
      return JammerConnectionState.ok;
    }
    if(_failed_attemps<5){
      return JammerConnectionState.warning;
    }
    return JammerConnectionState.fail;
  }

  bool isLoading = false;
  String error_msg ="";
  DateTime? lastUpdate;

  JammerProfileModel? _jammer_profile = null;
  JammerSettingsModel? _jammer_settings = null;
  Map<String, WaveformEntry> waveforms = {};

  JammerProfileModel? get profile => _jammer_profile;
  JammerSettingsModel? get settings => _jammer_settings;

  JammerStateProvider(this._service) {
    _state_timer= Timer.periodic(Duration(milliseconds: 1000), (timer) async{
      //print("Updating state: ${timer.tick}");
      await refresh_state();
    });
  }

  Future<void> refresh_state() async {
    // api call
    try{
      final response = await _service.get_state();
      _jammer_profile = response.profile;
      _jammer_settings = response.settings;

      final jammerWavforms = await _service.get_waveform_list();
      waveforms = { for (var element in jammerWavforms.map((e) =>
          WaveformEntry(e, "tbd", false, true, isJammer: true))) element.name : element };

      _failed_attemps=0;
      error_msg="";
      lastUpdate= DateTime.now();
    }
    on Exception catch (e)  {
      _failed_attemps++;
      error_msg= e.toString();
    }
    if(_failed_attemps >5){
      _jammer_settings=null;
      _jammer_profile=null;
      waveforms = {};
    }
    // update state
    notifyListeners();
  }

}
