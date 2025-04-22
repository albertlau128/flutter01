import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  String metarData = '';

  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  Future<void> fetchMetar() async {
    const url = 'https://www.hko.gov.hk/aviat/metar_eng_revamp.json';
    try {
      final response = await http.get(Uri.parse(url));
      print('METAR HTTP response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        metarData = response.body;
        // final data = json.decode(response.body);
        // print('Decoded METAR data: $data');
        // final content = data['metar_decode_eng_json']?['content']?['table']?['content'];
        // metarData = content != null ? content.toString() : 'No METAR content found';
      } else {
        metarData = 'Error fetching METAR: HTTP ${response.statusCode}';
      }
    } catch (e) {
      metarData = 'Error fetching METAR: $e';
      print('Error fetching METAR: $e');
    }
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Timer? _metarTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<MyAppState>(context, listen: false);
      appState.fetchMetar();
      _metarTimer = Timer.periodic(Duration(seconds: 30), (_) {
        appState.fetchMetar();
      });
    });
  }
  
  @override
  void dispose() {
    _metarTimer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('A random AWESOME idea:'),
            Text(appState.current.asLowerCase),
            ElevatedButton(
              onPressed: () {
                appState.getNext();
              },
              child: Text('Next'),
            ),
            // New box to show METAR data
            Container(
              margin: const EdgeInsets.only(top: 20.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                appState.metarData.isNotEmpty ? appState.metarData : 'Loading METAR data...',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}