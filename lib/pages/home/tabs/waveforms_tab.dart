import 'package:flutter/material.dart';

import 'package:jam_app/providers/WaveformsProviderV2.dart';
import 'package:provider/provider.dart';

import '../../../components/JammerCurrentStateConsumer.dart';
import '../../../components/LoadingWidget.dart';
import '../../../components/NoListItemsCard.dart';
import '../../../components/WaveformEntryCard.dart';
import '../../waveform/waveform_details_page.dart';

class WaveformsTab extends StatefulWidget {
  const WaveformsTab({super.key});

  @override
  State<WaveformsTab> createState() => _WaveformsTabState();
}

class _WaveformsTabState extends State<WaveformsTab> {
  final location_icons = Map.fromEntries(WaveformFilter.values.map((e) {
    if(e==WaveformFilter.local)
      return MapEntry(e, Icon(Icons.smartphone));
    if(e==WaveformFilter.jammer)
      return MapEntry(e, Icon(Icons.settings_input_antenna));
    return MapEntry(e, Icon(Icons.question_mark));
  }));

  @override
  Widget build(BuildContext context) {
    WaveformsProviderV2 provider =
        Provider.of<WaveformsProviderV2>(context, listen: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Waveforms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: provider.pick_waveform_from_device_storage,
          ),
          const IconButton(
            icon: Icon(Icons.download),
            onPressed: null,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: provider.update_local_force,
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (provider.isLoading) {
            return const LoadingWidget();
          }

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                const JammerCurrentStateConsumer(),

                if (!provider.hasEntries) ...[
                  const Expanded(child: NoListItemsCard()),
                ] else ...[
                  // Filters Row
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Text("Location Filter:", style: Theme.of(context).textTheme.bodyLarge,),
                      Expanded(
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: WaveformFilter.values
                                .map((e) => FilterChip(
                              label: Row(
                                children: [
                                  location_icons[e]!,
                                  Text(e.name)
                                ],
                              ),
                              selected: provider.filters.contains(e),
                              onSelected: (isSelected) {
                                if (isSelected) {
                                  provider.add_filter(e);
                                } else {
                                  provider.delete_filter(e);
                                }
                              },

                            ))
                                .toList()),
                      )
                    ],
                  )

                ],
                Expanded(
                  child: ListView.builder(
                    itemBuilder: (context, index) => WaveformEntryListTile(
                      provider.entries.elementAt(index),
                      (entry) {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => WaveformDetailPage(entry)));
                      },
                    ),
                    itemCount: provider.entries.length,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}



