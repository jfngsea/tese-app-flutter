import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:jam_app/models/WaveformEntry.dart';

import '../graph_utils.dart';


class GraphDataProvider extends ChangeNotifier {
  final WaveformEntry entry;

  bool _isLoading = true;
  String _isLoadingMsg = "";

  bool get isLoading => _isLoading;
  String get isLoadingMsg => _isLoadingMsg;

  void set_isLoading(bool value, {String message = ""}){
    _isLoading=value;
    _isLoadingMsg=message;
    notifyListeners();
  }

  String _errorMsg = "";
  String get errorMsg => _errorMsg;

  void set_errorMsg(String errorMsg, {bool isLoadingVal=false, String loadingmsg=""}){
    _errorMsg= errorMsg;
    set_isLoading(isLoadingVal, message: loadingmsg);
  }

  GraphDataProvider(this.entry){
    init_wf();
    init_spectrum();
    set_isLoading(false);
  }

  bool isSpectrumReady = false;
  List<FlSpot> spectrum_all_spots = [];
  List<FlSpot> spectrum_avg_spots = [];

  void init_spectrum() async {
    print("Init Spectrum");
    List<Point<double>> spectrum_all_points = await compute(get_fft, entry.file_path);
    print("Init Spectrum: fft done");


    spectrum_avg_spots =  await compute((points) {
      return points_to_flspot(avg_range(points, 0, points.length, points.length~/100));
    }, spectrum_all_points);
    print("Init Spectrum: avg done");

    spectrum_all_spots =  await compute((points) {
      return points_to_flspot(points);

    }, spectrum_all_points);
    print("Init Spectrum: spots done");


    isSpectrumReady=true;
    notifyListeners();
  }

  bool isWaveformReady = false;
  List<double> waveform_all_samples = [];
  List<Point<double>> waveform_all_points = [];
  List<FlSpot> waveform_all_spots = [];
  List<FlSpot> waveform_avg_spots = [];
  double? papr = null;

  void init_wf() async {
    print("Init wf");

    waveform_all_samples = await compute((file_path) {
      return get_file_samples_points(file_path)
          .map((fftVal) => sqrt(pow(fftVal.x, 2) + pow(fftVal.y, 2))) //abs values
          //.map((abs) => 10 * (log(abs) / ln10))
          .toList();
    }, entry.file_path);

    final job1 = compute((samples) {
      return List.generate(
          samples.length,
              (index) => Point<double>(index.toDouble(), samples[index]));
    }, waveform_all_samples);


    final job2 = compute((samples) {
      final samples_2 = samples.map((e) => pow(e, 2));

      //final min_val = samples_2.reduce(min);
      final max_val =  samples_2.reduce(max);
      final avg_val = samples_2.reduce((value, element) => value+element)/samples_2.length;

      final log10_val = (log((max_val/avg_val)) / ln10);

      return log10_val * 10;
    }, waveform_all_samples);


    papr = await job2;
    notifyListeners();

    waveform_all_points = await job1;

    waveform_avg_spots = await compute((samples) {
      return points_to_flspot(avg_range(samples, 0, samples.length, samples.length~/100));
    }, waveform_all_points);

    waveform_avg_spots.forEach((element) {
      if( element.y == double.infinity || element.y == -double.infinity){
        print("Element: ${element.x}");
      }
    });
    print("Init wf: avg done");

    isWaveformReady=true;
    notifyListeners();

    waveform_all_spots = await compute((samples) {
      return points_to_flspot(samples);
    }, waveform_all_points);
    print("Init wf: spots done");


    notifyListeners();
  }
}

Future<List<FlSpot>> points_to_flspot(List<Point<double>> points ) async {
  return await compute((points) {
    final sampleRate = (3.072e9).toDouble();
    final deltaFrequency = sampleRate / points.length;

    //fft_result = fft_result.where((element) => element > -10.0).toList();

    List<FlSpot> _freqs = List<FlSpot>.generate(
      //1 + l4.length ~/ 2,
      points.length,
          (n) {
        return FlSpot(points[n].x, points[n].y);
      },
    );
    return _freqs;
  }, points);

}