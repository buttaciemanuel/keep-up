import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'dart:convert';

const weekDayName = {
  1: 'Lunedì',
  2: 'Martedì',
  3: 'Mercoledì',
  4: 'Giovedì',
  5: 'Venerdì',
  6: 'Sabato',
  7: 'Domenica'
};

const Map _universityPickerMap = {
  'Politecnico di Torino': {
    'Architettura': {
      1: 'https://www.swas.polito.it/dotnet/orari_lezione_pub/consultazione_generale.aspx?annoAccademicoConsultazione=2022&sedeConsultazione=6&sedeInfoConsultazione=TORINO+++++++++++++++++++&tipoCdlConsultazione=1&areaConsultazione=2&facoltaConsultazione=80&cdlConsultazione=1&cdlInfoConsultazione=ARCHITETTURA+(scienze+dell%27architettura)&key=1A44801A1492F9E62B640DCD18D9CC430C63135FA44AB8F9C4EF3BA6A2F7403B',
      2: 'https://www.swas.polito.it/dotnet/orari_lezione_pub/consultazione_generale.aspx?annoAccademicoConsultazione=2022&sedeConsultazione=6&sedeInfoConsultazione=TORINO+++++++++++++++++++&tipoCdlConsultazione=1&areaConsultazione=2&facoltaConsultazione=80&cdlConsultazione=1&cdlInfoConsultazione=ARCHITETTURA+(scienze+dell%27architettura)&annoConsultazione=2&orientamentoConsultazione=0&cognomeConsultazione=AAAA&dataInizioConsultazione=2021-12-20&key=C95A315F6C2A1C92C020CB74DD539E8999CDF36AD48AB1852E4FD956A115DB47',
      3: 'https://www.swas.polito.it/dotnet/orari_lezione_pub/consultazione_generale.aspx?annoAccademicoConsultazione=2022&sedeConsultazione=6&sedeInfoConsultazione=TORINO+++++++++++++++++++&tipoCdlConsultazione=1&areaConsultazione=2&facoltaConsultazione=80&cdlConsultazione=1&cdlInfoConsultazione=ARCHITETTURA+(scienze+dell%27architettura)&annoConsultazione=3&orientamentoConsultazione=0&cognomeConsultazione=AAAA&dataInizioConsultazione=2021-12-20&key=356EB4D851AD22FC428C5824D2302DE3F574695E619CCA2C532126E92AD9659A'
    },
    'Design': {
      1: 'https://www.swas.polito.it/dotnet/orari_lezione_pub/consultazione_generale.aspx?annoAccademicoConsultazione=2022&sedeConsultazione=6&sedeInfoConsultazione=TORINO+++++++++++++++++++&tipoCdlConsultazione=1&areaConsultazione=2&facoltaConsultazione=81&cdlConsultazione=6&cdlInfoConsultazione=DESIGN+E+COMUNICAZIONE+(disegno+industriale)&key=72E5128A28CFEE640DB1DE1D54B29A5CA12752BBB7A790A6436A4939D3E0E9DA',
      2: 'https://www.swas.polito.it/dotnet/orari_lezione_pub/consultazione_generale.aspx?annoAccademicoConsultazione=2022&sedeConsultazione=6&sedeInfoConsultazione=TORINO+++++++++++++++++++&tipoCdlConsultazione=1&areaConsultazione=2&facoltaConsultazione=81&cdlConsultazione=6&cdlInfoConsultazione=DESIGN+E+COMUNICAZIONE+(disegno+industriale)&annoConsultazione=2&orientamentoConsultazione=0&cognomeConsultazione=AAAA&dataInizioConsultazione=2021-12-20&key=25303FF7400836162BED7AAF58E5684EDCB1B910CFE688CADC55CB68CF3CCEE7',
      3: 'https://www.swas.polito.it/dotnet/orari_lezione_pub/consultazione_generale.aspx?annoAccademicoConsultazione=2022&sedeConsultazione=6&sedeInfoConsultazione=TORINO+++++++++++++++++++&tipoCdlConsultazione=1&areaConsultazione=2&facoltaConsultazione=81&cdlConsultazione=6&cdlInfoConsultazione=DESIGN+E+COMUNICAZIONE+(disegno+industriale)&annoConsultazione=3&orientamentoConsultazione=0&cognomeConsultazione=AAAA&dataInizioConsultazione=2021-12-20&key=D42814EE7DF8076057C1D6A051C0354CE69354D8FB47483917EF0B44216F9DBA'
    },
    'Ingegneria Informatica': {
      1: 'https://www.swas.polito.it/dotnet/orari_lezione_pub/consultazione_generale.aspx?annoAccademicoConsultazione=2022&sedeConsultazione=6&sedeInfoConsultazione=TORINO+++++++++++++++++++&tipoCdlConsultazione=1&areaConsultazione=1&facoltaConsultazione=37&cdlConsultazione=3&cdlInfoConsultazione=INGEGNERIA+INFORMATICA+(ingegneria+dell%27informazione)&key=05616175CF13895CBD998289A34E22332FEAFC1F7CC344D44C8BF283E5E34F93',
      2: 'https://www.swas.polito.it/dotnet/orari_lezione_pub/consultazione_generale.aspx?annoAccademicoConsultazione=2022&sedeConsultazione=6&sedeInfoConsultazione=TORINO+++++++++++++++++++&tipoCdlConsultazione=1&areaConsultazione=1&facoltaConsultazione=37&cdlConsultazione=3&cdlInfoConsultazione=INGEGNERIA+INFORMATICA+(ingegneria+dell%27informazione)&annoConsultazione=2&orientamentoConsultazione=0&cognomeConsultazione=AAAA&dataInizioConsultazione=2021-12-20&key=2BC7A64CE4DF5E8D55726FF0877AE367384C8D47917E30FA68F6548455AAFFAD',
      3: 'https://www.swas.polito.it/dotnet/orari_lezione_pub/consultazione_generale.aspx?annoAccademicoConsultazione=2022&sedeConsultazione=6&sedeInfoConsultazione=TORINO+++++++++++++++++++&tipoCdlConsultazione=1&areaConsultazione=1&facoltaConsultazione=37&cdlConsultazione=3&cdlInfoConsultazione=INGEGNERIA+INFORMATICA+(ingegneria+dell%27informazione)&annoConsultazione=3&orientamentoConsultazione=0&cognomeConsultazione=AAAA&dataInizioConsultazione=2021-12-20&key=63D9A07A8715EBF8FC5AA6DC9BF0DC418AAEFFB91C5300F6DE8FF520F79E27DE'
    }
  }
};

void fetchUniversityTimetable(
    String university, String course, int year) async {
  final url = Uri.parse("${_universityPickerMap[university][course][year]}");
  final response = await http.get(url);
  List<dynamic> jsonData =
      jsonDecode(response.body.split('v.events.list = ')[1].split(';')[0]);
  for (final activity in jsonData) {
    final name = html
        .parse(activity['text'].toString().split('<br>')[0])
        .children[0]
        .text;
    final start = DateTime.parse(activity['start']);
    final end = DateTime.parse(activity['end']);
    print(
        "$name -> ${weekDayName[start.weekday]} ${start.hour}:${start.minute}-${end.hour}:${end.minute}");
  }
}
