import 'package:flutter/material.dart';
import 'package:jam_app/models/JammerSettingsModel.dart';

class JammerSettingsCard extends StatelessWidget {
  final JammerSettingsModel settings;
  const JammerSettingsCard(this.settings, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child:Column(
        children: [
          ListTile(
            title: Text("Current Settings", style: Theme.of(context).textTheme.headlineSmall,),

          ),
          const Divider(),

          if(settings.mixer_freq !=null) ...[
            ListTile(
              title: Text("Frequency: ${settings.mixer_freq!}"),
            ),
          ],
          if(settings.mixer_phase !=null) ...[
            ListTile(
              title: Text("Phase: ${settings.mixer_phase!}"),
            ),
          ],


          if(settings.decimation_factor !=null) ...[
            ListTile(
              title: Text("Decimation: ${settings.decimation_factor!}"),
            ),
          ],
          if(settings.interpolation_factor !=null) ...[
            ListTile(
              title: Text("Interpolation: ${settings.interpolation_factor!}"),
            ),
          ],
        ],
      ),
    );
  }
}
