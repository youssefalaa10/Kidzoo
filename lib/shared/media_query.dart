import 'package:flutter/material.dart';

class CustomMQ {
  final BuildContext context;

  // Constructor to accept the BuildContext
  CustomMQ(this.context);

  // Method to calculate width based on a factor
  double width(double factor) {
    return MediaQuery.of(context).size.width * (factor / 100);
  }

  // Method to calculate height based on a factor
  double height(double factor) {
    return MediaQuery.of(context).size.height * (factor / 100);
  }

  // Function will call like this ResMediaQuery(context).height(10);  10% percentage of height of page
}