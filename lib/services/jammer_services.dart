import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:jam_app/models/JammerProfileModel.dart';
import 'package:jam_app/models/JammerSettingsModel.dart';

import '../models/JammerStateModel.dart';



const String JAMMER_API_PROT = "http";

class JammerService {
  String _host_url;

  void set host_url(String url){
    _host_url = url;
  }
  String get host_url => _host_url;

  JammerService(this._host_url);


  // STATE GROUP
  static const String state_path="state";

  Future<JammerStateModel> get_state() async {
    final response = await http
        .get(Uri.parse("$JAMMER_API_PROT://$_host_url/$state_path"));

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      final json_data= jsonDecode(response.body) as Map<String, dynamic>;
      return JammerStateModel.fromJSON(json_data);
    } else {
      throw Exception('Failed to load state');
    }
  }

  Future<JammerProfileModel?> get_profile() async {

      final response = await http
          .get(Uri.parse("$JAMMER_API_PROT://$_host_url/$state_path/profile"));

      if (response.statusCode == 200) {
        if (response.body.isEmpty){
          // no profile > null
          return null;
        }
        return JammerProfileModel.fromJSON(jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        throw HttpException('${response.statusCode}');
      }



  }

  Future<bool> post_profile(String profile_path) async {
    final data = await File(profile_path).readAsString();
    Map<String,String> headers = {
      'content-type' : 'application/json',
    };

    final bodey = jsonEncode(jsonDecode(data));

    final response = await http
        .post(
        Uri.parse("$JAMMER_API_PROT://$_host_url/$state_path/profile"),
        body:bodey,
      headers: headers,
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw HttpException('${response.statusCode}');
    }
  }

  Future<bool> post_settings(JammerSettingsModel settings) async {
    Map<String,String> headers = {
      'content-type' : 'application/json',
    };

    //final bodey = jsonEncode(jsonDecode(data));

    final response = await http
        .post(
      Uri.parse("$JAMMER_API_PROT://$_host_url/$state_path/settings"),
      body:jsonEncode(settings.toJson()),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw HttpException('${response.statusCode}');
    }
  }


  Future<void> reset() async {
    final response = await http
        .get(Uri.parse("$JAMMER_API_PROT://$_host_url/$state_path/reset"));

    if (response.statusCode == 200) {
      return;
    } else {
      throw HttpException('${response.statusCode}:${response.body}');
    }
  }

  Future<void> set_transmission_on(bool powerOn) async {
    final response = await http
        .post(Uri.parse("$JAMMER_API_PROT://$_host_url/$state_path/transmission/$powerOn"));

    if (response.statusCode == 200) {
      return;
    } else {
      throw HttpException('${response.statusCode}:${response.body}');
    }
  }

  // WAVEFORM GROUP
  Future<List<String>> get_waveform_list() async {

      final response = await http
          .get(Uri.parse("$JAMMER_API_PROT://$_host_url/waveform/list"));

      if(response.statusCode==200){
        final data = List<String>.from(jsonDecode(response.body));
        return data;
      }
      else {
        throw HttpException('${response.statusCode}');
      }
  }

  Future<bool> get_waveform(String name, String path_out) async {
    final response = await http
        .get(Uri.parse("$JAMMER_API_PROT://$_host_url/waveform/file/$name"));

    if(response.statusCode==200){
      File(path_out).writeAsBytes(response.bodyBytes);
      return true;
    }
    else if(response.statusCode==404){
      return false;
    }
    else {
      throw HttpException('${response.statusCode}');
    }
  }

  Future<bool> post_waveform(String path) async {
    final request = http.MultipartRequest("POST", Uri.parse("$JAMMER_API_PROT://$_host_url/waveform/file"));
    request.files.add(await http.MultipartFile.fromPath("file", path, filename:path.split(Platform.pathSeparator).last));

    final response = await request.send();
    //final response = await http.post(Uri.parse("$JAMMER_API_PROT://$_host_url/waveform/file"), body: waveform.readAsBytesSync());
    if(response.statusCode==200){
      return true;
    }
    throw HttpException('${response.statusCode}');
  }

  Future<bool> delete_waveform(String name) async {
    final response = await http.delete(Uri.parse("$JAMMER_API_PROT://$_host_url/waveform/file/$name"));
    if(response.statusCode==200){
      return true;
    }
    else if(response.statusCode==403){
      return false;
    }
    else if(response.statusCode==404){
      return true;
    }
    throw HttpException('${response.statusCode}');
  }
}