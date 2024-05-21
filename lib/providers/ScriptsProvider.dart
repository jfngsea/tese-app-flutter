import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:jam_app/models/JammerScripScheduleJobModel.dart';

import '../services/jammer_services.dart';

import 'package:http/http.dart' as http;

class ScriptsProvider extends ChangeNotifier{
  final JammerService _service;
  JammerService get service => _service;


  Directory _local_storage;
  final String scripts_folder;
  late Directory _scripts_dir;

  Directory get scripts_dir => _scripts_dir;
  List<String> _entries = [];
  List<String> get entries => _entries;

  bool isLoading =false;


  ScriptsProvider(this._service, this._local_storage,  {this.scripts_folder="scripts"}){
    _scripts_dir = Directory("${_local_storage.path}/$scripts_folder/");
    if(!_scripts_dir.existsSync()){
      _scripts_dir.createSync();
    }
    force_local_update();
  }

  void force_local_update(){
    isLoading=true;
    notifyListeners();

    _entries.clear();

    _entries = _scripts_dir
        .listSync()
        .where((element) => FileSystemEntity.isFileSync(element.path))
        .map((e) =>
    e.path
        .split(Platform.pathSeparator)
        .last)
        .toList();

    isLoading=false;
    notifyListeners();
  }


  Future<bool> pick_from_device_storage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);
      final File newFile = await file.copy('${_scripts_dir.path}/${result.names[0]}');
      force_local_update();
      return true;
    }
    else {
      return false;
    }
  }

  Future<bool> delete_local_profile(String name) async {
    File f = File('${_scripts_dir.path}/$name');
    if(await f.exists()){
      await f.delete();
    }
    force_local_update();
    return true;
  }

  Future<String> get_script_description(String filename) async {
    File f = File('${_scripts_dir.path}/$filename');

    final lines = await f.readAsLines();
    final it = lines.iterator;

    List<String> commnets =[];
    while(it.moveNext()){
      final line = it.current;
      if(line.contains("\"\"\"")){
        final nl = line.replaceAll("\"\"\"", "");
        if (nl.isNotEmpty){
          commnets.add(nl);

        }

        while(it.moveNext()){
          final line = it.current;
          if(line.contains("\"\"\"")){
            final nl = line.replaceAll("\"\"\"", "");
            if (nl.isNotEmpty){
              commnets.add(nl);
            }
            break;

          } else {
            commnets.add(line);
          }
        }
        break;
      }
    }

    return commnets.reduce((value, element) => "$value\n$element");
  }

  Future<void> run_script(String filename, Function(String new_state) on_new_state, {bool restore_profile=false}) async  {
    final request = http.MultipartRequest("POST", Uri.parse("http://${service.host_url}/scripting/run"));
    request.fields.putIfAbsent("restore_profile", () => restore_profile.toString());
    request.files.add(await http.MultipartFile.fromPath("script", '${scripts_dir.path}/$filename', filename:filename));

    on_new_state("Running Script...");
    final sresponse = await request.send();


    var result = await http.Response.fromStream(sresponse);
    on_new_state("Script Done!");


    final o = jsonDecode(result.body);
    on_new_state("Script Output:\n-------------");
    on_new_state(o["stdout"]);
    
  }

  Future<bool> schedule_script_in_jammer(String filename, DateTime schedule_utc) async {
    if(schedule_utc.isBefore(DateTime.now().toUtc())){
      return false;
    }

    try{
      final request = http.MultipartRequest("POST", Uri.parse("http://${service.host_url}/scripting/schedule/${schedule_utc.toString()}"));
      request.files.add(await http.MultipartFile.fromPath("script", '${scripts_dir.path}/$filename', filename:filename));

      final response = await http.Response.fromStream(await request.send());

      if(response.statusCode == 200){
        return true;
      }

      return false;

    } on HttpException catch (e){
      return false;
    }
  }

  Future<List<JammerScriptScheduleJob>> get_all_schedules() async {
    final response = await http
        .get(Uri.parse("$JAMMER_API_PROT://${service.host_url}/scripting/schedule/list"));

    if(response.statusCode==200){
      final json_data = jsonDecode(response.body) as List;
      return json_data.map((e) => JammerScriptScheduleJob.fromJSON(e)).toList();
    }
    else {
      return [];
    }
  }

  Future<bool> delete_script_schedule(String job_id) async {


    final response = await http
        .delete(Uri.parse("$JAMMER_API_PROT://${service.host_url}/scripting/schedule/$job_id"));
    notifyListeners();
    if(response.statusCode==200){
      return true;
    }
    else {
      return false;
    }

  }
}