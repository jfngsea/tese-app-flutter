import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:jam_app/models/JammerProfileModel.dart';
import 'package:jam_app/providers/WaveformsProviderV2.dart';

import '../models/WaveformEntry.dart';
import '../services/jammer_services.dart';
import 'JammerStateProvider.dart';

class ProfileProvider extends ChangeNotifier {
  final JammerService _service;
  WaveformsProviderV2 wf_provider;

  Directory _local_storage;
  String _profile_folder;
  late Directory _profile_dir;

  List<String> _local_profiles = [];
  List<String> get local_profiles => _local_profiles;

  ProfileProvider(this._service, this.wf_provider, this._local_storage,  {String profile_folder="profiles"}) : _profile_folder = profile_folder{
    _profile_dir = Directory("${_local_storage.path}/$_profile_folder/");
    if(!_profile_dir.existsSync()){
      _profile_dir.createSync();
    }
    force_local_update();
  }


  void force_local_update(){
    _update_local_profiles_list();
    notifyListeners();
  }

  Future<JammerProfileModel> get_model_from_file(String name) async {
    File f = File('${_profile_dir.path}/$name');
    final f_contents = await f.readAsString();
    final json = jsonDecode(f_contents);
    return JammerProfileModel.fromJSON(json);
  }

  Future<bool> pick_from_device_storage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);
      final File newFile = await file.copy('${_profile_dir.path}/${result.names[0]}');
      force_local_update();
      return true;
    }
    else {
      return false;
    }
  }

  Future<bool> delete_local_profile(String name) async {
    File f = File('${_profile_dir.path}/$name');
    if(await f.exists()){
      await f.delete();
    }
    force_local_update();
    return true;
  }

  //todo
  Future<bool> apply_profile_in_jammer(String profile_name) async {
    // check if profile's waveform is already preent on the jammer
    // if not upload it

    final model = await get_model_from_file(profile_name);
    final wf_entr = wf_provider.get_enty_by_name(model.waveform_name);

    if(wf_entr==null){
      print("@ProfileProvider#apply_profile_in_jammer wf_entry is null");
      return false;
    }

    if(wf_entr.isJammer!=true){
      if(wf_entr.isLocal==true){
        final res = await wf_provider.put_waveform_in_jammer(wf_entr);
        if(res!=true){
          print("@ProfileProvider#apply_profile_in_jammer error while posting waveform");
          return false;
        }
      }
      else {
        print("@ProfileProvider#apply_profile_in_jammer wf_entry is neither in jammer nor device");
        return false;
      }
    }

    // apply profile
    //_service.post_profile('${_profile_dir.path}/$profile_name');

    try{
      final res = await _service.post_profile('${_profile_dir.path}/$profile_name');
      return res;
    } on HttpException catch (e){
      return false;
    }
  }



  bool _update_local_profiles_list() {
    _local_profiles.clear();

    _local_profiles = _profile_dir
        .listSync()
        .where((element) => FileSystemEntity.isFileSync(element.path))
        .map((e) =>
    e.path
        .split(Platform.pathSeparator)
        .last)
        .toList();

    return true;
  }
}