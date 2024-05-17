import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:fftea/fftea.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jam_app/components/LoadingWidget.dart';
import 'package:jam_app/models/WaveformEntry.dart';
import 'package:jam_app/components/ZoomableGraph.dart';

import '../graph_utils.dart';

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

  int nr_points_threshold = 10000;
  bool below_threshold = false;
  bool full_render_upclose = false;

  @override
  Widget build(BuildContext context) {
    if(isLoading){
      return LoadingWidget();
    }

    if(spots.isEmpty){
      return Text("No fft data");
    }

    return ZoomableChart(
      maxX: spots.last.x,
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
                topTitles: const AxisTitles(
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

  print("Waveform ${entry.name}\nNr. Points:${entry.cache_fft.length}");

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

