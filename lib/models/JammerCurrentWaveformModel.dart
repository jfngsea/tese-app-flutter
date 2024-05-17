class JammerCurrentWaveformModel{
  String filename;
  int offset;
  bool isBase;

  JammerCurrentWaveformModel(this.filename, this.offset, {this.isBase = false});

  factory JammerCurrentWaveformModel.fromJSON(Map<String, dynamic> json) {
    int offset = json["offset"] as int;
    return JammerCurrentWaveformModel(
        json["filename"] as String,
        offset,
      isBase: offset == 0
    );
  }
}