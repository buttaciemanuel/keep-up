/// Questo file contiene l'API per interfacciarsi con l'account istituzionale
/// del Politecnico di Torino per scaricare gli orari delle lezioni dello
/// studente
import 'dart:convert';
import 'dart:io';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// I parametri utilizzati nelle richieste HTTP inviate al server del Politecnico
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

/// Gli indirizzi di destinazione dell'API per le singole operazioni
class PolitoRequestEndpoint {
  static const registerDeviceEndpoint =
      'https://app.didattica.polito.it/register.php';
  static const loginEndpoint = 'https://app.didattica.polito.it/login.php';
  static const logoutEndpoint = 'https://app.didattica.polito.it/logout.php';
  static const scheduleEndpoint =
      'https://app.didattica.polito.it/orari_lezioni.php';
}

/// Le chiavi utilizzate per salvare matricola, password e token della sessione
/// all'interno del portachiavi
class PolitoSavedKey {
  static const user = 'polito.user';
  static const password = 'polito.password';
  static const token = 'polito.token';
}

/// Questa classe è utilizzata per ricevere una risposta attraverso una
/// future in seguito ad una richiesta http
class PolitoResponse<T> {
  // conferma la presenza di un errore nella richesta
  bool error = false;
  // contiene il messaggio di errore eventualmente
  String? message;
  // contiene il risultato della richiesta (e.g. la timetable delle lezioni)
  T? result;

  /// costruisce una risposta errata
  PolitoResponse.error(this.message) {
    error = true;
  }

  /// costruisce una risposta corretta con risultato
  PolitoResponse.result(this.result);

  /// costruisce una risposta corretta priva di risultato
  PolitoResponse() {
    result = null;
  }
}

/// La classe principale utilizzata per le principali operazioni dell'API:
/// [+] registrazione dispositivo (operazione implicita)
/// [+] login con matricola e password
/// [+] logout
/// [+] scaricamento orari delle lezioni
class PolitoClient {
  /// id univoco con cui il dispositivo è registrato sul server del Politecnico
  late String _registeredId;

  /// stringa che identifica la sessione stabilita dopo il login
  PolitoUserSession? _session;

  /// portachiavi utilizzato per salvare info della sessione corrente
  final _keychain = const FlutterSecureStorage();

  static final PolitoClient _instance = PolitoClient._();

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

  /// codifica i parametri nel modo preciso affinchè la richiesta sia accetata
  /// ed elaborata corretamente
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

  /// ogni richiesta HTTP è trattata con il metodo POST
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

