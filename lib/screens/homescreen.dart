import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_civic_connect/utils/my_navigator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_civic_connect/screens/login/location_screen.dart';
import '../../services/local_storage.dart';
import 'package:smart_civic_connect/services/notif_badge.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final supabase = Supabase.instance.client;

  int openCount = 0;
  int progressCount = 0;
  int closedCount = 0;

  String userName = "";
  String location = "";

  @override
  void initState() {
    super.initState();
    loadDashboardData();
    NotifBadgeService.load();
  }

 Future<void> loadDashboardData() async {
  final phone = await AppLocalStorage.getUser();
  if (phone == null) return;

  final userData = await supabase
      .from('users')
      .select()
      .eq('phone', phone)
      .single();

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  // Use Firebase UID to fetch complaints (user_id column)
  final complaints = await supabase
      .from('complaints')
      .select()
      .eq('user_id', user.uid);

  int open = 0;
  int progress = 0;
  int closed = 0;

  for (var c in complaints) {
    if (c['status'] == 'open') open++;
    if (c['status'] == 'progress') progress++;
    if (c['status'] == 'closed') closed++;
  }

  setState(() {
    userName = userData['first_name'] ?? "";
    location = userData['location'] ?? "";
    openCount = open;
    progressCount = progress;
    closedCount = closed;
  });
}

  Widget buildStatCard(
      {required Color color,
      required IconData icon,
      required String title,
      required int count}) {

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              count.toString(),
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color),
            ),
            const SizedBox(height: 6),
            Text(title,
                style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),

      body: RefreshIndicator(
        onRefresh: loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4A90E2), Color(0xFF70C6FB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(35),
                      bottomRight: Radius.circular(35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Hi, $userName",
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout,
                              color: Colors.white),
                          onPressed: () async {
                            await AppLocalStorage.logout();
                            Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const LocationScreen()),
                                (route) => false);
                          },
                        )
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 5),
                        Text(
                          location,
                          style:
                              const TextStyle(color: Colors.white70),
                        )
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 25),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    buildStatCard(
                        color: Colors.blue,
                        icon: Icons.camera_alt,
                        title: "Open",
                        count: openCount),
                    buildStatCard(
                        color: Colors.orange,
                        icon: Icons.timelapse,
                        title: "In Progress",
                        count: progressCount),
                    buildStatCard(
                        color: Colors.green,
                        icon: Icons.check_circle,
                        title: "Resolved",
                        count: closedCount),
                  ],
                ),
              ),
              const SizedBox(height: 35),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  children: [

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.report_problem,color: Colors.white,),
                        label: const Text("Report Civic Issue",style: TextStyle(color: Colors.white),),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.red,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          MyNavigator.goReport(context);
                        }
                      ),
                    ),

                    const SizedBox(height: 15),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.list_alt,color: Colors.white),
                        label: const Text("View Complaints",style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF4A90E2),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          MyNavigator.goComplaints(context);
                        }
                      ),
                    )
                  ],
                ),
              ),

              

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),

      bottomNavigationBar: Container(
        height: 70,
        margin: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [

            IconButton(
              icon: const Icon(Icons.home, color: Color(0xFF4A90E2)),
              onPressed: () {},
            ),

            IconButton(
              icon: const Icon(Icons.assignment_outlined,
                  color: Colors.grey),
              onPressed: () {
                MyNavigator.goComplaints(context);
              },
            ),

            IconButton(
              icon: ValueListenableBuilder<int>(
                valueListenable: NotifBadgeService.count,
                builder: (_, cnt, __) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_none, color: Colors.grey),
                    if (cnt > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              onPressed: () {
                MyNavigator.goNotifications(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}