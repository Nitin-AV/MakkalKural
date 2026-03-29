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

      if (user == null) {
        setState(() {
          complaints = [];
          isLoading = false;
        });
        return;
      }

      final data = await supabase
          .from('complaints')
          .select(
              'id, complaint_id, issue_name, description, priority, status, image_url, latitude, longitude, created_at, assigned_to, assigned_worker_id, deadline, ward_name, rating, review')
          .eq('user_id', user.uid)
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

  Future<Map<String, dynamic>?> _fetchWorkerDetails(int workerId) async {
    try {
      final data = await supabase
          .from('workers')
          .select('id, name, phone, ward_name')
          .eq('id', workerId)
          .maybeSingle();
      return data;
    } catch (_) {
      return null;
    }
  }

  void _openDetail(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ComplaintDetailSheet(
        item: item,
        fetchWorkerDetails: _fetchWorkerDetails,
      ),
    );
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

    return GestureDetector(
      onTap: () => _openDetail(item),
      child: Container(
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
            // Complaint number row
            if (item['complaint_id'] != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Complaint No: ${item['complaint_id']}",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A90E2),
                    letterSpacing: 1,
                  ),
                ),
              ),

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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87),
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    item['ward_name'],
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.blueGrey),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _badge(priority.toUpperCase(), priorityColor),
                    const SizedBox(width: 10),
                    _badge((item['status'] ?? "open").toUpperCase(), statusColor),
                  ],
                ),
                const Row(
                  children: [
                    Text("Details", style: TextStyle(color: Color(0xFF4A90E2), fontSize: 13)),
                    Icon(Icons.chevron_right, color: Color(0xFF4A90E2), size: 18),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 70, color: Colors.grey),
          SizedBox(height: 15),
          Text(
            "No complaints yet",
            style: TextStyle(fontSize: 18, color: Colors.grey),
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.grey),
            onPressed: () => MyNavigator.goHome(context),
          ),
          const Icon(
            Icons.assignment_outlined,
            color: Color(0xFF4A90E2),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.grey),
            onPressed: () => MyNavigator.goNotifications(context),
          ),
        ],
      ),
    );
  }
}

// ─── Detail Bottom Sheet ────────────────────────────────────────────────────

class _ComplaintDetailSheet extends StatefulWidget {
  final Map<String, dynamic> item;
  final Future<Map<String, dynamic>?> Function(int) fetchWorkerDetails;

  const _ComplaintDetailSheet({
    required this.item,
    required this.fetchWorkerDetails,
  });

  @override
  State<_ComplaintDetailSheet> createState() => _ComplaintDetailSheetState();
}

class _ComplaintDetailSheetState extends State<_ComplaintDetailSheet> {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? workerData;
  bool loadingWorker = false;

  // Rating & Review
  int _selectedRating = 0;
  int _savedRating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _reviewSaved = false;
  bool _submittingReview = false;

