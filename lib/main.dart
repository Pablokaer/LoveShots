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

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  String _randomPhrase = 'Carregando...';
  List<String> _phrases = [];
  Timer? _timer;
  Timer? _countdownTimer;
  final int _intervalSeconds = 5;
  double _percentageDiscovered = 0.0;
  List<String> _discoveredPhrases = [];
  int _countdown = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPhrases();
    _startTimer();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xFFf12174),
        body: OrientationBuilder(
          builder: (context, orientation) {
            bool isPortrait = orientation == Orientation.portrait;

            // Definindo diferentes tamanhos para cada orientação
            double textSize = isPortrait ? 22 : 28; // Tamanho da frase
            double progressSize = isPortrait ? 60 : 50; // Tamanho da barra de progresso
            double buttonWidth = isPortrait ? 200 : 180; // Largura do botão
            double buttonHeight = isPortrait ? 50 : 40; // Altura do botão



            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // Texto posicionado perto da borda superior
                  Align(
                    alignment: Alignment.topCenter, // Alinha o texto no topo
                child: Transform.translate(
                  offset: const Offset(0, 4), // Desce o texto 4 pixels
                    child: Text(
                      'Love Shots', // Aqui é o texto desejado
                      style: TextStyle(
                        fontFamily: 'LoveFont', // Nome da fonte definida no pubspec.yaml
                        fontSize: 40,
                        color: Colors.white,
                      ),),
                    ),
                  ),
                  // Frase no centro
                  Expanded(
                    child: Center(
                      child: Text(
                        _randomPhrase,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: textSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Indicador de progresso (CÍRCULO)
                  Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: progressSize, // Tamanho ajustado
                            height: progressSize, // Tamanho ajustado
                            child: CircularProgressIndicator(
                              value: _percentageDiscovered / 100,
                              strokeWidth: 8,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF0066)),
                            ),
                          ),
                          Text(
                            '${_percentageDiscovered.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: isPortrait ? 16 : 15, // Tamanho do texto da porcentagem
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_percentageDiscovered < 100)
                        Text(
                          'Next in: $_countdown''s',
                          style: const TextStyle(fontSize: 14, color: Colors.white),

                        ),

                    ],
                  ),

                  const SizedBox(height: 20),

                  // Botão na parte inferior
                  SizedBox(
                    width: buttonWidth, // Largura do botão ajustada
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Color(0xFFFF0066),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        _showDiscoveredPhrasesDialog(context);
                      },
                      child: const Text(
                        'Discovered Phrases',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 35),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
