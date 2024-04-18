import 'package:flutter/material.dart';
import 'package:jam_app/components/ProfileContentCard.dart';
import 'package:jam_app/providers/JammerStateProvider.dart';
import 'package:provider/provider.dart';

class MainTab extends StatefulWidget {
  const MainTab({super.key});

  @override
  State<MainTab> createState() => _MainTabState();
}

class _MainTabState extends State<MainTab> {
  final host_text_controler = TextEditingController();



  @override
  Widget build(BuildContext context) {
    JammerStateProvider provider =
        Provider.of<JammerStateProvider>(context, listen: true);

    if(host_text_controler.text.isEmpty){
      host_text_controler.text= provider.host_url;
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
          child: Column(
            children: [
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
                if(provider.profile == null) ...[
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off, size: 96,),
                        Text("No Profile!"),
                      ],
                    ),
                  ),
                ]
                else ...[
                  ProfileContentCard(provider.profile!),

                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