  @override
  void initState() {
    super.initState();
    final workerId = widget.item['assigned_worker_id'];
    if (workerId != null) {
      _loadWorker(workerId as int);
    }
    // Pre-fill existing rating/review if already submitted
    final existingRating = widget.item['rating'];
    final existingReview = widget.item['review'] as String?;
    if (existingRating != null) {
      _savedRating = (existingRating as num).toInt();
      _selectedRating = _savedRating;
      _reviewSaved = true;
    }
    if (existingReview != null && existingReview.isNotEmpty) {
      _reviewController.text = existingReview;
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _loadWorker(int id) async {
    setState(() => loadingWorker = true);
    final data = await widget.fetchWorkerDetails(id);
    if (mounted) setState(() { workerData = data; loadingWorker = false; });
  }

  Future<void> _submitReview() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a star rating."), backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() => _submittingReview = true);
    try {
      await supabase.from('complaints').update({
        'rating': _selectedRating,
        'review': _reviewController.text.trim(),
      }).eq('id', widget.item['id']);
      if (mounted) {
        setState(() {
          _savedRating = _selectedRating;
          _reviewSaved = true;
          _submittingReview = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Review submitted. Thank you!"), backgroundColor: Colors.green),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _submittingReview = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to submit review."), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final String status = item['status'] ?? 'open';

    Color statusColor;
    switch (status) {
      case 'closed':   statusColor = Colors.green;  break;
      case 'progress': statusColor = Colors.orange; break;
      default:         statusColor = Colors.red;
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF4F7FB),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

            // Complaint Number
            if (item['complaint_id'] != null)
              _infoCard(
                icon: Icons.tag,
                iconColor: const Color(0xFF4A90E2),
                title: "Complaint Number",
                value: item['complaint_id'],
              ),

            const SizedBox(height: 12),

            // Issue
            _infoCard(
              icon: Icons.report_problem,
              iconColor: Colors.red,
              title: "Issue",
              value: item['issue_name'] ?? "-",
              subtitle: item['description'],
            ),

            const SizedBox(height: 12),

            // Status & Priority
            Row(children: [
              Expanded(
                child: _smallInfoCard(
                  "Status",
                  status.toUpperCase(),
                  statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _smallInfoCard(
                  "Priority",
                  (item['priority'] ?? "low").toUpperCase(),
                  item['priority']?.toString().toLowerCase() == 'high'
                      ? Colors.red
                      : item['priority']?.toString().toLowerCase() == 'medium'
                          ? Colors.orange
                          : Colors.green,
                ),
              ),
            ]),

            const SizedBox(height: 12),

            // Ward & Date
            _infoCard(
              icon: Icons.location_city,
              iconColor: Colors.blueGrey,
              title: "Ward",
              value: item['ward_name'] ?? "-",
            ),
            const SizedBox(height: 12),

            _infoCard(
              icon: Icons.calendar_today,
              iconColor: Colors.purple,
              title: "Reported On",
              value: item['created_at'] != null
                  ? item['created_at'].toString().substring(0, 10)
                  : "-",
            ),

            if (item['deadline'] != null) ...[
              const SizedBox(height: 12),
              _infoCard(
                icon: Icons.timer,
                iconColor: Colors.orange,
                title: "Deadline",
                value: item['deadline'].toString().substring(0, 10),
              ),
            ],

            // ── Assigned Worker ──────────────────────
            const SizedBox(height: 20),
            const Text(
              "Assigned Worker",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            loadingWorker
                ? const Center(child: CircularProgressIndicator())
                : workerData != null
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: const Color(0xFF4A90E2).withOpacity(0.15),
                              child: const Icon(Icons.person, color: Color(0xFF4A90E2), size: 28),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  workerData!['name'] ?? "Worker",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (workerData!['phone'] != null)
                                  Text(
                                    workerData!['phone'],
                                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                                  ),
                                if (workerData!['ward_name'] != null)
                                  Text(
                                    workerData!['ward_name'],
                                    style: const TextStyle(color: Colors.blueGrey, fontSize: 13),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.person_outline, color: Colors.grey.shade400),
                            const SizedBox(width: 12),
                            const Text(
                              "No worker assigned yet",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),

            // Action buttons
            const SizedBox(height: 20),
            if (item['image_url'] != null)
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text("Complaint Image")),
                        body: Center(child: Image.network(item['image_url'])),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.image),
                label: const Text("View Complaint Image"),
              ),

            if (item['latitude'] != null && item['longitude'] != null)
              OutlinedButton.icon(
                onPressed: () async {
                  final url =
                      "https://www.google.com/maps/search/?api=1&query=${item['latitude']},${item['longitude']}";
                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.location_on),
                label: const Text("View Location on Map"),
              ),

            // ── Rating & Review (only for resolved complaints) ───────────
            if (status == 'closed') ..._buildRatingSection(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRatingSection() {
    return [
      const SizedBox(height: 24),
      const Divider(),
      const SizedBox(height: 16),
      Row(
        children: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
          const SizedBox(width: 8),
          const Text(
            "Rate the Work",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (_reviewSaved) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                "Submitted",
                style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
      const SizedBox(height: 4),
      const Text(
        "Your feedback helps improve civic services.",
        style: TextStyle(fontSize: 12, color: Colors.black54),
      ),
      const SizedBox(height: 14),

      // Star selector
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          final star = index + 1;
          final filled = _reviewSaved ? star <= _savedRating : star <= _selectedRating;
          return GestureDetector(
            onTap: _reviewSaved ? null : () => setState(() => _selectedRating = star),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                filled ? Icons.star_rounded : Icons.star_outline_rounded,
                color: filled ? Colors.amber : Colors.grey.shade400,
                size: 42,
              ),
            ),
          );
        }),
      ),

      const SizedBox(height: 16),

      // Review text box
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: TextField(
          controller: _reviewController,
          enabled: !_reviewSaved,
          maxLines: 4,
          maxLength: 300,
          decoration: InputDecoration(
            hintText: _reviewSaved
                ? (_reviewController.text.isEmpty ? "No review written." : null)
                : "Write your review (optional)...",
            hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: _reviewSaved ? Colors.grey.shade50 : Colors.white,
            counterStyle: const TextStyle(fontSize: 11, color: Colors.black38),
          ),
        ),
      ),

      const SizedBox(height: 14),

      if (!_reviewSaved)
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _submittingReview ? null : _submitReview,
            icon: _submittingReview
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded, color: Colors.white),
            label: Text(
              _submittingReview ? "Submitting..." : "Submit Review",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A90E2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 3,
            ),
          ),
        ),
    ];
  }

  Widget _infoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: iconColor.withOpacity(0.12),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 3),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallInfoCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
        ],
      ),
    );
  }
}