import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../components/LoadingWidget.dart';
import '../../../components/ZoomableGraph.dart';
import '../../../providers/GraphDataProvider.dart';

class WaveformDetailTimeGraph extends StatelessWidget {
  final int nr_points_threshold = 10000;
  final double sample_rate_sps;

  const WaveformDetailTimeGraph({super.key, this.sample_rate_sps=3.072E9});

  @override
  Widget build(BuildContext context) {
    GraphDataProvider graphs =
        Provider.of<GraphDataProvider>(context, listen: true);

    if (!graphs.isWaveformReady) {
      return const LoadingWidget();
    }

    if (graphs.waveform_all_points.isEmpty) {
      return const Text("No data!");
    }
    int middle_value = graphs.waveform_all_points.last.x ~/ 2 + 1;

    return ZoomableChart(
        maxX: graphs.waveform_all_points.last.x - 1,
        builder: (p0, p1) {
          double real_points_in_view =
              (p1 - p0) / graphs.waveform_all_points.length;
          double threshon_total_points =
              nr_points_threshold / graphs.waveform_all_points.length;
          //print("real_points_in_view: $real_points_in_view:$threshon_total_points");
          List<FlSpot> render_spots = graphs.waveform_avg_spots;
          if (real_points_in_view <= threshon_total_points) {
            render_spots =
                graphs.waveform_all_spots.sublist(p0.toInt(), p1.toInt());
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
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                    axisNameWidget: Text("Time (ms)"),
                    sideTitles: SideTitles(
                        reservedSize: 30,
                        showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text("${sample_idx_to_time(value.toInt()).toStringAsFixed(4)}");
                      },
                      interval: (p1-p0)/10,
                    )
                ),
              ),
            ),
          );
        });
    }

    double sample_idx_to_time(int sample_idx){
    double ts= (sample_idx/(sample_rate_sps))*1000 ;
      return ts;
    }
}
