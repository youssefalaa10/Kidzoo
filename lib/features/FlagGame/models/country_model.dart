import 'package:flutter/material.dart';
import 'package:kidzo/core/localization/app_localizations.dart';

class Country {
  final String code;
  final String name;
  final String continent;
  final String capital;

  Country({
    required this.code,
    required this.name,
    required this.continent,
    required this.capital,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      continent: json['continent'] ?? '',
      capital: json['capital'] ?? '',
    );
  }

  String get flagAsset => 'assets/flags/${code.toLowerCase()}.svg';

  String localizedName(BuildContext context) {
    return AppLocalizations.of(context).getCountryName(code);
  }
}
