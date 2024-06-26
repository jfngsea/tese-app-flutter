import 'package:flutter/material.dart';
import 'package:jam_app/models/JammerProfileModel.dart';
import 'package:jam_app/models/JammerSettingsModel.dart';

import '../pages/waveform/waveform_details_page.dart';
class ProfileContentCard extends StatelessWidget {
  final JammerProfileModel profile;
  const ProfileContentCard(this.profile, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          child: Column(
            children: [
              ListTile(
                title: Text("Waveform: ${profile.waveform_name} (${profile.waveform_format})"),
                trailing: IconButton(
                  icon: Icon(Icons.arrow_forward),
                  onPressed: () async {
                    final res = await Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => WaveformDetailPageName(profile.waveform_name)
                    ));

                    if(res!= null && res as bool == false){
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Waveform not reachable! (${profile.waveform_name})")));
                    }
                  },
                ),
              ),
              const Divider(),
              ListTile(
                title: Text("Frequency: ${profile.mixer_freq} MHz"),
              ),
              ListTile(
                title: Text("Phase: ${profile.mixer_phase}"),
              ),
              //const Divider(),
              if(profile.decimation_factor !=null) ...[
                ListTile(
                  title: Text("Decimation: ${profile.decimation_factor!}"),
                ),
              ],
              if(profile.interpolation_factor !=null) ...[
                ListTile(
                  title: Text("Interpolation: ${profile.interpolation_factor!}"),
                ),
              ],


            ],
          ),
        ),
      ],
    );


  }
}
