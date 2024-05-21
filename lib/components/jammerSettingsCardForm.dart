import 'package:flutter/material.dart';
import 'package:jam_app/models/JammerSettingsModel.dart';
import 'package:jam_app/providers/JammerStateProvider.dart';
import 'package:provider/provider.dart';

class JammerSettingsCardForm extends StatefulWidget {
  final JammerSettingsModel settings;

  const JammerSettingsCardForm(this.settings, {super.key});

  @override
  State<JammerSettingsCardForm> createState() => _JammerSettingsCardFormState();
}

class _JammerSettingsCardFormState extends State<JammerSettingsCardForm> {
  final _formKey = GlobalKey<FormState>();
  bool _has_been_edited = false;

  late JammerSettingsModel _editable_settings;
  @override
  void initState() {
    super.initState();
    _editable_settings = JammerSettingsModel.from(widget.settings);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<JammerStateProvider>(context, listen: true);
    return Card(
      child:Form(
        key: _formKey ,
        child: Column(
          children: [
            ListTile(
              title: Text("Current Settings", style: Theme.of(context).textTheme.headlineSmall,),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [if (_has_been_edited) ...[
                    TextButton(
                      child: Text("Reset"),
                      onPressed: (){
                        setState(() {
                          _editable_settings = JammerSettingsModel.from(widget.settings);
                          _formKey.currentState!.reset();
                          _has_been_edited=false;
                        });
                      },
                    ),
                  TextButton(
                    child: Text("Send"),
                    onPressed: () async {
                      if (_formKey.currentState!.validate())  {
                        _formKey.currentState!.save();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Updating Settings...')),
                        );
                        final result = await provider.apply_new_settings(_editable_settings);
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result? "Done!":"Error while updating")),
                        );
                        if(result){
                          setState(() {
                            _has_been_edited = false;
                          });
                        }
                      }
                    },
                  ),
                  ]
                ],
              ),
            ),
            const Divider(),

            if(_editable_settings.mixer_freq !=null) ...[
              ListTile(
                leading: Text("Frequency:", style: Theme.of(context).textTheme.bodyLarge,),
                trailing: Text("MHz", style: Theme.of(context).textTheme.bodyLarge,),
                title: TextFormField(
                  initialValue: _editable_settings.mixer_freq.toString(),
                  validator: (String? value) {
                    return (value != null && double.tryParse(value) == null) ? 'Invalid Value' : null;
                  },
                  onSaved: (newValue) => setState(() {
                    _editable_settings.mixer_freq=double.tryParse(newValue!)?? widget.settings.mixer_freq!;
                  }),
                  onChanged: (value) => setState(() {
                    _has_been_edited=true;
                  }),
                ),
              ),
            ],


            if(widget.settings.mixer_phase !=null) ...[
              ListTile(
                title: Text("Phase: ${widget.settings.mixer_phase!}"),
              ),
            ],


            if(widget.settings.decimation_factor !=null) ...[
              ListTile(
                title: Text("Decimation: ${widget.settings.decimation_factor!}"),
              ),
            ],
            if(widget.settings.interpolation_factor !=null) ...[
              ListTile(
                title: Text("Interpolation: ${widget.settings.interpolation_factor!}"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
