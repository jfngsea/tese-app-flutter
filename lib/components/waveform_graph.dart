import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:fftea/fftea.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/WaveformEntry.dart';
import 'LoadingWidget.dart';

class WaveformGraphWidget extends StatefulWidget {
  final WaveformEntry entry;

  const WaveformGraphWidget(this.entry, {super.key});

  @override
  State<WaveformGraphWidget> createState() => _WaveformGraphWidgetState();
}

class _WaveformGraphWidgetState extends State<WaveformGraphWidget> {
  bool isLoading = true;
  File? wf_file;
  List<FlSpot> spots = [];

  String? img_path;

  double _min_y_val = 0;
  double _movavg_buf_len = 1.0;
  double min_y_val = 0;
  double movavg_buf_len = 10;

  @override
  void initState() {
    super.initState();
    //init_process_entry();
  }

  @override
  Widget build(BuildContext context) {
     final chart1 = LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );



    return Column(
      children: [
        SizedBox(
          height: 500,
          width: 400,
          child: WFGraph(
            widget.entry,
            min_y_val,
            movavg_buf_len
          )
        ),
        Text("Min Y value: $_min_y_val"),
        Slider(
          value: _min_y_val,
          onChanged: (value) {
            setState(() {
              _min_y_val = value.round().toDouble();
            });
          },
          onChangeEnd: (value) {
            setState(() {
              //print("Updated min_y_val");
              min_y_val = _min_y_val;
            });
          },
          max: 50,
        ),
        Text("Moving Avg Buffer Length: $_movavg_buf_len"),
        Slider(
          max: 1000,
          min: 1.0,
          divisions: 1000,
          value: _movavg_buf_len,
          onChanged: (value) {
            setState(() {
              _movavg_buf_len = value.round().toDouble();
            });
          },
          onChangeEnd: (value) {
            setState(() {
              //print("Updated movavg_buf_len");

              movavg_buf_len = _movavg_buf_len;
            });
          },
        ),
      ],
    );
  }

  void init_process_entry() async {
    final file = File(widget.entry.file_path);

    // check made more sense i  precious version
    // obsolete
    if (!file.existsSync()) {
      setState(() {
        wf_file = null;
        isLoading = false;
      });
      return;
    }

    final _spots = await process_entry();

    final _img_path =
        "${Platform.environment['HOME']}/.local/share/jam_app/wf_img/${widget.entry.name}";
    Directory("${Platform.environment['HOME']}/.local/share/jam_app/wf_img/")
        .createSync(recursive: true);

    setState(() {
      spots = _spots;
      wf_file = file;
      isLoading = false;
      img_path = _img_path;
    });
  }

  Future<List<FlSpot>> process_entry() async {

    if (widget.entry.cache_fft.isEmpty) {
      // compute fft of the signal
      List<double> fft_result = await compute(get_fft, widget.entry.file_path);

      // cache filtered fft results for next renders
      widget.entry.cache_fft = fft_result;
    }

    print(
        "Waveform ${widget.entry.name}\nNr. Points:${widget.entry.cache_fft.length}");

    Map args = {};
    args.putIfAbsent("fft_res", () => widget.entry.cache_fft);
    args.putIfAbsent("min_value", () => min_y_val);
    args.putIfAbsent("movavg_buf_len", () => movavg_buf_len);

    // apply filters
    final List<Point<double>> result = await compute((args) {
      double min_value = args["min_value"] as double;
      double movavg_buf_len = args["movavg_buf_len"] as double;
      List<double> fft_res = args["fft_res"] as List<double>;

      // 1) update all values below the min_value to min_value
      final min_val_filter =
          fft_res.map((e) => (e < min_value) ? min_value : e).toList();

      // convert to points as to keep both x and y information
      List<Point<double>> points = List.generate(min_val_filter.length,
          (index) => Point<double>(index.toDouble(), min_val_filter[index]));

      // 2.a) find first non zero value
      int zero_1_idx = 0;
      for (int i = 0; i < points.length; i++) {
        if (points[i].y > min_value) {
          zero_1_idx = i;
          break;
        }
      }

      //2.b)
      int zero_2_idx = points.length - 1;
      for (int i = points.length - 1; i >= 0; i--) {
        if (points[i].y > min_value) {
          zero_2_idx = i + 1;
          break;
        }
      }

      points.removeRange(zero_2_idx+1, points.length-1);
      points.removeRange(1, zero_1_idx-1);


      //points = points.sublist(zero_1_idx, zero_2_idx);

      List<double> avg_hist = [];

      for(int i= zero_1_idx+1; i<zero_2_idx; i++){
        avg_hist.add(points[i].y);
        if (avg_hist.length > movavg_buf_len) {
          avg_hist.removeAt(0);
        }
        final sum = avg_hist.reduce((value, element) => value + element);
        points[i]= Point(points[i].x, sum / avg_hist.length);
      }

      /*points = points.map((e) {
        avg_hist.add(e.y);
        if (avg_hist.length > moving_nr) {
          avg_hist.removeAt(0);
        }

        final sum = avg_hist.reduce((value, element) => value + element);
        final y = sum / avg_hist.length;

        return Point(e.x, y);
      }).toList();*/



      return points;
    }, args);

    // add back one zero field in beginning and end (for visualization)


    print(
        "Filters Done!\nNr Points (new): ${result.length} (${(result.length.toDouble() / widget.entry.cache_fft.length) * 100} %)");

    // map points into flspot for the graph
    List<FlSpot> _spots = await compute((points) {
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
    }, result);

    return _spots;
  }
}

