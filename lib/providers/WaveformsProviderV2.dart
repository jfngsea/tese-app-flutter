import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jam_app/providers/JammerStateProvider.dart';

import '../models/WaveformEntry.dart';
import '../services/jammer_services.dart';

enum WaveformFilter {local, jammer}
Map<WaveformFilter, String> filter_names ={
  WaveformFilter.local: "Local",
  WaveformFilter.jammer: "Jammer Hw",
};

final filter_icons = Map.fromEntries(WaveformFilter.values.map((e) {
  if(e==WaveformFilter.local)
    return MapEntry(e, Icon(Icons.smartphone));
  if(e==WaveformFilter.jammer)
    return MapEntry(e, Icon(Icons.settings_input_antenna));
  return MapEntry(e, Icon(Icons.question_mark));
}));


class WaveformsProviderV2 extends ChangeNotifier {
  final JammerService _service;

  Directory _local_storage;
  String wf_folder;
  late Directory _wf_dir;

  Map<String, WaveformEntry> _jammer_entries = {};
  Map<String, WaveformEntry> _local_entries = {};
  Map<String, WaveformEntry> _all_entries = {};


  Set<WaveformFilter> filters={};
  List<WaveformEntry> _filtered_entries = List.empty();

  bool get hasEntries => _local_entries.isNotEmpty || _jammer_entries.isNotEmpty;

  List<WaveformEntry> get entries => _filtered_entries;

  bool isLoading =false;

  WaveformsProviderV2(this._service, this._local_storage,  {String this.wf_folder="waveforms"}){
    _wf_dir = Directory("${_local_storage.path}/$wf_folder/");
    if(!_wf_dir.existsSync()){
      _wf_dir.createSync();
    }

    _update_local_entries();
  }


  void update_with_state_provider(JammerStateProvider jsp){
    if(jsp.connection_state==JammerConnectionState.fail){
      _jammer_entries = {};
    }
    // no actual update of waveform list
    else if(setEquals(jsp.waveforms.keys.toSet(), _jammer_entries.keys.toSet())){
        return;
    }
    else {
      _jammer_entries = jsp.waveforms;
    }
    _update_entries_state();

  }

  void update_local_force() {
    _update_local_entries();
    _update_entries_state();
  }

  WaveformsProviderV2 _update_entries_state(){
    _merge_entries();
    _apply_filters();
    notifyListeners();
    return this;
  }
  
  bool _update_local_entries() {
    _local_entries.clear();

    final local_files = _wf_dir
        .listSync()
        .where((element) => FileSystemEntity.isFileSync(element.path))
        .map((e) {
          final name = e.path.split(Platform.pathSeparator).last;
          return MapEntry<String, WaveformEntry>(name,
          WaveformEntry(
              name,
              name.split(".").last,
              true, false,
              isLocal: true,
              file_path: e.path,
          )
      );
    });

    _local_entries.addEntries(local_files);

    return true;
  }

  bool _merge_entries(){
    _all_entries.clear();
    _all_entries.addAll(_local_entries);
    _all_entries.forEach((key, value) {value.isJammer=false;});

    _jammer_entries.forEach((key, value) {
      if(_all_entries.containsKey(key)){
        _all_entries[key]!.isJammer=true;
      }
      else {
        _all_entries.putIfAbsent(key, () => value,);
        _all_entries[key]!.isLocal=false;
      }
    });
    return true;
  }

  
  
  bool add_filter(WaveformFilter filter) {
    filters.add(filter);
    _apply_filters();
    notifyListeners();
    return true;
  }
  bool delete_filter(WaveformFilter filter) {
    filters.remove(filter);
    _apply_filters();
    notifyListeners();
    return true;
  }

  void _apply_filters(){
    _filtered_entries = _all_entries.values
        .where((element) {
      bool c1 = !filters.contains(WaveformFilter.jammer) || (element.isJammer ?? false);
      bool c2 = !filters.contains(WaveformFilter.local) || (element.isLocal ?? false);
      return c1 && c2;
    })
        .toList();
  }


  Future<bool> pick_waveform_from_device_storage() async{
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);
      final File newFile = await file.copy('${_wf_dir.path}/${result.names[0]}');
      update_local_force();
      return true;
    }
    else {
      return false;
    }
  }


  Future<bool> get_waveform_from_jammer(WaveformEntry wf) async {
    try{
      final success = await _service.get_waveform(wf.name, "${_wf_dir.path}/${wf.name}");
      if(success){
        wf.isLocal=true;
        wf.file_path= ""; //todo
      }
      update_local_force();
      return true;
    } on Exception catch (e){
      rethrow;
    }
  }

  bool delete_local_waveform(WaveformEntry wf){
    if(wf.isLocal == false){
      return true;
    }
    File local =  File("${_wf_dir.path}/${wf.name}");
    local.deleteSync();
    wf.isLocal=false;
    update_local_force();
    return true;
  }

  Future<bool> put_waveform_in_jammer(WaveformEntry wf) async {
    try{
      final result = await _service.post_waveform("${_wf_dir.path}/${wf.name}");
      return result;
    } on Exception catch (e){
      print("@WaveformsProvider#delete_jammer_waveform exception: ${e.toString()}");
      return false;
    }
  }

  Future<bool> delete_jammer_waveform(WaveformEntry wf) async {
    try{
      final success = await _service.delete_waveform(wf.name);
      return success;
    } on Exception catch (e){
      print("@WaveformsProvider#delete_jammer_waveform exception: ${e.toString()}");
      return false;
    }
  }

  WaveformEntry? get_enty_by_name(String name){
    return _all_entries[name];
  }

}