import 'package:flutter/material.dart';
import 'package:jam_app/models/JammerCurrentWaveformModel.dart';

import '../pages/waveform/waveform_details_page.dart';



class JammerCurrentWaveformCard extends StatelessWidget {
  final JammerCurrentWaveformModel? waveform;
  const JammerCurrentWaveformCard({super.key, this.waveform});

  @override
  Widget build(BuildContext context) {
    if(waveform == null || waveform!.isBase){
      return Card(
        child: ListTile(
          leading: Icon(Icons.wifi_off, size: 48,),

          title: Text("No waveform is applied",style: Theme.of(context).textTheme.headlineSmall),
        ),
      );
    }
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text("Current Waveform", style: Theme.of(context).textTheme.headlineSmall),
          ),
          const Divider(),
          ListTile(
            title: Text("Name: ${waveform!.filename}"),
            trailing: IconButton(
              icon: Icon(Icons.arrow_forward),
              onPressed: () async {
                final res = await Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => WaveformDetailPageName(waveform!.filename)
                ));

                if(res!= null && res as bool == false){
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Waveform not reachable! (${waveform!.filename})")));
                }
              },
            ),
          )
        ],
      ),
    );
  }
}
