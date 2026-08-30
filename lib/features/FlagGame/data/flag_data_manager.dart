import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/country_model.dart';

class FlagDataManager {
  static List<Country> _countries = [];

  static List<Country> get countries => _countries;

  static Future<void> loadCountries() async {
    if (_countries.isNotEmpty) return;

    final String response =
        await rootBundle.loadString('assets/data/countries.json');
    final List<dynamic> data = json.decode(response);

    _countries = data.map((json) => Country.fromJson(json)).toList();

    print('🚩 Loaded ${_countries.length} available flags');
  }

  static List<Country> getRandomCountries(int count) {
    final list = List<Country>.from(_countries)..shuffle();
    return list.take(count).toList();
  }
}