  /// Questa funzione è utilizzata per inizializzare l'API e deve essere chiamata
  /// per prima.
  /// Verifica inizialmente se l'utente è loggato e quindi esiste una sessione
  /// in corso. Nel qual caso in cui non ci sia nessuna sessione, allora si procede
  /// con la registrazione del dispositivo
  Future<PolitoResponse> init() async {
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
        return PolitoResponse.error(
            'PolitoClient: unable to register device. ${jsonBody['esito']['generale']['error']}');
      }
    }

    return PolitoResponse();
  }

  /// Restituisce l'utente dell'attuale sessione o null se nessun utente è loggato
  /// attualmente
  PolitoUser? get user => _session?.user;

  /// Questa funzione è utilizzata per autenticare l'utente con matricola e password
  /// del Politecnico. Se tutto va correttamente, al termine la sessione è stabilita
  /// e le informazioni sono preservate nel portachiavi fino al prossimo logout.
  Future<PolitoResponse> loginUser(String userId, String password) async {
    final response = await _makeRequest(PolitoRequestEndpoint.loginEndpoint, {
      PolitoRequestParams.registeredIdParam: _registeredId,
      PolitoRequestParams.userIdParam: userId,
      PolitoRequestParams.passwordParam: password
    });
    final jsonBody = jsonDecode(response.body);

    print('[login ${response.statusCode} ${response.reasonPhrase}]');
    print('${response.body}');

    if (_didRequestFailed(response)) {
      return PolitoResponse.error(
          'PolitoClient: unable to login user. ${jsonBody['esito']['generale']['error']}');
    } else {
      _session = PolitoUserSession();
      _session!.token = jsonBody['data']['login']['token'] as String;
      _session!.user = PolitoUser(userId);
      _keychain.write(key: PolitoSavedKey.user, value: userId);
      _keychain.write(key: PolitoSavedKey.password, value: password);
      _keychain.write(key: PolitoSavedKey.token, value: _session!.token);
    }

    return PolitoResponse();
  }

  /// Quando l'utente esegue il logout, la sessione è chiusa e tutte le informazioni
  /// nel portachiavi sono eliminate.
  Future<PolitoResponse> logoutUser() async {
    if (_session == null) {
      return PolitoResponse.error('PolitoClient: no session is established');
    }

    final response = await _makeRequest(PolitoRequestEndpoint.logoutEndpoint, {
      PolitoRequestParams.registeredIdParam: _registeredId,
      PolitoRequestParams.tokenParam: _session!.token
    });
    final jsonBody = jsonDecode(response.body);

    print('[logout ${response.statusCode} ${response.reasonPhrase}]');
    print('${response.body}');

    if (_didRequestFailed(response)) {
      return PolitoResponse.error(
          'PolitoClient: unable to logout user. ${jsonBody['esito']['generale']['error']}');
    } else {
      _session = null;
      _keychain.delete(key: PolitoSavedKey.user);
      _keychain.delete(key: PolitoSavedKey.password);
      _keychain.delete(key: PolitoSavedKey.token);
    }

    return PolitoResponse();
  }

  /// Questa funzione è utile allo scopo dell'app poichè restituisce la lista
  /// degli orari ordinati delle lezioni dello studente loggato.
  /// Nota: il risultato è restituito come List<PolitoLecture>
  Future<PolitoResponse<List<PolitoLecture>>> getWeekSchedule(
      {DateTime? inDate}) async {
    if (_session == null) {
      return PolitoResponse.error('PolitoClient: no session is established');
    }

    final now = DateFormat('dd/MM/yyyy').format(inDate ?? DateTime.now());
    final response =
        await _makeRequest(PolitoRequestEndpoint.scheduleEndpoint, {
      PolitoRequestParams.registeredIdParam: _registeredId,
      PolitoRequestParams.tokenParam: _session!.token,
      PolitoRequestParams.refDateParam: now
    });
    final jsonBody = jsonDecode(response.body);
    final jsonLectures = jsonBody['data']['orari'];

    print('[schedule ${response.statusCode} ${response.reasonPhrase}]');
    print('${response.body}');

    if (_didRequestFailed(response)) {
      return PolitoResponse.error(
          'PolitoClient: unable get user schedule. ${jsonBody['esito']['generale']['error']}');
    }

    List<PolitoLecture> lectures = [];

    for (final jsonLecture in jsonLectures) {
      log('${jsonLecture['TITOLO_MATERIA']}: ${jsonLecture['ORA_INIZIO']} - ${jsonLecture['ORA_FINE']}');
      lectures.add(PolitoLecture.fromJson(jsonLecture));
    }

    lectures.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

    List<PolitoLecture> reduced = [];

    for (int i = 0; i < lectures.length;) {
      reduced.add(lectures[i++]);
      for (; i < lectures.length; ++i) {
        if (lectures[i].subject == reduced.last.subject &&
            lectures[i].startDateTime == reduced.last.endDateTime) {
          reduced.last.endDateTime = lectures[i].endDateTime;
        } else {
          break;
        }
      }
    }

    return PolitoResponse.result(reduced);
  }
}

/// Questa classe contiene le informazioni della sessione
class PolitoUserSession {
  /// Il token identifica la sessione attuale
  late String token;

  /// Lo user è l'utente autenticato nella sessione attuale
  late PolitoUser user;
}

/// Questa classe definisce l'utente loggato
class PolitoUser {
  // matricola univoca dello studente
  final String id;

  PolitoUser(this.id);
}

/// Questa classe rappresenta l'istanza di evento di una lezione settimanale
class PolitoLecture {
  // nome della materia
  String subject;
  // data e orario di inizio
  DateTime startDateTime;
  // data e orario di fine
  DateTime endDateTime;
  // insegnante
  String? lecturer;
  // nome aula
  String? room;
  // tipologia di evento
  String? eventType;
  // identificativo del corso a cui appartiene la lezione
  String? courseId;
  // identificativo della lezione
  String? lectureId;
  // inizio coorte
  String? cohortFrom;
  // fine coorte
  String? cohortTo;

  PolitoLecture(
      {required this.subject,
      this.lecturer,
      this.room,
      this.eventType,
      this.courseId,
      this.lectureId,
      this.cohortFrom,
      this.cohortTo,
      required this.startDateTime,
      required this.endDateTime});

  /// Estrapola una lezione dell'oggetto json ricevuto in risposta dal server
  /// del Politecnico
  factory PolitoLecture.fromJson(dynamic json) {
    final format = DateFormat('dd/MM/yyyy HH:mm:ss');
    return PolitoLecture(
        subject: json['TITOLO_MATERIA'],
        startDateTime: format.parse(json['ORA_INIZIO']),
        endDateTime: format.parse(json['ORA_FINE']),
        lecturer: json['NOMINATIVO_AULA'],
        room: json['AULA'],
        eventType: json['TIPOLOGIA_EVENTO'],
        courseId: json['NUMCOR'],
        lectureId: json['ID_EVENTO'],
        cohortFrom: json['ALFA_INI'],
        cohortTo: json['ALFA_FIN']);
  }
}