List<double> get_fft(String file_path) {
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
  final l2 = iqList.map((val) {
    int signal = val & signal_mask == signal_mask ? -1 : 1;

    // remove signal bit
    val &= data_mask;

    double val_double = (val * (pow(2, (-frac_length)))).toDouble();

    if (signal == -1) {
      val_double = 1 - val_double;
    }

    return signal * val_double;
  }).toList();

  final l2_5 = [
    for (int i = 0; i < l2.length - 1; i += 2) Float64x2(l2[i + 1], l2[i])
  ];

  final l3 = Float64x2List.fromList(l2_5);

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

  return l_plot;
}

List<FlSpot> get_spots(List<double> fft_result) {
  final sampleRate = (3.072e9).toDouble();
  final deltaFrequency = sampleRate / fft_result.length;

  //fft_result = fft_result.where((element) => element > -10.0).toList();

  List<FlSpot> _freqs = List<FlSpot>.generate(
    //1 + l4.length ~/ 2,
    fft_result.length,
    (n) {
      return FlSpot(n.toDouble(), fft_result[n]);
      return FlSpot(n * deltaFrequency, fft_result[n]);
    },
  );
  return _freqs;
}

class WFGraph extends StatefulWidget {
  final WaveformEntry entry;
  final double min_y_val;
  final  double movavg_buf_len;

  const WFGraph(this.entry, this.min_y_val, this.movavg_buf_len);

  @override
  State<WFGraph> createState() => _WFGraphState();
}

class _WFGraphState extends State<WFGraph> {
  List<FlSpot> spots = [];
  bool isLoading = true;


  @override
  void initState() {
    super.initState();
    init_process_entry();
  }

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
    return FutureBuilder(
      future: process_entry(),
      builder: (context, snapshot) {
        if(snapshot.hasData){
          return LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: snapshot.data!,
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          );
        }
        return LoadingWidget();
      },
    );
  }

  void init_process_entry() async {
    final file = File(widget.entry.file_path);

    // check made more sense i  precious version
    // obsolete
    if (!file.existsSync()) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final _spots = await process_entry();


    setState(() {
      spots = _spots;
      isLoading = false;
    });
  }


  Future<List<FlSpot>> process_entry() async {


    if (widget.entry.cache_fft.isEmpty) {
      // compute fft of the signal
      List<double> fft_result = await compute(get_fft, widget.entry.file_path);

      // cache filtered fft results for next renders
      widget.entry.cache_fft = fft_result;
    }

    print(
        "Waveform ${widget.entry.name}\nNr. Points:${widget.entry.cache_fft.length}");

    Map args = {};
    args.putIfAbsent("fft_res", () => widget.entry.cache_fft);
    args.putIfAbsent("min_value", () => widget.min_y_val);
    args.putIfAbsent("movavg_buf_len", () => widget.movavg_buf_len);

    // apply filters
    final List<Point<double>> result = await compute((args) {
      double min_value = args["min_value"] as double;
      double movavg_buf_len = args["movavg_buf_len"] as double;
      List<double> fft_res = args["fft_res"] as List<double>;

      // 1) update all values below the min_value to min_value
      final min_val_filter =
      fft_res.map((e) => (e < min_value) ? min_value : e).toList();

      // convert to points as to keep both x and y information
      List<Point<double>> points = List.generate(min_val_filter.length,
              (index) => Point<double>(index.toDouble(), min_val_filter[index]));

      // 2.a) find first non zero value
      int zero_1_idx = 0;
      for (int i = 0; i < points.length; i++) {
        if (points[i].y > min_value) {
          zero_1_idx = i;
          break;
        }
      }

      //2.b)
      int zero_2_idx = points.length - 1;
      for (int i = points.length - 1; i >= 0; i--) {
        if (points[i].y > min_value) {
          zero_2_idx = i + 1;
          break;
        }
      }

      List<double> avg_hist = [];

      for(int i= zero_1_idx+1; i<zero_2_idx; i++){
        avg_hist.add(points[i].y);
        if (avg_hist.length > movavg_buf_len) {
          avg_hist.removeAt(0);
        }
        final sum = avg_hist.reduce((value, element) => value + element);
        points[i]= Point(points[i].x, sum / avg_hist.length);
      }

      points.removeRange(zero_2_idx+1, points.length-1);
      points.removeRange(1, zero_1_idx-1);


      //points = points.sublist(zero_1_idx, zero_2_idx);





      return points;
    }, args);

    // add back one zero field in beginning and end (for visualization)


    print(
        "Filters Done!\nNr Points (new): ${result.length} (${(result.length.toDouble() / widget.entry.cache_fft.length) * 100} %)");

    // map points into flspot for the graph
    List<FlSpot> _spots = await compute((points) {
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
    }, result);

    return _spots;
  }
}
