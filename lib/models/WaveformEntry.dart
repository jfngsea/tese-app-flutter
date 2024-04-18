import 'dart:math';
class WaveformEntry {
  String name;
  String format;
  bool inLocal, inJammer;

  bool? isLocal, isJammer;

  String file_path = "";
  
  List<Point<double>> points_fft = [];

  List<double> _cache_fft = [];
  List<double> get cache_fft => _cache_fft;
  set cache_fft(List<double> value) {
    _cache_fft = value;
    // todo: save fft cache to filesystem
  }

  WaveformEntry(this.name, this.format, this.inLocal, this.inJammer,
      {this.isLocal, this.isJammer, String this.file_path = ""});
}
