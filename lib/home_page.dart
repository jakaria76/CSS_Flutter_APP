import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String status = 'Checking Supabase connection...';

  @override
  void initState() {
    super.initState();
    testConnection();
  }

  Future<void> testConnection() async {
    try {
      final supabase = Supabase.instance.client;

      final data = await supabase
          .from('test_connection') // ✅ YOUR OWN TABLE
          .select()
          .limit(1);

      setState(() {
        status = '✅ Supabase connected successfully!\n$data';
      });
    } catch (e) {
      setState(() {
        status = '❌ Connection failed: $e';
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CSS Mobile App')),
      body: Center(
        child: Text(
          status,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
