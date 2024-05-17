import 'package:jam_app/models/JammerCurrentWaveformModel.dart';
import 'package:jam_app/models/JammerProfileModel.dart';
import 'package:jam_app/models/JammerSettingsModel.dart';

class JammerStateModel {
  JammerProfileModel? profile;
  JammerSettingsModel? settings;
  JammerCurrentWaveformModel? ddr_state;
  bool trasmission_on;


  JammerStateModel(this.profile, this.settings, this.ddr_state, {bool this.trasmission_on = false});

  factory JammerStateModel.fromJSON(Map<String, dynamic> json){
    return JammerStateModel(
        json["profile"]!=null? JammerProfileModel.fromJSON(json["profile"]):null,
        json["settings"]!=null? JammerSettingsModel.fromJSON(json["settings"]):null,
        json["ddr"]!=null? JammerCurrentWaveformModel.fromJSON(json["ddr"]) : null,
        trasmission_on: json["rfdc_on"]!=null? json["rfdc_on"] as bool:false,
    );
  }
}