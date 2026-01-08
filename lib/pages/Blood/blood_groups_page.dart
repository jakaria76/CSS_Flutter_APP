import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'find_donors_map_page.dart';

class BloodGroupsPage extends StatefulWidget {
  const BloodGroupsPage({super.key});

  @override
  State<BloodGroupsPage> createState() => _BloodGroupsPageState();
}

class _BloodGroupsPageState extends State<BloodGroupsPage> {
  final supabase = Supabase.instance.client;
  bool _loading = true;

  final List<String> bloodGroups = [
    "A+","A-","B+","B-","O+","O-","AB+","AB-"
  ];

  Map<String, Map<String, int>> stats = {};

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _loading = true);

    final data = await supabase
        .from('profiles')
        .select('blood_group, donation_eligibility');

    Map<String, Map<String, int>> temp = {};
    for (var g in bloodGroups) {
      temp[g] = {"total": 0, "ready": 0};
    }

    for (var u in data) {
      final g = u['blood_group'];
      final e = (u['donation_eligibility'] ?? '').toString().toLowerCase();

      if (temp.containsKey(g)) {
        temp[g]!['total'] = temp[g]!['total']! + 1;
        if (e == 'eligible' || e == 'ready') {
          temp[g]!['ready'] = temp[g]!['ready']! + 1;
        }
      }
    }

    setState(() {
      stats = temp;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "BLOOD SUMMARY",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _loading
            ? const Center(
          child:
          CircularProgressIndicator(color: Colors.cyanAccent),
        )
            : RefreshIndicator(
          onRefresh: _fetchStats,
          color: Colors.cyanAccent,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 120, 16, 100),
            itemCount: bloodGroups.length,
            itemBuilder: (_, i) {
              final g = bloodGroups[i];
              final s = stats[g]!;

              return Container(
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  color: Colors.white.withOpacity(0.07),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      /// LEFT INFO
                      Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            g,
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: Colors.redAccent,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _infoChip(
                                "Total",
                                s['total']!,
                                Colors.white24,
                                Colors.white70,
                              ),
                              const SizedBox(width: 10),
                              _infoChip(
                                "Ready",
                                s['ready']!,
                                Colors.greenAccent
                                    .withOpacity(0.15),
                                Colors.greenAccent,
                              ),
                            ],
                          ),
                        ],
                      ),

                      /// FIND BUTTON
                      ElevatedButton.icon(
                        icon: const Icon(Icons.location_on),
                        label: const Text("FIND"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor:
                          const Color(0xFF0F2027),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  FindDonorsMapPage(
                                    bloodGroup: g,
                                  ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _infoChip(
      String label,
      int value,
      Color bg,
      Color textColor,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        "$label: $value",
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}
