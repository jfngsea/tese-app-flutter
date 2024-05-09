import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:fftea/fftea.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jam_app/components/LoadingWidget.dart';
import 'package:jam_app/models/WaveformEntry.dart';
import 'package:jam_app/pages/waveform/ZoomableGraph.dart';

enum RenderTypeEnum{
  all_points,
  avg_all,

}

class WaveformGraphV2 extends StatefulWidget {
  final WaveformEntry entry;
  const WaveformGraphV2(this.entry, {super.key});

  @override
  State<WaveformGraphV2> createState() => _WaveformGraphV2State();
}

class _WaveformGraphV2State extends State<WaveformGraphV2> {
  bool isLoading = true;
  List<FlSpot> spots = [];
  List<FlSpot> all_spots = [];
  double maxY=50,minY=0;

  double min_y_val = 0;
  RenderTypeEnum rendertype = RenderTypeEnum.avg_all;

  double graph_minX =0 , graph_maxX=0;
  double lastMinXValue =0 , lastMaxXValue=0;
  int _zoom=0;
  int _panning = 0;


  int nr_points_threshold = 10000;
  bool below_threshold = false;
  bool full_render_upclose = false;

  void reset_graph() {
    setState(() {
      graph_minX=0;
      graph_maxX = spots.last.x;
      _zoom =0;
      _panning =0;
      full_render_upclose =false;
    });
  }



  @override
  Widget build(BuildContext context) {
    if(isLoading){
      return LoadingWidget();
    }

    if(spots.isEmpty){
      return Text("No fft data");
    }

    bool render_all_points = (full_render_upclose && ((graph_maxX - graph_minX )<nr_points_threshold ));
    List<FlSpot> render_spots = render_all_points ? all_spots.sublist(graph_minX.toInt(), graph_maxX.toInt()):spots;

    double real_points_in_view = (graph_maxX-graph_minX)/all_spots.length;
    double threshon_total_points = nr_points_threshold / all_spots.length;
    print("real_points_in_view: $real_points_in_view:$threshon_total_points");
    if(real_points_in_view <= threshon_total_points){
      render_spots =all_spots.sublist(graph_minX.toInt(), graph_maxX.toInt());
    }

    return Column(
      children: [
        SizedBox(
          height: 500,
          child: ZoomableChart(
            maxX: graph_maxX,
            builder: (p0, p1) {
              double real_points_in_view = (p1-p0)/all_spots.length;
              double threshon_total_points = nr_points_threshold / all_spots.length;
              print("real_points_in_view: $real_points_in_view:$threshon_total_points");
              List<FlSpot> render_spots = spots;
              if(real_points_in_view <= threshon_total_points){
                render_spots =all_spots.sublist(p0.toInt(), p1.toInt());
              }

              return LineChart(
                LineChartData(
                  minX: p0,
                  maxX: p1,
                  lineTouchData: const LineTouchData(enabled: false),
                  clipData: const FlClipData.all(),
                  lineBarsData: [
                    LineChartBarData(
                      spots: render_spots,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                  titlesData:FlTitlesData(
                      topTitles: AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: false
                          )
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          interval: (p0 + (p1-p0)/2).roundToDouble(),
                          getTitlesWidget: (value, meta) {
                            int middle_value = all_spots.last.x~/2+1;
                            double  final_value= all_spots.last.x /(value.toInt() - middle_value);
                            int final_value_int = final_value==double.infinity?0:final_value.round();
                            if(final_value_int==0){
                              return Text("0");
                            }

                            if(final_value_int < 0) {
                              return Text("-Fs/${final_value_int.abs()}");
                            }
                            return Text("Fs/${final_value_int}");
                          },
                          reservedSize: 30,
                          showTitles: true,
                        ),
                      )
                  ),
                ),
              );

            },
          ),
        )
      ],
    );

