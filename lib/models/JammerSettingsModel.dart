class JammerSettingsModel{
  double? mixer_freq;
  double? mixer_phase;


  int? decimation_factor;
  int? interpolation_factor;


  JammerSettingsModel({this.mixer_phase, this.mixer_freq, this.decimation_factor, this.interpolation_factor});

  factory JammerSettingsModel.fromJSON(Map<String, dynamic> json){

    JammerSettingsModel settings = JammerSettingsModel();

    settings.mixer_freq =  json['mixer_freq']==null? null: (json['mixer_freq'] as num).toDouble();
    settings.mixer_phase =json['mixer_phase']==null? null: (json['mixer_phase'] as num).toDouble();
    //settings.nyquist_zone =json['nyquist_zone']==null? null: (json['nyquist_zone'] as num).round();
    settings.decimation_factor = json['decimation_factor']==null? null: (json['decimation_factor'] as num).round();
    settings.interpolation_factor = json['interpolation_factor']==null? null: (json['interpolation_factor'] as num).round();

    return settings;
  }

  factory JammerSettingsModel.from(JammerSettingsModel model){
    return JammerSettingsModel(
      mixer_freq: model.mixer_freq,
      mixer_phase: model.mixer_phase,
      decimation_factor: model.decimation_factor,
      interpolation_factor: model.interpolation_factor,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      "mixer_freq":mixer_freq,
      "mixer_phase":mixer_phase,
      "decimation_factor":decimation_factor,
      "interpolation_factor":interpolation_factor,
    };

    return json..removeWhere((key, value) => value ==null);
  }
}