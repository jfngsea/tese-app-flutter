import 'package:flutter/material.dart';
import 'package:jam_app/pages/waveform/graphs/WaveformDetailPDFGraph.dart';
import 'package:jam_app/pages/waveform/graphs/WaveformDetailTimeGraph.dart';
import 'package:provider/provider.dart';

import '../../components/LoadingWidget.dart';
import '../../components/NoListItemsCard.dart';

import '../../models/WaveformEntry.dart';
import '../../providers/GraphDataProvider.dart';
import '../../providers/WaveformsProviderV2.dart';
import 'graphs/WaveformDetailSpectrumGraph.dart';

class WaveformDetailPageV2 extends StatelessWidget {
  final WaveformEntry entry;

  const WaveformDetailPageV2(this.entry, {super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => GraphDataProvider(entry),
      child: const WaveformDetailPageContent(),
    );
  }
}

class WaveformDetailPageContent extends StatelessWidget {
  const WaveformDetailPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GraphDataProvider>(
      builder: (context, graphs, child) {

        final wf_provider = Provider.of<WaveformsProviderV2>(context, listen: true);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Waveform Detail'),
            actions: [
              if (graphs.entry.isLocal != true) ...[
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () {},
                ),
              ],
              if (graphs.entry.isJammer != true) ...[
                IconButton(
                  icon: const Icon(Icons.upload),
                  onPressed: () {},
                ),
              ]
            ],
          ),
          body: DefaultTabController(
            length: 3,
            child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Builder(
                  builder: (context) {
                    if (graphs.isLoading) {
                      return Column(
                        children: [
                          const LoadingWidget(),
                          Text(graphs.isLoadingMsg),
                        ],
                      );
                    }

                    if (graphs.errorMsg.isNotEmpty) {
                      return Text("Error: ${graphs.errorMsg}");
                    }

                    return ListView(
                      shrinkWrap: true,
                      children: [
                        Card(
                          child: Column(
                            children: [
                              ListTile(
                                title: Text("Name: ${graphs.entry.name}"),
                              ),
                              // AVailability row
                              ListTile(
                                title: Row(
                                  //mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Available On:"),
                                    if (graphs.entry.isLocal == true) ...[
                                      FilterChip(
                                        label: Row(
                                          children: [
                                            filter_icons[WaveformFilter.local]!,
                                            Text(
                                              filter_names[WaveformFilter.local]!,
                                            )
                                          ],
                                        ),
                                        onSelected: (_) {},
                                      )
                                    ],
                                    if (graphs.entry.isJammer == true) ...[
                                      FilterChip(
                                        label: Row(
                                          children: [
                                            filter_icons[WaveformFilter.jammer]!,
                                            Text(
                                              filter_names[WaveformFilter.jammer]!,
                                            )
                                          ],
                                        ),
                                        onSelected: (_) {},
                                      )
                                    ]
                                  ],
                                ),
                              ),
                              const Divider(),

                              // Action Buttons
                              ListTile(
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Actions: "),
                                    if (graphs.entry.isLocal != true) ...[
                                      FilledButton.tonal(
                                          onPressed: () => on_download_entry_press(graphs, wf_provider),
                                          child: const Text("Download")),
                                    ] else ...[
                                      FilledButton.tonal(
                                          onPressed: () => wf_provider
                                              .delete_local_waveform(graphs.entry),
                                          child: const Text("Delete Local")),
                                    ],
                                    if (graphs.entry.isJammer == false) ...[
                                      FilledButton.tonal(
                                          onPressed: () => on_upload_to_jammer_press(graphs, wf_provider),
                                          child: Text(
                                              "Upload to ${filter_names[WaveformFilter.jammer]}")),
                                    ] else if (graphs.entry.isJammer == true) ...[
                                      FilledButton.tonal(
                                          onPressed: () => wf_provider
                                              .delete_jammer_waveform(graphs.entry),
                                          child: Text(
                                              "Delete from ${filter_names[WaveformFilter.jammer]}")),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (graphs.entry.isLocal == true) ...[
                          Card(
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                const TabBar(
                                  tabs: [
                                    Tab(
                                      text: "Waveform",
                                    ),
                                    Tab(
                                      text: "Spectrum",
                                    ),
                                    Tab(
                                      text: "PDF",
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 600,
                                  child: TabBarView(
                                    children: [
                                      WaveformDetailTimeGraph(),
                                      WaveformDetailSpectrumGraph(),
                                      WaveformDetailPDFGraph(),
                                    ],
                                  ),
                                ),
                                const Divider(),
                                ListTile(
                                  title: Text("PAPR: ${graphs.papr?.toStringAsFixed(2) ?? "Calculating..."}"),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                )),
          ),
        );
      }
    );
  }

  void on_download_entry_press(GraphDataProvider graphsProvider, WaveformsProviderV2 wfProvider) async {
    graphsProvider.set_isLoading(true, message: "Downloading...");

    try {
      final success = await wfProvider.get_waveform_from_jammer(graphsProvider.entry);
      graphsProvider.set_errorMsg(success? "": "Download failed");

    } on Exception catch (e) {
      graphsProvider.set_errorMsg(e.toString());
    }
  }

  void on_upload_to_jammer_press(GraphDataProvider graphsProvider, WaveformsProviderV2 wfProvider) async {
    graphsProvider.set_isLoading(true, message: "Uploading...");
    try {
      final success = await wfProvider.put_waveform_in_jammer(graphsProvider.entry);
      graphsProvider.set_errorMsg(success? "": "Upload failed");

    } on Exception catch (e) {
      graphsProvider.set_errorMsg(e.toString());
    }
}
}



class WaveformDetailPageName extends StatelessWidget {
  final String waveform_name;

  const WaveformDetailPageName(this.waveform_name, {super.key});

  @override
  Widget build(BuildContext context) {
    WaveformEntry? entry = Provider.of<WaveformsProviderV2>(context)
        .get_enty_by_name(waveform_name);

    if (entry == null) {
      Future.microtask(() => Navigator.pop(context, false));

      return Center(
        child: NoListItemsCard("Waveform"),
      );
    }
    return WaveformDetailPageV2(entry);
  }
}




