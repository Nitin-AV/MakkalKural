import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_civic_connect/utils/my_navigator.dart';
import 'package:url_launcher/url_launcher.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() =>
      _ComplaintsScreenState();
}

class _ComplaintsScreenState
    extends State<ComplaintsScreen> {

  final supabase = Supabase.instance.client;

  bool isLoading = true;
  List complaints = [];

  @override
  void initState() {
    super.initState();
    fetchComplaints();
  }

  Future<void> fetchComplaints() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null || user.phoneNumber == null) {
        setState(() {
          complaints = [];
          isLoading = false;
        });
        return;
      }

      final data = await supabase
          .from('complaints')
          .select(
              'id, issue_name, description, priority, status, image_url, latitude, longitude, created_at, ward_name')
          .eq('phone', user.phoneNumber!)
          .order('created_at', ascending: false);

      setState(() {
        complaints = data;
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load complaints")),
      );
    }
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 25),
            decoration: const BoxDecoration(
              color: Color(0xFF4A90E2),
            ),
            child: const Center(
              child: Text(
                "My Complaints",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: fetchComplaints,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : complaints.isEmpty
                      ? _emptyState()
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          itemCount: complaints.length,
                          itemBuilder: (context, index) {
                            return _complaintCard(complaints[index]);
                          },
                        ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _bottomNavigation(context),
    );
  }

  Widget _complaintCard(Map<String, dynamic> item) {
    final String priority =
    (item['priority'] ?? 'low').toString().toLowerCase();

Color priorityColor;

switch (priority) {
  case 'high':
    priorityColor = Colors.red;
    break;
  case 'medium':
    priorityColor = Colors.orange;
    break;
  default:
    priorityColor = Colors.green;
}

    Color statusColor;
    switch (item['status']) {
      case 'closed':
        statusColor = Colors.green;
        break;
      case 'progress':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item['issue_name'] ?? "",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            item['description'] ?? "",
            style: const TextStyle(
                fontSize: 14,
                color: Colors.black87),
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              if (item['created_at'] != null)
                Text(
                  "Reported: ${item['created_at'].toString().substring(0, 10)}",
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey),
                ),
              if (item['ward_name'] != null)
                Text(
                  "Ward: ${item['ward_name']}",
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.blueGrey),
                ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              _badge(
                priority.toUpperCase(),
                priorityColor,
              ),
              const SizedBox(width: 12),
              _badge(
                (item['status'] ?? "open").toUpperCase(),
                statusColor,
              ),
            ],
          ),

          const SizedBox(height: 12),
          Row(
            children: [

              if (item['image_url'] != null)
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(
                              title: const Text("Complaint Image")),
                          body: Center(
                            child:
                                Image.network(item['image_url']),
                          ),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.image),
                  label: const Text("View Image"),
                ),

              if (item['latitude'] != null &&
                  item['longitude'] != null)
                TextButton.icon(
                  onPressed: () async {
                    final url =
                        "https://www.google.com/maps/search/?api=1&query=${item['latitude']},${item['longitude']}";

                    await launchUrl(
                      Uri.parse(url),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                  icon:
                      const Icon(Icons.location_on),
                  label: const Text("Location"),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined,
              size: 70, color: Colors.grey),
          SizedBox(height: 15),
          Text(
            "No complaints yet",
            style: TextStyle(
                fontSize: 18,
                color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _bottomNavigation(BuildContext context) {
    return Container(
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
        mainAxisAlignment:
            MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon:
                const Icon(Icons.home, color: Colors.grey),
            onPressed: () =>
                MyNavigator.goHome(context),
          ),
          const Icon(
            Icons.assignment_outlined,
            color: Color(0xFF4A90E2),
          ),
          IconButton(
            icon: const Icon(
                Icons.notifications_none,
                color: Colors.grey),
            onPressed: () =>
                MyNavigator.goNotifications(context),
          ),
        ],
      ),
    );
  }
}