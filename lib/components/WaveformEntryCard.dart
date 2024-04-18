import 'package:flutter/material.dart';
import 'package:jam_app/models/WaveformEntry.dart';

class WaveformEntryListTile extends StatelessWidget {
  final WaveformEntry entry;
  final Function(WaveformEntry) onClick;

  const WaveformEntryListTile(this.entry, this.onClick, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(

        leading: Icon(
          Icons.wifi_channel,
        ),
        title: Text(entry.name),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // make sure its the same ordern as WaveformFilter
            Icon(
              Icons.smartphone,
              color: entry.isLocal==true ? Colors.lightGreen : Colors.orange,
            ),
            Icon(Icons.settings_input_antenna,
                color: entry.isJammer==true ? Colors.lightGreen : Colors.orange),
          ],
        ),
        onTap: () {this.onClick(entry);},
      ),
    );
  }
}
