class JammerProfileModel{
  String waveform_format;
  String waveform_name;

  double mixer_freq;
  double mixer_phase;

  int? decimation_factor;
  int? interpolation_factor;

  JammerProfileModel(
      this.waveform_format,
      this.waveform_name,
      this.mixer_freq,
      this.mixer_phase,
      [this.decimation_factor, this.interpolation_factor]
      );

    factory JammerProfileModel.fromJSON(Map<String, dynamic> json){

      final model = JammerProfileModel(
          json["waveform_format"] as String,
          json["waveform_name"] as String,
          double.parse(json["mixer_freq"].toString()),
          double.parse(json["mixer_phase"].toString()),
        );

      model.decimation_factor= json['decimation_factor']==null? null: (json['decimation_factor'] as num).round();
      model.interpolation_factor =json['interpolation_factor']==null? null: (json['interpolation_factor'] as num).round();

      return model;
    }
}