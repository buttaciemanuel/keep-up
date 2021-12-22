import 'dart:convert';
import 'dart:io';
import 'dart:developer';
import 'package:xml/xml.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:intl/intl.dart';

class PolitoRequestParams {
  static const String tokenParam = 'token';
  static const registeredIDParam = 'regID';
  static const fileCodeParam = 'code';
  static const incaricoParam = 'incarico';
  static const inserimentoParam = 'cod_ins';
  static const refDateParam = 'data_rif';
  static const usernameParam = 'username';
  static const passwordParam = 'password';
  static const roomTypeParam = 'local_type';
  static const dayParam = 'giorno';
  static const timeParam = 'ora';
  static const booksPerPageParam = 'numrec';
  static const deviceUUIDParam = 'uuid';
  static const devicePlatformParam = 'device_platform';
  static const deviceVersionParam = 'device_version';
  static const deviceModelParam = 'device_model';
  static const deviceManufacturerParam = 'device_manufacturer';
}

class PolitoRequestEndpoint {
  static const String registerDeviceEndpoint =
      "https://app.didattica.polito.it/register.php";
  static const String loginEndpoint =
      "https://app.didattica.polito.it/login.php";
  static const String logoutEndpoint =
      "https://app.didattica.polito.it/logout.php";
  static const String scheduleEndpoint =
      "https://app.didattica.polito.it/orari_lezioni.php";
}

class PolitoAPI {
  final PolitoUserSession _session = PolitoUserSession();

  static Future<Map<String, dynamic>> _getDeviceInfo() async {
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      final iosDeviceInfo = await deviceInfo.iosInfo;
      return {
        PolitoRequestParams.registeredIDParam:
            iosDeviceInfo.identifierForVendor,
        PolitoRequestParams.deviceUUIDParam: iosDeviceInfo.identifierForVendor,
        PolitoRequestParams.devicePlatformParam: 'iOS',
        PolitoRequestParams.deviceVersionParam: iosDeviceInfo.systemVersion,
        PolitoRequestParams.deviceModelParam: iosDeviceInfo.model,
        PolitoRequestParams.deviceManufacturerParam: 'Apple'
      };
    } else {
      final androidDeviceInfo = await deviceInfo.androidInfo;
      return {
        PolitoRequestParams.registeredIDParam: androidDeviceInfo.androidId,
        PolitoRequestParams.deviceUUIDParam: androidDeviceInfo.androidId,
        PolitoRequestParams.devicePlatformParam: 'Android',
        PolitoRequestParams.deviceVersionParam:
            androidDeviceInfo.version.baseOS,
        PolitoRequestParams.deviceModelParam: androidDeviceInfo.model,
        PolitoRequestParams.deviceManufacturerParam:
            androidDeviceInfo.manufacturer
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
    final response = await _makeRequest(
        PolitoRequestEndpoint.registerDeviceEndpoint, deviceInfo);

    print(deviceInfo);
    _session.registeredId = deviceInfo[PolitoRequestParams.registeredIDParam];

    print("[device-reg ${response.statusCode} ${response.reasonPhrase}]");
    print("${response.body}");

    return _session;
  }

  Future<void> loginUser(String username, String password) async {
    final response = await _makeRequest(PolitoRequestEndpoint.loginEndpoint, {
      PolitoRequestParams.registeredIDParam: _session.registeredId,
      PolitoRequestParams.usernameParam: username,
      PolitoRequestParams.passwordParam: password
    });

    _session.token =
        jsonDecode(response.body)['data']['login']['token'] as String;

    print("[login ${response.statusCode} ${response.reasonPhrase}]");
    print("${response.body}");
  }

  Future<void> logoutUser() async {
    final response = await _makeRequest(PolitoRequestEndpoint.logoutEndpoint, {
      PolitoRequestParams.registeredIDParam: _session.registeredId,
      PolitoRequestParams.tokenParam: _session.token
    });

    print("[logout ${response.statusCode} ${response.reasonPhrase}]");
    print("${response.body}");
  }

  Future<void> getSchedule() async {
    final now = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final response =
        await _makeRequest(PolitoRequestEndpoint.scheduleEndpoint, {
      PolitoRequestParams.registeredIDParam: _session.registeredId,
      PolitoRequestParams.tokenParam: _session.token,
      PolitoRequestParams.refDateParam: now
    });

    final lectures = jsonDecode(response.body)['data']['orari'];

    print('[schedule ${response.statusCode} ${response.reasonPhrase}]');
    print('${response.body}');

    for (final lecture in lectures) {
      log('${lecture['TITOLO_MATERIA']}: ${lecture['ORA_INIZIO']} - ${lecture['ORA_FINE']}');
    }
  }
}

class PolitoUserSession {
  late String registeredId;
  late String token;
}
