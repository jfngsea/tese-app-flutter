import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:fftea/fftea.dart';

/// Reads the file and transforms the 16bit float samples into dart native doubles
List<double> get_file_samples(String file_path){
  final _wf_file = File(file_path);

  final iqBuffer = _wf_file.readAsBytesSync().buffer;
  // reads byte buffer 16bit word at a time -> inverts samples from [I,Q] to [Q,I]
  //final iqList =iqBuffer.asUint16List(4);
  final iqList = iqBuffer.asUint16List(0);
  // todo: hardcoded
  int frac_length = 15;
  int signal_mask = 0x8000;
  int data_mask = 0x7fff;

  // map uint16 integers to doubles
  // iqlist is a set of 16 fixed poit float with 15 fractional bits
  return iqList.map((val) {
    int signal = val & signal_mask == signal_mask ? -1 : 1;

    // remove signal bit
    val &= data_mask;

    double val_double = (val * (pow(2, (-frac_length)))).toDouble();

    if (signal == -1) {
      val_double = 1 - val_double;
    }

    return signal * val_double;
  }).toList();
}

/// Reads a samples file and returns an iq sample as a Float64x2
List<Float64x2> get_file_samples_points(String file_path){
  // get the file samples as double: interleaved i and q samples
  final samples = get_file_samples(file_path);
  return [
    for (int i = 0; i < samples.length - 1; i += 2) Float64x2(samples[i + 1], samples[i])
  ];
}

List<Point<double>> get_fft(String file_path) {
  final l3 = Float64x2List.fromList(get_file_samples_points(file_path));

  final fft = FFT(l3.length);
  fft.inPlaceFft(l3);

  // l3 shift
  //aa = fft((up_signal_final));
  //aa = [aa(end/2:end); aa(1:end/2)];

  //l3.getRange(0, l3.length~/2);
  //l3.getRange(l3.length~/2, l3.length);

  final sl3 = List.of(l3.getRange(l3.length ~/ 2, l3.length));
  sl3.addAll(l3.getRange(0, l3.length ~/ 2));

  final l_abs =
  sl3.map((fftVal) => sqrt(pow(fftVal.x, 2) + pow(fftVal.y, 2))).toList();

  final l_plot = l_abs.map((abs) => 10 * (log(abs) / ln10)).toList();

  //return l_plot;

  // convert to points as to keep both x and y information
  List<Point<double>> points = List.generate(l_plot.length,
          (index) => Point<double>(index.toDouble(), l_plot[index]));

  return points;
}


List<Point<double>> avg_range(List<Point<double>> points, int start, int stop, int n_final_points){

  int n_elems_to_avg= stop - start;
  int partition_size = (n_elems_to_avg~/n_final_points);
  int n_elems_left = (n_elems_to_avg%n_final_points);

  List<Point<double>> new_points =[];

  int offset_factor=0;

  while(offset_factor<n_final_points-1){
    int offset = offset_factor * partition_size;
    double new_y = points.sublist(start+offset, start+offset+partition_size).reduce((value, element) => Point(-1, value.y+element.y)).y / partition_size;
    Point<double> new_point = Point((start+offset).toDouble(), new_y);
    new_points.add(new_point);
    offset_factor++;
  }

  //for the last
  int offset = offset_factor * partition_size;
  double new_y = points.sublist(start+offset, stop).reduce((value, element) => Point(-1, value.y+element.y)).y / (partition_size+n_elems_left);
  Point<double> new_point = Point((start+offset).toDouble(), new_y);
  new_points.add(new_point);
  points.removeRange(start, stop);
  points.insertAll(start, new_points);
  return points;
}