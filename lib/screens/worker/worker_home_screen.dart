import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_civic_connect/screens/worker/worker_complaint_detail_screen.dart';
import 'package:smart_civic_connect/screens/login/location_screen.dart';
import 'package:smart_civic_connect/services/local_storage.dart';

class WorkerHomeScreen extends StatefulWidget {
  final Map<String, dynamic> workerData;

  const WorkerHomeScreen({super.key, required this.workerData});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  final supabase = Supabase.instance.client;

  bool isLoading = true;
  List<Map<String, dynamic>> complaints = [];

  int get openCount =>
      complaints.where((c) => c['status'] == 'open').length;
  int get progressCount =>
      complaints.where((c) => c['status'] == 'progress').length;
  int get closedCount =>
      complaints.where((c) => c['status'] == 'closed').length;

  @override
  void initState() {
    super.initState();
    _fetchAssignedComplaints();
  }

  Future<void> _fetchAssignedComplaints() async {
    setState(() => isLoading = true);
    try {
      final workerId = widget.workerData['id'] as int;
      final data = await supabase
          .from('complaints')
          .select(
              'id, complaint_id, issue_name, description, priority, status, image_url, latitude, longitude, created_at, ward_name, deadline, additional_comments')
          .eq('assigned_worker_id', workerId)
          .order('created_at', ascending: false);

      setState(() {
        complaints = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load complaints")),
        );
      }
    }
  }

  Future<void> _logout() async {
    await AppLocalStorage.logout();
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LocationScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final workerName = widget.workerData['name'] ?? "Worker";
    final wardName = widget.workerData['ward_name'] ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: RefreshIndicator(
        onRefresh: _fetchAssignedComplaints,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(35),
                    bottomRight: Radius.circular(35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Hi, Worker",
                              style:
                                  TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            Text(
                              workerName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          onPressed: _logout,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_city,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 5),
                        Text(
                          wardName,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // Stats row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    _statCard(
                        color: Colors.blue,
                        icon: Icons.assignment,
                        title: "Open",
                        count: openCount),
                    _statCard(
                        color: Colors.orange,
                        icon: Icons.timelapse,
                        title: "In Progress",
                        count: progressCount),
                    _statCard(
                        color: Colors.green,
                        icon: Icons.check_circle,
                        title: "Completed",
                        count: closedCount),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Assigned Complaints",
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${complaints.length}/10",
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              isLoading
                  ? const Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: CircularProgressIndicator(),
                    )
                  : complaints.isEmpty
                      ? _emptyState()
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: complaints.length,
                          itemBuilder: (context, index) =>
                              _complaintCard(complaints[index]),
                        ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _complaintCard(Map<String, dynamic> item) {
    final String status = item['status'] ?? 'open';
    Color statusColor;
    switch (status) {
      case 'closed':
        statusColor = Colors.green;
        break;
      case 'progress':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.red;
    }

    final bool isClosedItem = status == 'closed';

    return GestureDetector(
      onTap: isClosedItem
          ? null
          : () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkerComplaintDetailScreen(
                    complaint: item,
                    workerId: widget.workerData['id'] as int,
                  ),
                ),
              );
              _fetchAssignedComplaints();
            },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isClosedItem
              ? Colors.white.withOpacity(0.7)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (item['complaint_id'] != null)
                  Text(
                    item['complaint_id'],
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                      letterSpacing: 1,
                    ),
                  ),
                _statusBadge(status.toUpperCase(), statusColor),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item['issue_name'] ?? "",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isClosedItem ? Colors.grey : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item['description'] ?? "",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (item['ward_name'] != null)
                  Row(
                    children: [
                      const Icon(Icons.location_city,
                          size: 13, color: Colors.blueGrey),
                      const SizedBox(width: 4),
                      Text(
                        item['ward_name'],
                        style: const TextStyle(
                            fontSize: 12, color: Colors.blueGrey),
                      ),
                    ],
                  ),
                if (!isClosedItem)
                  const Row(
                    children: [
                      Text("Tap to complete",
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF2E7D32))),
                      Icon(Icons.chevron_right,
                          size: 16, color: Color(0xFF2E7D32)),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _statCard({
    required Color color,
    required IconData icon,
    required String title,
    required int count,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(title,
                style:
                    const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return const Padding(
      padding: EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(Icons.assignment_outlined, size: 70, color: Colors.grey),
          SizedBox(height: 15),
          Text(
            "No complaints assigned yet",
            style: TextStyle(fontSize: 17, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
