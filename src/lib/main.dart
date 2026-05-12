import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Calculator Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;

  const MyHomePage({super.key, required this.title});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _firstController = TextEditingController();
  final TextEditingController _secondController = TextEditingController();
  String _resultText = 'Result will appear here';
  bool _loading = false;
  final String backendBase = 'http://127.0.0.1:8000';

  @override
  void dispose() {
    _firstController.dispose();
    _secondController.dispose();
    super.dispose();
  }

  int? _parseInt(String value) {
    return int.tryParse(value.trim());
  }

  Future<void> _calculate(String op) async {
    final a = _parseInt(_firstController.text);
    final b = _parseInt(_secondController.text);
    if (a == null || b == null) {
      setState(() {
        _resultText = 'Enter valid integers in both fields';
      });
      return;
    }

    final endpoint = {
      '+': '/calculator/add',
      '-': '/calculator/subtract',
      '*': '/calculator/multiply',
      '/': '/calculator/divide',
    }[op]!;

    setState(() {
      _loading = true;
      _resultText = 'Loading...';
    });

    try {
      final uri = Uri.parse('$backendBase$endpoint');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'a': a, 'b': b}),
      );

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        final num result = body['result'];
        setState(() {
          if (result == result.roundToDouble()) {
            _resultText = result.toInt().toString();
          } else {
            _resultText = result.toString();
          }
        });
      } else if (resp.statusCode == 400) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        setState(() => _resultText = body['detail'] ?? 'Bad request');
      } else {
        setState(() => _resultText = 'Server error: ${resp.statusCode}');
      }
    } catch (e) {
      setState(() => _resultText = 'Network error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _firstController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'First integer',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _secondController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Second integer',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : () => _calculate('+'),
                    child: const Text('Add'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : () => _calculate('-'),
                    child: const Text('Subtract'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : () => _calculate('*'),
                    child: const Text('Multiply'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : () => _calculate('/'),
                    child: const Text('Divide'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _resultText,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
