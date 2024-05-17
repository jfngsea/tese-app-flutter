import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../components/LoadingWidget.dart';
import '../../../components/ZoomableGraph.dart';
import '../../../providers/GraphDataProvider.dart';
class WaveformDetailSpectrumGraph extends StatelessWidget {
  final int nr_points_threshold = 10000;

  const WaveformDetailSpectrumGraph({super.key});

  @override
  Widget build(BuildContext context) {
    GraphDataProvider graphs = Provider.of<GraphDataProvider>(context, listen: true);

    if(!graphs.isSpectrumReady){
      return LoadingWidget();
    }

    if(graphs.spectrum_all_spots.isEmpty){
      return Text("No data!");
    }

    int middle_value = graphs.spectrum_all_spots.last.x~/2+1;

    return ZoomableChart(
      maxX: graphs.spectrum_all_spots.last.x,
      builder: (p0, p1) {
        double real_points_in_view = (p1-p0)/graphs.spectrum_all_spots.length;
        double threshon_total_points = nr_points_threshold / graphs.spectrum_all_spots.length;
        //print("real_points_in_view: $real_points_in_view:$threshon_total_points");
        List<FlSpot> render_spots = graphs.spectrum_avg_spots;
        if(real_points_in_view <= threshon_total_points){
          render_spots =graphs.spectrum_all_spots.sublist(p0.toInt(), p1.toInt());
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
            gridData: FlGridData(verticalInterval: (p0 + (p1-p0)/2).roundToDouble()),

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
                      double  final_value= graphs.spectrum_all_spots.last.x /(value.toInt() - middle_value);
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
}