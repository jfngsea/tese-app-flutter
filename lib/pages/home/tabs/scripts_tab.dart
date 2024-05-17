import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:jam_app/components/JammerCurrentStateConsumer.dart';
import 'package:jam_app/pages/scripts/ScriptDetailPage.dart';
import 'package:jam_app/pages/scripts/ScriptScheduleListPage.dart';
import 'package:jam_app/providers/ScriptsProvider.dart';
import 'package:provider/provider.dart';

import '../../../components/NoListItemsCard.dart';


import 'package:http/http.dart' as http;


class ScriptsTab extends StatefulWidget {
  const ScriptsTab({super.key});

  @override
  State<ScriptsTab> createState() => _ScriptsTabState();
}

class _ScriptsTabState extends State<ScriptsTab> {
  @override
  Widget build(BuildContext context) {

    ScriptsProvider provider = Provider.of<ScriptsProvider>(context, listen: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scripts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: provider.pick_from_device_storage,
          ),
          const IconButton(
            icon: Icon(Icons.download),
            onPressed: null,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: provider.force_local_update,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) =>
                      ScriptSchduleListpage()
              ));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          JammerCurrentStateConsumer(showLastUpdated: false,),
          if (provider.entries.isEmpty) ...[
            const Expanded(child: NoListItemsCard("Scripts")),
          ] else ...[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView.builder(
                  itemCount: provider.entries.length,
                  itemBuilder: (context, index) => Card(
                    child: ListTile(
                      title: Text(provider.entries[index]),
                      onTap: () {

                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) =>
                                ScriptDetailPage(provider.entries[index])));
                      },
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => delete_on_click(context, provider.entries[index]),
                          ),

                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          ]
        ],
      ),
    );
  }
}

void delete_on_click(BuildContext context, String name) async {
  final res = await Provider.of<ScriptsProvider>(context, listen: false).delete_local_profile(name);
  if (res) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Deleted ${name}!")));
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting ${name}!")));
  }
}
