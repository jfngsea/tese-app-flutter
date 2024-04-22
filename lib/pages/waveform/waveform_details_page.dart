import 'package:flutter/material.dart';
import 'package:jam_app/components/waveform_graph.dart';
import 'package:provider/provider.dart';

import '../../components/LoadingWidget.dart';
import '../../components/NoListItemsCard.dart';
import '../../models/WaveformEntry.dart';
import '../../providers/WaveformsProviderV2.dart';

class WaveformDetailPage extends StatefulWidget {
  final WaveformEntry entry;

  const WaveformDetailPage(this.entry, {super.key});

  @override
  State<WaveformDetailPage> createState() => _WaveformDetailPageState();
}

class _WaveformDetailPageState extends State<WaveformDetailPage> {
  bool isLoading = false;
  String isLoadingMsg = "";
  String errorMsg = "";

  @override
  Widget build(BuildContext context) {
    WaveformsProviderV2 provider =
    Provider.of<WaveformsProviderV2>(context, listen: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Waveform Detail'),
        actions: [
          if (widget.entry.isLocal != true) ...[
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {},
            ),
          ],
          if (widget.entry.isJammer != true) ...[
            IconButton(
              icon: const Icon(Icons.upload),
              onPressed: () {},
            ),
          ]
        ],
      ),
      body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Builder(
            builder: (context) {
              if (isLoading) {
                return Column(
                  children: [
                    const LoadingWidget(),
                    Text(isLoadingMsg),
                  ],
                );
              }

              if (errorMsg.isNotEmpty) {
                return Text("Error: $errorMsg");
              }

              return ListView(
                shrinkWrap: true,
                children: [
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          title: Text("Name: ${widget.entry.name}"),
                        ),
                        const Divider(),


                        const Text("Available on:"),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (widget.entry.isLocal==true) ...[
                              FilterChip(
                                label: const Row(
                                  children: [
                                    Icon(Icons.smartphone),
                                    Text("Local")
                                  ],
                                ),
                                onSelected: (_) {},)
                            ],
                            if (widget.entry.isJammer==true) ...[
                              FilterChip(
                                label: const Row(
                                  children: [
                                    Icon(Icons.settings_input_antenna),
                                    Text("Jammer")
                                  ],
                                ),
                                onSelected: (_) {},)
                            ]
                          ],
                        ),


                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (widget.entry.isLocal != true) ...[
                              FilledButton.tonal(
                                  onPressed: () async {
                                    setState(() {
                                      isLoading = true;
                                      isLoadingMsg = "Downloading";
                                    });
                                    try {
                                      final success =
                                      await Provider.of<WaveformsProviderV2>(context, listen: false)
                                          .get_waveform_from_jammer(widget.entry);
                                      setState(() {
                                        errorMsg = success ? "" : "Download failed";
                                        isLoading = false;
                                        isLoadingMsg = "";
                                      });
                                    } on Exception catch (e) {
                                      errorMsg = e.toString();
                                      isLoading = false;
                                      isLoadingMsg = "";
                                    }
                                  },
                                  child: Text("Download")
                              ),
                            ] else ...[
                              FilledButton.tonal(
                                  onPressed: () => provider.delete_local_waveform(widget.entry),
                                  child: Text("Delete Local")
                              ),
                            ],

                            if (widget.entry.isJammer == false) ...[
                              FilledButton.tonal(
                                  onPressed: () async {
                                    setState(() {
                                      isLoading = true;
                                      isLoadingMsg = "Uploading...";
                                    });
                                    try {
                                      final success =
                                      await Provider.of<WaveformsProviderV2>(context, listen: false)
                                          .put_waveform_in_jammer(widget.entry);
                                      setState(() {
                                        errorMsg = success ? "" : "Upload failed";
                                        isLoading = false;
                                        isLoadingMsg = "";
                                      });
                                    } on Exception catch (e) {
                                      errorMsg = e.toString();
                                      isLoading = false;
                                      isLoadingMsg = "";
                                    }
                                  },
                                  child: Text("Upload Jammer")
                              ),
                            ] else if(widget.entry.isJammer == true) ...[
                              FilledButton.tonal(
                                  onPressed: () => provider.delete_jammer_waveform(widget.entry),
                                  child: Text("Delete Jammer")
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  if(widget.entry.isLocal==true) ...[
                    Card(
                      child: Column(
                        children: [
                          Text("graph"),
                          Divider(),
                          WaveformGraph(widget.entry),
                        ],
                      ),
                    )
                  ]
                ],
              );

            },
          )),
    );
  }

  void on_local_dowload_press(BuildContext ctx) async {
    setState(() {
      isLoading = true;
      isLoadingMsg = "Downloading";
    });
    try {
      final success =
      await Provider.of<WaveformsProviderV2>(context, listen: false)
          .get_waveform_from_jammer(widget.entry);
      setState(() {
        errorMsg = success ? "" : "Download failed";
        isLoading = false;
        isLoadingMsg = "";
      });
    } on Exception catch (e) {
      errorMsg = e.toString();
      isLoading = false;
      isLoadingMsg = "";
    }
  }
}

class WaveformDetailPageName extends StatelessWidget {
  final String waveform_name;
  const WaveformDetailPageName(this.waveform_name, {super.key});

  @override
  Widget build(BuildContext context) {
    WaveformEntry? entry = Provider.of<WaveformsProviderV2>(context).get_enty_by_name(waveform_name);

    if(entry==null){
      Future.microtask(() => Navigator.pop(context, false));


      return Center(
        child: NoListItemsCard(),
      );

    }
    return WaveformDetailPage(entry);
  }
}