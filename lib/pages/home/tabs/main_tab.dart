import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:jam_app/components/JammerCurrentWaveformCard.dart';
import 'package:jam_app/components/JammerProfileCard.dart';
import 'package:jam_app/components/jammerSettingsCard.dart';
import 'package:jam_app/providers/JammerStateProvider.dart';
import 'package:provider/provider.dart';

class MainTab extends StatefulWidget {
  const MainTab({super.key});

  @override
  State<MainTab> createState() => _MainTabState();
}

class _MainTabState extends State<MainTab> {
  final host_text_controler = TextEditingController();
  bool has_host_been_set = false;



  @override
  Widget build(BuildContext context) {
    JammerStateProvider provider =
        Provider.of<JammerStateProvider>(context, listen: true);

    if(!has_host_been_set && host_text_controler.text.isEmpty){
      host_text_controler.text= provider.host_url;
      //has_host_been_set=true;
    }

    Color urlBorderColor;
    switch (provider.connection_state) {
      case JammerConnectionState.ok:
        urlBorderColor = Colors.lightGreen;
        break;
      case JammerConnectionState.warning:
        urlBorderColor = Colors.orange;
        break;
      default:
        urlBorderColor = Colors.redAccent;
    }

    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView(
            children: [
              // Host URL Field
              TextField(
                controller: host_text_controler,
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: urlBorderColor,
                    ),
                  ),
                  labelText: 'Host URL',
                ),
                onSubmitted: (String val) {
                  provider.host_url = val;
                },
              ),

              // Connection Error (if)
              if (provider.error_msg.isNotEmpty) ...[
                Text("Error: ${provider.error_msg}")
              ],
      
              if (provider.connection_state == JammerConnectionState.fail) ...[
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.link_off, size: 96, color: Colors.orangeAccent,),
                      Text("No connection with the jammer!"),
                    ],
                  ),
                ),
              ] else ...[
                // Transmission and Reset Row

                ListTile(
                  title: const Text("Transmission"),
                  trailing: Switch(
                    value: provider.jammer_state?.trasmission_on ?? false,
                    onChanged: (value) async {
                      if( await provider.transmission_poweron(value)){

                      } else {
                        ScaffoldMessenger
                            .of(context)
                            .showSnackBar(const SnackBar(
                          content: Text('Failed to change transmission'),
                        ));
                      }
                  },),
                ),

                ListTile(
                  title: const Text("Reset Jammer State"),
                  trailing: TextButton(
                    child: const Text("Reset"),
                    onPressed: () async {
                      if( !(await provider.reset()) ){
                        ScaffoldMessenger
                            .of(context)
                            .showSnackBar(const SnackBar(
                          content: Text('Failed to Reset'),
                        ));

                      }
                    },
                  ),
                ),
                if(provider.jammer_state!.settings != null) ...[


                ListTile(
                    title: const Text("Configuration set by:"),
                  trailing: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      style: Theme.of(context).textTheme.bodyMedium,
                      provider.jammer_state!.profile == null?
                          "Script" : "Profile"
                    ),
                  ),
                ),
                    ],
                const Divider(),

                /*CarouselSlider(
                  items: [
                    if(provider.profile!=null) ...[
                      JammerProfileCard(provider.profile!),
                    ],

                    if(provider.settings!=null) ...[
                      JammerSettingsCard(provider.settings!),
                    ],
                  ],
                  options: CarouselOptions(
                    enableInfiniteScroll: false,
                    initialPage: 0,

                  ),
                ),*/

                JammerCurrentWaveformCard(waveform:  provider.jammer_state!.ddr_state),




                if(provider.settings != null) ...[
                  JammerSettingsCard(provider.settings!),
                ],



              ],
            ],
          ),
        ),
      ),
    );
  }
}
