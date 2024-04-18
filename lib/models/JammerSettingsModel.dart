class JammerSettingsModel{
  double? mixer_freq;
  double? mixer_phase;

  int? nyquist_zone;
  int? decimation_factor;
  int? interpolation_factor;


  JammerSettingsModel();

  factory JammerSettingsModel.fromJSON(Map<String, dynamic> json){

    JammerSettingsModel settings = JammerSettingsModel();

    settings.mixer_freq = double.parse(json["mixer_freq"].toString());
    settings.mixer_phase =json['mixer_phase']==null? null: (json['mixer_phase'] as num).toDouble();
    settings.nyquist_zone =json['nyquist_zone']==null? null: (json['nyquist_zone'] as num).round();
    settings.decimation_factor = json['decimation_factor']==null? null: (json['decimation_factor'] as num).round();
    settings.interpolation_factor = json['interpolation_factor']==null? null: (json['interpolation_factor'] as num).round();

    return settings;
  }
}