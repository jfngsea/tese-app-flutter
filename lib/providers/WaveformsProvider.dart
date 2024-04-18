
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'package:jam_app/models/WaveformEntry.dart';
import 'package:jam_app/services/jammer_services.dart';
import 'package:path_provider/path_provider.dart';

enum WaveformFilter {jammer, local}

class WaveformsProvider extends ChangeNotifier {

  final JammerService _service;

  List<WaveformEntry> _all_entries = List.empty();
  List<WaveformEntry> _filtered_entries = List.empty();
  List<WaveformEntry> get entries => _filtered_entries;
  bool get hasEntries => _all_entries.isNotEmpty;
  bool offline_results=false;

  String err_msg ="";

  Set<WaveformFilter> filters={};

  bool isLoading =false;
  DateTime? lastUpdate;

  WaveformsProvider(this._service);

  Future<bool> get_waveform_list() async {
    isLoading =true;
    err_msg="";
    notifyListeners();

    // get waveforms from jammer
    List<String> jammer_wavforms =List.empty();
    try{
      jammer_wavforms= await _service.get_waveform_list();
      offline_results=false;
    } on Exception{
      offline_results=true;
    }


    Map<String, WaveformEntry> entries = { for (var element in jammer_wavforms.map((e) => WaveformEntry(e, "tbd", false, true))) element.name : element };

    // get local waveforms
    final local_doc_dir = (await getExternalStorageDirectory())!;
    print(local_doc_dir.path);
    final local_waveform_dir =  Directory("${local_doc_dir.path}/waveforms");


    if (local_waveform_dir.existsSync()){
      final file_names = local_waveform_dir
          .listSync()
          .where((element) => FileSystemEntity.isFileSync(element.path))
          .map((e) => e.path.split(Platform.pathSeparator).last)
          .toList();

      file_names.forEach((element) {
        if(entries.containsKey(element)){
          entries[element]?.inLocal= true;
        }
        else{
          entries.putIfAbsent(element, () => WaveformEntry(element, "tbd", true, false));
        }

      });
    }
    else {
      local_waveform_dir.createSync(recursive: true);
    }

    // compare


    _all_entries = entries.values.toList();
    _apply_filters();

    isLoading=false;
    lastUpdate = DateTime.now();
    notifyListeners();
    return true;
  }

  void _apply_filters(){
    _filtered_entries = _all_entries
        .where((element) {
          bool c1 = !filters.contains(WaveformFilter.jammer) || element.inJammer;
          bool c2 = !filters.contains(WaveformFilter.local) || element.inLocal;
          return c1 && c2;
    })
        .toList();
  }

  bool set_filter(WaveformFilter filter) {
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

  Future<bool> pick_file_from_device_storage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);
      final String path = (await getExternalStorageDirectory())!.path;
      final File newFile = await file.copy('$path/waveforms/${result.names[0]}');
      get_waveform_list();
      return true;
    } else {
      return false;
    }
  }

  Future<bool> get_waveform_from_jammer(WaveformEntry wf) async {
    try{
      final success = await _service.get_waveform(wf.name, "${(await getExternalStorageDirectory())!.path}/waveforms/${wf.name}");
      if(success){
        wf.inLocal=true;
      }
    } on Exception catch (e){
      rethrow;
    }
    notifyListeners();
    return true;
  }

  Future<File?> get_waveform_file(WaveformEntry wf) async {
    if(wf.inLocal != true){
      return null;
    }
    File file = File("${await _get_local_waveform_dir_path()}/${wf.name}");
    if(!file.existsSync()){
        return null;
    }
    return file;
  }

  Future<bool> delete_local_waveform(WaveformEntry wf) async{
    if(wf.inLocal == false){
      return true;
    }
    File local = await _get_local_waveform_file(wf.name);
    local.deleteSync();
    wf.inLocal=false;
    notifyListeners();
    return true;
  }

  Future<bool> put_waveform_in_jammer(WaveformEntry wf) async {
    try{
      final result = await _service.post_waveform(await _get_local_waveform_path(wf.name));
      notifyListeners();
      return result;
    } on Exception catch (e){
      print("@WaveformsProvider#delete_jammer_waveform exception: ${e.toString()}");
      return false;
    }
  }

  Future<bool> delete_jammer_waveform(WaveformEntry wf) async {
    try{
      final success = await _service.delete_waveform(wf.name);
      notifyListeners();
      return success;
    } on Exception catch (e){
      print("@WaveformsProvider#delete_jammer_waveform exception: ${e.toString()}");
      return false;
    }
  }

  Future<Directory> _get_local_waveform_dir() async {
    return Directory("${(await getExternalStorageDirectory())!.path}/waveforms/");
  }

  Future<String> _get_local_waveform_dir_path() async {
    return (await _get_local_waveform_dir()).path;
  }

  Future<String> _get_local_waveform_path(String name) async {
    return "${(await _get_local_waveform_dir()).path}/${name}";
  }
  
  Future<File> _get_local_waveform_file(String name) async {
    return File(await _get_local_waveform_path(name));
  }
}