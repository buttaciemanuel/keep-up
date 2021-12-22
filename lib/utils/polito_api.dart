import 'dart:convert';
import 'dart:io';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PolitoRequestParams {
  static const tokenParam = 'token';
  static const registeredIdParam = 'regID';
  static const fileCodeParam = 'code';
  static const incaricoParam = 'incarico';
  static const inserimentoParam = 'cod_ins';
  static const refDateParam = 'data_rif';
  static const userIdParam = 'username';
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
  static const registerDeviceEndpoint =
      'https://app.didattica.polito.it/register.php';
  static const loginEndpoint = 'https://app.didattica.polito.it/login.php';
  static const logoutEndpoint = 'https://app.didattica.polito.it/logout.php';
  static const scheduleEndpoint =
      'https://app.didattica.polito.it/orari_lezioni.php';
}

class PolitoSavedKey {
  static const user = 'polito.user';
  static const password = 'polito.password';
  static const token = 'polito.token';
}

class PolitoClient {
  late String _registeredId;
  PolitoUserSession? _session;
  final _keychain = new FlutterSecureStorage();

  static PolitoClient _instance = PolitoClient._();

  PolitoClient._();

  static PolitoClient get instance => _instance;

  static Future<Map<String, dynamic>> _getDeviceInfo() async {
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      final iosDeviceInfo = await deviceInfo.iosInfo;
      return {
        PolitoRequestParams.registeredIdParam:
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
        PolitoRequestParams.registeredIdParam: androidDeviceInfo.androidId,
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
      result += '"$key":"$value"';
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

  static bool _didRequestFailed(http.Response response) =>
      response.statusCode != 200 ||
      jsonDecode(response.body)['esito']['generale']['stato'] != 0;

  Future<void> init() async {
    final deviceInfo = await _getDeviceInfo();
    final sessionToken = await _keychain.read(key: PolitoSavedKey.token);
    final sessionUser = await _keychain.read(key: PolitoSavedKey.user);

    _registeredId = deviceInfo[PolitoRequestParams.registeredIdParam];

    if (sessionToken != null && sessionUser != null) {
      _session = PolitoUserSession();
      _session!.token = sessionToken;
      _session!.user = PolitoUser(sessionUser);
    } else {
      final response = await _makeRequest(
          PolitoRequestEndpoint.registerDeviceEndpoint, deviceInfo);
      final jsonBody = jsonDecode(response.body);

      print(deviceInfo);
      print('[device-reg ${response.statusCode} ${response.reasonPhrase}]');
      print('${response.body}');

      if (_didRequestFailed(response)) {
        return Future.error(
            'PolitoClient: unable to register device. ${jsonBody['esito']['generale']['error']}');
      }
    }
  }

  PolitoUser? get user => _session?.user;

  Future<void> loginUser(String userId, String password) async {
    final response = await _makeRequest(PolitoRequestEndpoint.loginEndpoint, {
      PolitoRequestParams.registeredIdParam: _registeredId,
      PolitoRequestParams.userIdParam: userId,
      PolitoRequestParams.passwordParam: password
    });
    final jsonBody = jsonDecode(response.body);

    print('[login ${response.statusCode} ${response.reasonPhrase}]');
    print('${response.body}');

    if (_didRequestFailed(response)) {
      return Future.error(
          'PolitoClient: unable to login user. ${jsonBody['esito']['generale']['error']}');
    } else {
      _session = PolitoUserSession();
      _session!.token = jsonBody['data']['login']['token'] as String;
      _session!.user = PolitoUser(userId);
      _keychain.write(key: PolitoSavedKey.user, value: userId);
      _keychain.write(key: PolitoSavedKey.password, value: password);
      _keychain.write(key: PolitoSavedKey.token, value: _session!.token);
    }
  }

  Future<void> logoutUser() async {
    if (_session == null) {
      return Future.error('PolitoClient: no session is established');
    }

    final response = await _makeRequest(PolitoRequestEndpoint.logoutEndpoint, {
      PolitoRequestParams.registeredIdParam: _registeredId,
      PolitoRequestParams.tokenParam: _session!.token
    });
    final jsonBody = jsonDecode(response.body);

    print('[logout ${response.statusCode} ${response.reasonPhrase}]');
    print('${response.body}');

    if (_didRequestFailed(response)) {
      return Future.error(
          'PolitoClient: unable to logout user. ${jsonBody['esito']['generale']['error']}');
    } else {
      _session = null;
      _keychain.delete(key: PolitoSavedKey.user);
      _keychain.delete(key: PolitoSavedKey.password);
      _keychain.delete(key: PolitoSavedKey.token);
    }
  }

  Future<void> getSchedule() async {
    if (_session == null) {
      return Future.error('PolitoClient: no session is established');
    }

    final now = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final response =
        await _makeRequest(PolitoRequestEndpoint.scheduleEndpoint, {
      PolitoRequestParams.registeredIdParam: _registeredId,
      PolitoRequestParams.tokenParam: _session!.token,
      PolitoRequestParams.refDateParam: now
    });
    final jsonBody = jsonDecode(response.body);
    final lectures = jsonBody['data']['orari'];

    print('[schedule ${response.statusCode} ${response.reasonPhrase}]');
    print('${response.body}');

    if (_didRequestFailed(response)) {
      return Future.error(
          'PolitoClient: unable get user schedule. ${jsonBody['esito']['generale']['error']}');
    }

    for (final lecture in lectures) {
      log('${lecture['TITOLO_MATERIA']}: ${lecture['ORA_INIZIO']} - ${lecture['ORA_FINE']}');
    }
  }
}

class PolitoUserSession {
  late String token;
  late PolitoUser user;
}

class PolitoUser {
  final String id;

  PolitoUser(this.id);
}
