import 'package:jam_app/models/JammerProfileModel.dart';
import 'package:jam_app/models/JammerSettingsModel.dart';

class JammerStateModel {
  JammerProfileModel? profile;
  JammerSettingsModel? settings;


  JammerStateModel(this.profile, this.settings);

  factory JammerStateModel.fromJSON(Map<String, dynamic> json){
    return JammerStateModel(
        json["profile"]!=null? JammerProfileModel.fromJSON(json["profile"]):null,
        json["settings"]!=null? JammerSettingsModel.fromJSON(json["settings"]):null,
    );
  }
}