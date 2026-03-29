import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class WorkerComplaintDetailScreen extends StatefulWidget {
  final Map<String, dynamic> complaint;
  final int workerId;

  const WorkerComplaintDetailScreen({
    super.key,
    required this.complaint,
    required this.workerId,
  });

  @override
  State<WorkerComplaintDetailScreen> createState() =>
      _WorkerComplaintDetailScreenState();
}

class _WorkerComplaintDetailScreenState
    extends State<WorkerComplaintDetailScreen> {
  final supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  File? _completionPhoto;
  bool _isSubmitting = false;

  Future<void> _pickCompletionPhoto(ImageSource source) async {
    final XFile? photo = await _picker.pickImage(source: source);
    if (photo == null) return;
    setState(() => _completionPhoto = File(photo.path));
  }

  Future<void> _markAsCompleted() async {
    if (_completionPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please take a completion photo first."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final complaintId = widget.complaint['id']?.toString() ?? '';
      final fileName =
          'completion_${complaintId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await supabase.storage
          .from('civic_storage')
          .upload(fileName, _completionPhoto!);

      final photoUrl =
          supabase.storage.from('civic_storage').getPublicUrl(fileName);

      await supabase.from('complaints').update({
        'status': 'closed',
        'completion_image_url': photoUrl,
      }).eq('id', widget.complaint['id']);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Complaint marked as completed!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to submit. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.complaint;
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

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(10, 60, 20, 25),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.only(right: 40.0),
                          child: Text(
                            "Complaint Detail",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item['complaint_id'] != null)
                        _infoTile(
                          icon: Icons.tag,
                          iconColor: const Color(0xFF2E7D32),
                          title: "Complaint Number",
                          value: item['complaint_id'],
                        ),
                      const SizedBox(height: 12),

                      _infoTile(
                        icon: Icons.report_problem,
                        iconColor: Colors.red,
                        title: "Issue",
                        value: item['issue_name'] ?? "-",
                        subtitle: item['description'],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _smallTile(
                              "Priority",
                              priority.toUpperCase(),
                              priorityColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _smallTile(
                              "Ward",
                              item['ward_name'] ?? "-",
                              Colors.blueGrey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (item['deadline'] != null)
                        _infoTile(
                          icon: Icons.timer,
                          iconColor: Colors.orange,
                          title: "Deadline",
                          value: item['deadline'].toString().substring(0, 10),
                        ),

                      if (item['image_url'] != null) ...[
                        const SizedBox(height: 12),
                        _infoTile(
                          icon: Icons.image,
                          iconColor: Colors.purple,
                          title: "Issue Photo",
                          value: "Tap to view",
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Scaffold(
                                appBar: AppBar(
                                    title: const Text("Issue Photo")),
                                body: Center(
                                  child: Image.network(item['image_url']),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],

                      if (item['latitude'] != null &&
                          item['longitude'] != null) ...[
                        const SizedBox(height: 12),
                        _infoTile(
                          icon: Icons.location_on,
                          iconColor: Colors.blue,
                          title: "Location",
                          value: "Tap to open in Maps",
                          onTap: () async {
                            final url =
                                "https://www.google.com/maps/search/?api=1&query=${item['latitude']},${item['longitude']}";
                            await launchUrl(Uri.parse(url),
                                mode: LaunchMode.externalApplication);
                          },
                        ),
                      ],

                      const SizedBox(height: 28),
                      const Text(
                        "Mark as Completed",
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Take a photo of the resolved issue before marking complete.",
                        style: TextStyle(
                            fontSize: 13, color: Colors.black54),
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _pickCompletionPhoto(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt,
                                  color: Colors.white),
                              label: const Text("Camera",
                                  style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _pickCompletionPhoto(ImageSource.gallery),
                              icon: const Icon(Icons.photo,
                                  color: Colors.white),
                              label: const Text("Gallery",
                                  style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF388E3C),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (_completionPhoto != null) ...[
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            _completionPhoto!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],

                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _markAsCompleted,
                          icon: const Icon(Icons.check_circle,
                              color: Colors.white),
                          label: const Text(
                            "Mark as Completed",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 4,
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (_isSubmitting)
            Container(
              color: Colors.black.withOpacity(0.35),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                  Text(title,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 3),
                  Text(value,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: onTap != null
                            ? const Color(0xFF2E7D32)
                            : Colors.black87,
                      )),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black54)),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _smallTile(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
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
          Text(title,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14)),
        ],
      ),
    );
  }
}
