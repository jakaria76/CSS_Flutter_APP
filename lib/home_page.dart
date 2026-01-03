import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool loading = true;
  bool connected = false;
  String message = 'Checking Supabase connection...';

  @override
  void initState() {
    super.initState();
    testConnection();
  }

  Future<void> testConnection() async {
    setState(() {
      loading = true;
      message = 'Checking Supabase connection...';
    });

    try {
      final supabase = Supabase.instance.client;

      // ✅ Correct Flutter way
      supabase.auth.currentSession;

      setState(() {
        connected = true;
        message = 'Supabase connected successfully';
        loading = false;
      });
    } catch (e) {
      setState(() {
        connected = false;
        message = 'Connection failed:\n$e';
        loading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1D2671),
        title: const Text(
          'CSS Mobile App',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 14,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ================= ICON =================
                CircleAvatar(
                  radius: 45,
                  backgroundColor: connected
                      ? Colors.green.withOpacity(0.15)
                      : Colors.red.withOpacity(0.15),
                  child: Icon(
                    connected ? Icons.cloud_done : Icons.cloud_off,
                    color: connected ? Colors.green : Colors.red,
                    size: 50,
                  ),
                ),

                const SizedBox(height: 24),

                // ================= TITLE =================
                Text(
                  connected ? 'Connection Successful' : 'Connection Error',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: connected ? Colors.green : Colors.red,
                  ),
                ),

                const SizedBox(height: 12),

                // ================= MESSAGE =================
                Text(
                  loading ? 'Please wait...' : message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 30),

                // ================= ACTION BUTTON =================
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text(
                      'Retry Connection',
                      style: TextStyle(fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D2671),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: loading ? null : testConnection,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
