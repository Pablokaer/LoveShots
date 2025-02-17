import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:vibration/vibration.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Love Shots',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Love Shots'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _randomPhrase = 'Carregando...';
  List<String> _phrases = [];
  Timer? _timer;
  Timer? _countdownTimer;
  final int _intervalSeconds = 5;
  double _percentageDiscovered = 0.0;
  List<String> _discoveredPhrases = [];
  int _countdown = 0;
  bool _isAppBarVisible = true;

  @override
  void initState() {
    super.initState();
    _loadPhrases();
    _startTimer();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPhrases() async {
    try {
      String fileContent = await rootBundle.loadString('assets/phrases.txt');
      _phrases = fileContent.split('\n').map((line) => line.trim()).toList();
      _getRandomPhrase();
    } catch (e) {
      setState(() {
        _randomPhrase = 'Erro ao carregar frases.';
      });
    }
  }

  void _getRandomPhrase() {
    if (_phrases.isEmpty) return;

    final random = Random();
    final index = random.nextInt(_phrases.length);
    final newPhrase = _phrases[index];

    if (!_discoveredPhrases.contains(newPhrase)) {
      _discoveredPhrases.add(newPhrase);
    }

    _percentageDiscovered = (_discoveredPhrases.length / _phrases.length) * 100;
    _countdown = _intervalSeconds;

    if (_percentageDiscovered == 100) {
      _timer?.cancel();
      _countdownTimer?.cancel();
    }

    // Vibração ao receber uma nova frase
    Vibration.hasVibrator().then((hasVibrator) {
      if (hasVibrator == true) {
        Vibration.vibrate(duration: 200);
      }
    });

    setState(() {
      _randomPhrase = newPhrase;
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: _intervalSeconds), (timer) {
      _getRandomPhrase();
    });
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        }
      });
    });
  }

  void _showDiscoveredPhrasesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Frases Descobertas'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _discoveredPhrases.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(_discoveredPhrases[index]),
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Fechar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _toggleAppBarVisibility() {
    setState(() {
      _isAppBarVisible = !_isAppBarVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        appBar: _isAppBarVisible
            ? AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        )
            : null,
        body: GestureDetector(
          onTap: _toggleAppBarVisibility,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  _randomPhrase,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
                Text(
                  'Frases Descobertas: ${_percentageDiscovered.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 16),
                ),
                if (_percentageDiscovered < 100)
                  Column(
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        'Próximo Sorteio em: $_countdown',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    _showDiscoveredPhrasesDialog(context);
                  },
                  child: const Text('Ver Frases Descobertas'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
