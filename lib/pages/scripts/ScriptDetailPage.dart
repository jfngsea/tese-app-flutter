import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:jam_app/components/LoadingWidget.dart';
import 'package:jam_app/providers/ScriptsProvider.dart';
import 'package:provider/provider.dart';

class ScriptDetailPage extends StatefulWidget {
  final String filename;
  const ScriptDetailPage(this. filename, {super.key});

  @override
  State<ScriptDetailPage> createState() => _ScriptDetailPageState();
}

class _ScriptDetailPageState extends State<ScriptDetailPage> {
  DateTime datetime_utc = DateTime.now().toUtc();
  final format = DateFormat("yyyy-MM-dd HH:mm");

  bool running_script =false;
  String states = "";
  List<String> statesl= [];

  final TextEditingController states_controller = TextEditingController();


  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ScriptsProvider>(context, listen:false);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Script Detail'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            // titile: details
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: Text("Name: ${widget.filename}"),
                  ),
                  FutureBuilder<String>(
                      future: provider.get_script_description(widget.filename),
                      builder: (context, snapshot) {
                        Widget content = LoadingWidget();
                        if(snapshot.hasData){
                          if(snapshot.data!.isNotEmpty){
                            content = ListTile(title: Text(snapshot.data!, style: Theme.of(context).textTheme.bodyMedium,));
                          } else {
                            content = Text("- Empty Description -");
                          }
                        }
                        return Column(
                          children: [
                            ListTile(
                              title: Text("Description:",),
                            ),
                            content,
                          ],
                        );
                      },
                  ),
                ],
              ),
            ),

            // title: Text("Schedule Execution"),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: Text("Schedule Execution"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          child: Text("Now"),
                          onPressed: () => setState(() {
                            datetime_utc = DateTime.now().toUtc();
                          }),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: () async {
                            final result = await provider.schedule_script_in_jammer(widget.filename, datetime_utc) ;
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(
                                    result?"Script Scheduled!":"Script not scheduled"
                                )));
                          },
                        ),
                      ],
                    ),
                  ),
                  Divider(),

                  ListTile(
                    leading: Text('  UTC:', style: Theme.of(context).textTheme.bodyLarge,),
                    title: Text(
                        format.format(datetime_utc)
                    ),
                    onTap: () async {
                      final new_datetime =  await showDatePicker(
                        context: context,
                        firstDate: DateTime(1900),
                        initialDate: datetime_utc,
                        lastDate: DateTime(2100),
                      ).then((DateTime? date) async {
                        if (date != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime:
                            TimeOfDay.fromDateTime(datetime_utc),
                          );
                          return combineUTC(date, time);
                        } else {
                          return datetime_utc;
                        }
                      });
                      setState(() {
                        datetime_utc = new_datetime;
                      });
                    },
                  ),
                  ListTile(
                    leading: Text('Local:', style: Theme.of(context).textTheme.bodyLarge,),
                    title: Text(
                        format.format(datetime_utc.toLocal())
                    ),
                    onTap: () async {
                      final new_datetime =  await showDatePicker(
                        context: context,
                        firstDate: DateTime(1900),
                        initialDate: datetime_utc.toLocal(),
                        lastDate: DateTime(2100),
                      ).then((DateTime? date) async {
                        if (date != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime:
                            TimeOfDay.fromDateTime(datetime_utc.toLocal()),
                          );
                          return combine(date, time);
                        } else {
                          return datetime_utc.toLocal();
                        }
                      });
                      setState(() {
                        datetime_utc = new_datetime.toUtc();
                      });
                    },
                  ),

                ],
              ),
            ),

            //title: Text("Execution"),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: Text("Execution"),
                    trailing: TextButton(
                      child: Text("Run"),
                      onPressed: running_script? null : () async {
                        setState(() {
                          running_script = true;
                          states = "";
                          statesl.clear();
                          states_controller.text =states;
                        });
                        await provider.run_script(widget.filename, (new_state) {
                          setState(() {
                            states = "$states${new_state}\n";
                            statesl.add(new_state);
                          });
                          states_controller.text =states;
                        },);
                        setState(() {
                          running_script = false;
                        });
                      },
                    ),
                  ),
                  //Divider(),
                  if(states.isNotEmpty) ...[
                    Divider(),

                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: statesl.map((e) =>  Row(
                          children: [Flexible(child: Text(e))],
                        )).toList(),
                      ),
                    ),
                  ]

                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

DateTime combine(DateTime date, TimeOfDay? time) => DateTime(
  date.year, date.month, date.day, time?.hour ?? 0, time?.minute ?? 0, );

DateTime combineUTC(DateTime date, TimeOfDay? time) => DateTime.utc(
  date.year, date.month, date.day, time?.hour ?? 0, time?.minute ?? 0, );