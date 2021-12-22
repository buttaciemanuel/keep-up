import 'dart:convert';
import 'dart:io';
import 'dart:developer';
import 'package:xml/xml.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:intl/intl.dart';

class PolitoAPI {
  static const String registerDeviceEndpoint =
      "https://app.didattica.polito.it/register.php";
  static const String loginEndpoint =
      "https://app.didattica.polito.it/login.php";
  static const String logoutEndpoint =
      "https://app.didattica.polito.it/logout.php";
  static const String scheduleEndpoint =
      "https://app.didattica.polito.it/orari_lezioni.php";

  final PolitoUserSession _session = PolitoUserSession();

  static Future<Map<String, dynamic>> _getDeviceInfo() async {
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      final iosDeviceInfo = await deviceInfo.iosInfo;
      return {
        'regID': iosDeviceInfo.identifierForVendor,
        'uuid': iosDeviceInfo.identifierForVendor,
        'device_platform': 'iOS',
        'device_version': iosDeviceInfo.systemVersion,
        'device_model': iosDeviceInfo.model,
        'device_manufacturer': 'Apple'
      };
    } else {
      final androidDeviceInfo = await deviceInfo.androidInfo;
      return {
        'regID': androidDeviceInfo.androidId,
        'uuid': androidDeviceInfo.androidId,
        'device_platform': 'Android',
        'device_version': androidDeviceInfo.version.baseOS,
        'device_model': androidDeviceInfo.model,
        'device_manufacturer': androidDeviceInfo.manufacturer
      };
    }
  }

  static String _encodeParams(Map<String, dynamic> params) {
    String result = 'data={';
    var index = 0;
    params.forEach((key, value) {
      if (index > 0) result += ',';
      result += "\"$key\":\"$value\"";
      ++index;
    });
    result += '}';
    return result;
  }

  static Future<http.Response> _makeRequest(
      String endpoint, Map<String, dynamic> params) async {
    final response = await http.post(Uri.parse(endpoint),
        body: _encodeParams(params),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'});
    return response;
  }

  Future<PolitoUserSession> init() async {
    final deviceInfo = await _getDeviceInfo();
    final response = await _makeRequest(registerDeviceEndpoint, deviceInfo);

    print(deviceInfo);
    _session.registeredId = deviceInfo['regID'];

    print("[device-reg ${response.statusCode} ${response.reasonPhrase}]");
    print("${response.body}");

    return _session;
  }

  Future<void> loginUser(String username, String password) async {
    final response = await _makeRequest(loginEndpoint, {
      'regID': _session.registeredId,
      'username': username,
      'password': password
    });

    _session.token =
        jsonDecode(response.body)['data']['login']['token'] as String;

    print("[login ${response.statusCode} ${response.reasonPhrase}]");
    print("${response.body}");
  }

  Future<void> logoutUser() async {
    final response = await _makeRequest(logoutEndpoint,
        {'regID': _session.registeredId, 'token': _session.token});

    print("[logout ${response.statusCode} ${response.reasonPhrase}]");
    print("${response.body}");
  }

  Future<void> getSchedule() async {
    final now = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final response = await _makeRequest(scheduleEndpoint, {
      'regID': _session.registeredId,
      'token': _session.token,
      'data_rif': now
    });

    final xmlUrl = jsonDecode(response.body)['data']['url_orari']
        ['v_original_url'] as String;
    final xmlResponse = await http.post(Uri.parse(xmlUrl));

    print("[schedule ${response.statusCode} ${response.reasonPhrase}]");
    print("${response.body}");
    log(xmlResponse.body);
  }
}

class PolitoUserSession {
  late String registeredId;
  late String token;
}
