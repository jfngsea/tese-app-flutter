import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:fftea/fftea.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jam_app/components/LoadingWidget.dart';
import 'package:jam_app/models/WaveformEntry.dart';

enum RenderTypeEnum{
  all_points,
  all_points_with_min_concat,
  all_points_above_min_values,
  avg_below_min,
  avg_all_threshold,
  avg_all,

}

class WaveformGraph extends StatefulWidget {
  final WaveformEntry entry;
  const WaveformGraph(this.entry, {super.key});

  @override
  State<WaveformGraph> createState() => _WaveformGraphState();
}

class _WaveformGraphState extends State<WaveformGraph> {
  bool isLoading = true;
  List<FlSpot> spots = [];
  List<FlSpot> all_spots = [];

  double min_y_val = 0;
  RenderTypeEnum rendertype = RenderTypeEnum.avg_all;

  double minX =0 , maxX=0;
  int zoom=0;
  int panning_offset = 0;


  int nr_points_threshold = 10000;
  bool below_threshold = false;
  bool full_render_upclose = false;

  void update_graph({int? new_zoom, int? panning }){
    new_zoom ??= zoom;
    panning ??= panning_offset;

    double percentagem_to_remove = min(new_zoom / 100, 0.999);
    //int nr_points_keep = max((all_spots.length * percentagem_to_keep).toInt(), 1);

    int n_points_remove = (all_spots.length * percentagem_to_remove)~/2;
    minX =all_spots[n_points_remove].x.toDouble();
    maxX = (all_spots[all_spots.length-n_points_remove-1].x).toDouble();

    if(maxX < minX){
      print("maxX < minX");
    }

    int points_left = (maxX - minX).toInt();

    //print("Zoom: $zoom | Remove # points: $n_points_remove | total points left: $points_left | x: $minX:$maxX");


    if(!below_threshold && points_left < nr_points_threshold){
      print("Below threshold! (${points_left}");
      below_threshold = true;
    }
    else if(below_threshold && points_left > nr_points_threshold ) {
      print("Above threshold!(${points_left}");
      below_threshold = false;
    }

    setState(() {
      minX += panning!;
      maxX+=panning;

      zoom = new_zoom!;
      panning_offset=panning;
    });


  }

