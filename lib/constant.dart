import 'package:flutter/material.dart';

const weekDays = [
  'Lunedì',
  'Martedì',
  'Mercoledì',
  'Giovedì',
  'Venerdì',
  'Sabato',
  'Domenica'
];

abstract class UniversityItem {
  static const polito = 'Politenico di Torino';
}

abstract class AppEventColors {
  static const orange = Color(0xFFFF7F00);
  static const yellow = Color(0xFFE6AD41);
  static const green = Color(0xFF4AB45E);
  static const red = Color(0xFFCE4747);
  static const purple = Color(0xFFA25CF4);
  static const lightBlue = Color(0xFF1EC2C9);
  static const values = [orange, yellow, green, red, purple, lightBlue];

  static Color fromEvent(String title) {
    return values[title.hashCode % values.length];
  }
}
