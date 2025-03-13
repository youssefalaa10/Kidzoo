import 'package:flutter/material.dart';
import 'package:kidzoo/modules/home/UI/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kidzoo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
      // BlocProvider(
      //   create: (context) => AlphabetBloc(),
      //   child: const HomeScreen(),
      // ),
    );
  }
}