    return Column(
      children: [
        SizedBox(
          height: 500,
          child: GestureDetector(
            onDoubleTap: reset_graph,
            onHorizontalDragStart: (details) {
              lastMinXValue = graph_minX;
              lastMaxXValue = graph_maxX;
            },
            onHorizontalDragUpdate: (details) {
              var horizontalDistance = details.primaryDelta ?? 0;
              if (horizontalDistance == 0) return;
              print(horizontalDistance);
              var lastMinMaxDistance = max(lastMaxXValue - lastMinXValue, 0.0);

              setState(() {
                graph_minX -= lastMinMaxDistance * 0.005 * horizontalDistance;
                graph_maxX -= lastMinMaxDistance * 0.005 * horizontalDistance;

                if (graph_minX < 0) {
                  graph_minX = 0;
                  graph_maxX = lastMinMaxDistance;
                }
                if (graph_maxX > all_spots.last.x) {
                  graph_maxX = all_spots.last.x;
                  graph_minX = graph_maxX - lastMinMaxDistance;
                }
                print("$graph_minX, $graph_maxX");
              });
            },


            onScaleStart: (details) {
              lastMinXValue = graph_minX;
              lastMaxXValue = graph_maxX;
            },
            onScaleUpdate: (details) {
              //print("onScaleUpdate");
              var horizontalScale = details.horizontalScale;
              //print(details);

              if (horizontalScale == 0) return;
              //print(horizontalScale);
              var lastMinMaxDistance = max(lastMaxXValue - lastMinXValue, 0);
              var newMinMaxDistance = max(lastMinMaxDistance / horizontalScale, 10);
              var distanceDifference = newMinMaxDistance - lastMinMaxDistance;
              //print("$lastMinMaxDistance, $newMinMaxDistance, $distanceDifference");
              setState(() {
                final newMinX = max(
                  lastMinXValue - distanceDifference,
                  0.0,
                );
                final newMaxX = min(
                  lastMaxXValue + distanceDifference,
                  all_spots.last.x,
                );

                if (newMaxX - newMinX > 2) {
                  graph_minX = newMinX.round().toDouble();
                  graph_maxX = newMaxX.roundToDouble();
                }
                //print("$graph_minX, $graph_maxX");
              });
            },

            child: LineChart(
              LineChartData(
                minX: graph_minX,
                maxX: graph_maxX,
                lineTouchData: const LineTouchData(enabled: false),
                clipData: const FlClipData.all(),
                lineBarsData: [
                  LineChartBarData(
                    spots: render_spots,
                    dotData: const FlDotData(show: false),
                  ),
                ],
                titlesData:FlTitlesData(
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false
                    )
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      interval: (graph_minX + (graph_maxX-graph_minX)/2).roundToDouble(),
                      getTitlesWidget: (value, meta) {
                        int middle_value = all_spots.last.x~/2+1;
                        double  final_value= all_spots.last.x /(value.toInt() - middle_value);
                        int final_value_int = final_value==double.infinity?0:final_value.round();
                        if(final_value_int==0){
                          return Text("0");
                        }

                        if(final_value_int < 0) {
                          return Text("-Fs/${final_value_int.abs()}");
                        }
                        return Text("Fs/${final_value_int}");
                      },
                      reservedSize: 30,
                      showTitles: true,
                    ),
                  )
                ),
              ),
            ),
          ),
        ),
        ElevatedButton(onPressed: reset_graph, child: Text("reset view")),
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
      graph_minX=0;
      graph_maxX=_allSpots.last.x;
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

Future<List<Point<double>>> process_entry(WaveformEntry entry, {double min_y_val = 0, int movavg_buf_size=1, RenderTypeEnum type=RenderTypeEnum.avg_all}) async {

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

  args.putIfAbsent("rendertype", () => type);

  // calc initial average
  final List<Point<double>> avg = await compute((points) {
    return avg_range(points, 0, points.length, points.length~/100); // averages all points into 1% of the total points
  }, entry.cache_fft);


  print(
      "Average Done!\nNr Points (new): ${avg.length} (${(avg.length.toDouble() / entry.cache_fft.length) * 100} %)");

  // map points into flspot for the graph
  return avg;
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




