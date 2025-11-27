import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MathApp());

class MathApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Math Challenge',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MathHomePage(),
    );
  }
}

class MathHomePage extends StatefulWidget {
  @override
  _MathHomePageState createState() => _MathHomePageState();
}

class _MathHomePageState extends State<MathHomePage> {
  String question = "Loading...";
  int answer = 0;
  final TextEditingController _controller = TextEditingController();
  final Random _rand = Random();
  int points = 0;
  int streak = 0;

  @override
  void initState() {
    super.initState();
    _generateQuestion();
  }

  Future<void> _generateQuestion() async {
    setState(() {
      question = "Loading...";
      _controller.clear();
    });

    int randomId = _rand.nextInt(100000);
    List<String> operations = ['+', '-', '×', '÷'];
    String operation = operations[_rand.nextInt(operations.length)];

    String prompt =
        "Generate a simple arithmetic math question for a child using operation $operation. "
        "Format: Question: ... Answer: ... Only question and answer.Make it medium hard. Random ID: $randomId";

    final url =
        Uri.parse('https://text.pollinations.ai/${Uri.encodeComponent(prompt)}');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        String text = response.body;
        if (!text.contains('Answer:')) {
          setState(() {
            question = "Invalid question received. Retrying...";
          });
          Future.delayed(Duration(seconds: 1), _generateQuestion);
          return;
        }
        final split = text.split('Answer:');
        setState(() {
          question = split[0].replaceAll('Question:', '').trim();
          answer = int.tryParse(split[1].trim()) ?? 0;
        });
      } else {
        setState(() {
          question = "Error generating question!";
        });
      }
    } catch (e) {
      setState(() {
        question = "Error: $e";
      });
    }
  }

  void _checkAnswer() {
    int? userAnswer = int.tryParse(_controller.text);

    if (userAnswer == null) {
      _showPopup("Please enter a valid number!", false);
      return;
    }

    bool correct = userAnswer == answer;

    setState(() {
      points += correct ? 10 : 0;
      streak = correct ? streak + 1 : 0;
    });

    _showPopup(correct ? "Correct!" : "Wrong! Correct answer: $answer", correct);

    _generateQuestion();
  }

  void _showPopup(String message, bool correct) {
    showGeneralDialog(
      context: context,
      barrierLabel: "Result",
      barrierDismissible: true,
      transitionDuration: Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Container(
            width: 300,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: correct ? Colors.green[400] : Colors.red[400],
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(correct ? Icons.check_circle : Icons.cancel,
                    size: 50, color: Colors.white),
                SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, color: Colors.white),
                ),
                SizedBox(height: 15),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: correct ? Colors.green : Colors.red,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("OK"),
                )
              ],
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.elasticOut),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Daily Math Challenge')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(question, style: TextStyle(fontSize: 24)),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Your Answer'),
            ),
            SizedBox(height: 10),
            ElevatedButton(onPressed: _checkAnswer, child: Text('Submit')),
            SizedBox(height: 20),
            Text('Points: $points    Streak: $streak',
                style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