  @override
  Widget build(BuildContext context) {
    if(isLoading){
      return LoadingWidget();
    }

    if(spots.isEmpty){
      return Text(" No fft data");
    }

    return Column(
      children: [
        SizedBox(
          height: 500,
          child: LineChart(
            LineChartData(
              minX: minX,
              maxX: maxX,
              clipData: const FlClipData.all(),
              lineBarsData: [
                LineChartBarData(
                  spots: (full_render_upclose && below_threshold) ? all_spots.sublist(minX.toInt(), maxX.toInt()):spots,
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
    Text("Full render up close: $full_render_upclose"),
    Switch(value: full_render_upclose, onChanged: (value) => setState(() {
      full_render_upclose=value;
    }),),

    Text("Panning: $panning_offset"),
    Slider(value: panning_offset.toDouble(), max: all_spots.length.toDouble(), onChanged: (value) => update_graph(panning: value.toInt()),),

    Text("Zoom: $zoom"),
      Slider(
        value: zoom.toDouble(),
        max: 100,
        divisions: 100,
        onChanged: (value) => update_graph(new_zoom: value.toInt()
        )),


        Text("Min Y: $min_y_val"),
        TextField(
          onSubmitted: (val){
            setState(() {
              min_y_val= double.parse(val);
              init_process_entry();
            });
          },
        ),
        Text("render:"),
        
        ...RenderTypeEnum.values.map((e) => RadioListTile<RenderTypeEnum>(
          title: Text(e.name.replaceAll("_", " ")),
            value: e,
            groupValue: rendertype,
            onChanged: (RenderTypeEnum? value) {
              setState(() {
                rendertype = value!;
                print("Changed Rendertype to: $rendertype");
                init_process_entry();
              });
            },
        )).toList()

      ],
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    init_process_entry();
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

    final result = await process_entry(widget.entry, min_y_val: min_y_val, type: rendertype);
    final _spots = await points_to_flspot(result);
    final _allSpots = await points_to_flspot(widget.entry.cache_fft);

    setState(() {
      spots = _spots;
      all_spots=_allSpots;
      minX=0;
      maxX=_allSpots.last.x;
      isLoading = false;
    });
  }
}


List<Point<double>> get_fft(String file_path) {
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

  //return l_plot;

  // convert to points as to keep both x and y information
  List<Point<double>> points = List.generate(l_plot.length,
          (index) => Point<double>(index.toDouble(), l_plot[index]));

  return points;
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

Future<List<Point<double>>> process_entry(WaveformEntry entry, {double min_y_val = 0, int movavg_buf_size=1, RenderTypeEnum type=RenderTypeEnum.all_points_above_min_values}) async {


  if (entry.cache_fft.isEmpty) {
    // compute fft of the signal
    List<Point<double>> points = await compute(get_fft, entry.file_path);

    // cache filtered fft results for next renders
    entry.cache_fft = points;
  }

  print(
      "Waveform ${entry.name}\nNr. Points:${entry.cache_fft.length}");

  Map args = {};
  args.putIfAbsent("fft_res", () => entry.cache_fft);


  args.putIfAbsent("min_value", () => min_y_val);
  args.putIfAbsent("movavg_buf_len", () => movavg_buf_size);
  args.putIfAbsent("rendertype", () => type);

  // apply filters
  final List<Point<double>> result = await compute((args) {
    List<Point<double>> points = args["fft_res"] as List<Point<double>>;

    double min_value = args["min_value"] as double;
    int movavg_buf_len = args["movavg_buf_len"] as int;
    RenderTypeEnum type = args["rendertype"] as RenderTypeEnum;

    // 2.a) find first non zero value
    int zero_1_idx = 0;
    for (int i = 0; i < points.length; i++) {
      if (points[i].y > min_value) {
        zero_1_idx = i;
        break;
      }
    }

    //2.b) find last non zero value
    int zero_2_idx = points.length - 1;
    for (int i = points.length - 1; i >= 0; i--) {
      if (points[i].y > min_value) {
        zero_2_idx = i + 1;
        break;
      }
    }


    /*List<double> avg_hist = [];

    for(int i= zero_1_idx+1; i<zero_2_idx; i++){
      avg_hist.add(points[i].y);
      if (avg_hist.length > movavg_buf_len) {
        avg_hist.removeAt(0);
      }
      final sum = avg_hist.reduce((value, element) => value + element);
      points[i]= Point(points[i].x, sum / avg_hist.length);
    }*/

   

    switch(type){
      case RenderTypeEnum.all_points_with_min_concat: {
        points = points.map((e) => (e.y < min_value) ? Point(e.x, min_value) : e).toList();
      }
      case RenderTypeEnum.all_points_above_min_values:
        {
          // update all values below the min_value to min_value
          points = points.map((e) => (e.y < min_value) ? Point(e.x, min_value) : e).toList();

          // remove points between last  and zero 2
          if(zero_2_idx < points.length-1){
            points.removeRange(zero_2_idx+1, points.length-1);
          }

          // remove points between forst and zero 1
          if(zero_1_idx>1){
            points.removeRange(1, zero_1_idx-1);
          }
          break;
        }
      case RenderTypeEnum.avg_below_min:
        {
          points= avg_below_threshold(points, zero_1_idx, zero_2_idx, 100);
          break;
        }
      case RenderTypeEnum.avg_all_threshold:{
        points=avg_all_threshold(points, zero_1_idx, zero_2_idx);
        break;
      }
      case RenderTypeEnum.avg_all:{
        points=avg_range(points, 0, points.length, points.length~/100);
        break;
      }
      case _:
        break;


    }


    return points;
  }, args);

  // add back one zero field in beginning and end (for visualization)


  print(
      "Filters Done!\nNr Points (new): ${result.length} (${(result.length.toDouble() / entry.cache_fft.length) * 100} %)");

  // map points into flspot for the graph
  return result;
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


List<Point<double>> avg_below_threshold(List<Point<double>> points, int zero1, int zero2, int n_points_section){
  points = avg_range(points, zero2, points.length, n_points_section);
  points = avg_range(points, 0, zero1, n_points_section);

  return points;
}

List<Point<double>> avg_all_threshold(List<Point<double>> points, int zero1, int zero2){
  points = avg_range(points, zero2, points.length, points.length~/100);
  points = avg_range(points, zero1, zero2, points.length~/100);
  points = avg_range(points, 0, zero1, points.length~/100);

  return points;
}