import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jam_app/components/JammerCurrentStateConsumer.dart';
import 'package:jam_app/components/LoadingWidget.dart';
import 'package:jam_app/components/NoListItemsCard.dart';
import 'package:jam_app/providers/ScriptsProvider.dart';
import 'package:provider/provider.dart';

class ScriptSchduleListpage extends StatelessWidget {
  const ScriptSchduleListpage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ScriptsProvider>(context, listen:true);
    return Scaffold(
      appBar: AppBar(
        title: Text("Scheduled Scripts"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FutureBuilder(
          future: provider.get_all_schedules(),
          builder: (context, snapshot) {
            if(snapshot.hasData){
              if(snapshot.data!.isEmpty){
                return const NoListItemsCard("Schedules");
              }

              return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final job = snapshot.data![index];
                    return Card(
                      child: ListTile(
                        title: Text(job.jobname),
                        subtitle: Text("Runs At: ${
                            DateFormat("yyyy-MM-dd HH:mm").format(job.jobdate)
                        } (UTC)"),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () async {
                            final result = await provider.delete_script_schedule(job.jobid);
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(
                                  result?"Deleted schedule!":"Not Deleted"
                                )));
                          },
                        ),
                      ),
                    );
                  },
              );
            }
            return LoadingWidget();
          },
        ),
      ),
    );
  }
}
