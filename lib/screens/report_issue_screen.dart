import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smart_civic_connect/screens/animated_screen_success.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  File? _issueImage;
  Position? _position;
  String? _imageUrl;

  String issueName = "";
  String description = "";
  String aiPriority = "";
  double aiConfidence = 0.0;

  bool isLoading = false;
  bool isCivicIssue = false;

  String _additionalComments = "";
  final TextEditingController _additionalCommentsController = TextEditingController();

  @override
  void dispose() {
    _additionalCommentsController.dispose();
    super.dispose();
  }

  String _generateComplaintId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random();
    final suffix = List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
    return 'CMP-$suffix';
  }
  Future<void> pickIssueImage(ImageSource source) async {
    final XFile? photo = await _picker.pickImage(source: source);
    if (photo == null) return;

    setState(() {
      _issueImage = File(photo.path);
      issueName = "";
      description = "";
      aiPriority = "";
      aiConfidence = 0.0;
      isCivicIssue = false;
      _imageUrl = null;
    });

    await _getLocation();
    await _processAI();
  }

  Future<void> _getLocation() async {
    try {
      LocationPermission permission =
          await Geolocator.requestPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      _position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {}
  }

  Future<String> _uploadImage(File image) async {
    if (_imageUrl != null) return _imageUrl!;

    final fileName =
        '${FirebaseAuth.instance.currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

    await supabase.storage
        .from('civic_storage')
        .upload(fileName, image);

    _imageUrl =
        supabase.storage.from('civic_storage')
            .getPublicUrl(fileName);

    return _imageUrl!;
  }

  Future<void> _processAI() async {
    if (_issueImage == null) return;

    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final imageUrl = await _uploadImage(_issueImage!);

      final response = await http.post(
        Uri.parse(
            'https://wriwcwwnywfqyqvjdvod.supabase.co/functions/v1/analyze-issue'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'imageUrl': imageUrl,
          'latitude': _position?.latitude,
          'longitude': _position?.longitude,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final isFake = data['is_fake'] ?? false;
        final detectedIssue = data['issue_name'] ?? "";
        final confidence =
            (data['confidence'] ?? 0.0).toDouble();

        if (isFake == true) {
          _showFakeImageDialog();
          setState(() => isLoading = false);
          return;
        }
        if (detectedIssue.isEmpty || confidence < 0.60) {
          isCivicIssue = false;
          _showInvalidIssueDialog();
          setState(() => isLoading = false);
          return;
        }

        setState(() {
          isCivicIssue = true;
          issueName = detectedIssue;
          description = data['description'] ?? "";
          aiPriority = data['priority'] ?? "Low";
          aiConfidence = confidence * 100;
        });
      } else {
        _showInvalidIssueDialog();
      }
    } catch (_) {
      if (mounted) _showInvalidIssueDialog();
    }

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  void _showInvalidIssueDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Invalid Issue"),
        content: const Text(
            "This image is not recognized as a civic issue."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _issueImage = null;
                isCivicIssue = false;
              });
            },
            child: const Text("Re-upload"),
          ),
        ],
      ),
    );
  }

  void _showFakeImageDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Fake Image Detected"),
        content: const Text(
            "This image appears AI-generated or manipulated."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _issueImage = null;
                isCivicIssue = false;
              });
            },
            child: const Text("Re-upload"),
          ),
        ],
      ),
    );
  }

  Future<void> submitComplaint() async {
    if (!isCivicIssue || _issueImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Upload valid civic issue."),
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final imageUrl = await _uploadImage(_issueImage!);

      final currentUser = FirebaseAuth.instance.currentUser!;
      final uid         = currentUser.uid;
      final firebasePhone = currentUser.phoneNumber ?? '';
      final phone = firebasePhone.length > 10
          ? firebasePhone.substring(firebasePhone.length - 10)
          : firebasePhone;

      int? wardCode;
      String? wardName;
      try {
        final userData = await supabase
            .from('users')
            .select('location_code, location')
            .eq('phone', phone)
            .single();
        wardCode = userData['location_code'] as int?;
        wardName = userData['location'] as String?;
      } catch (_) {}

      final complaintId = _generateComplaintId();

      await supabase.from('complaints').insert({
        'phone':        phone,
        'user_id':      uid,
        'complaint_id': complaintId,
        'issue_name':   issueName,
        'description':  description,
        'priority':     aiPriority.toLowerCase(),
        'image_url':    imageUrl,
        'latitude':     _position?.latitude,
        'longitude':    _position?.longitude,
        'ward_code':    wardCode,
        'ward_name':    wardName,
        'status':       'open',
        'additional_comments': _additionalComments.trim().isEmpty ? null : _additionalComments.trim(),
      });

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SuccessScreen(complaintId: complaintId),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Submission failed")),
      );
    }

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
       body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 60, 20, 25),
            decoration: const BoxDecoration(
              color: Color(0xFF4A90E2),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(right: 48.0),
                      child: Text(
                        "Report Civic Issue",
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
            child: Stack(
              children: [
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(), 
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _imageCard(),
                      const SizedBox(height: 20),
                      if (_position != null) _locationCard(),
                      const SizedBox(height: 20),
                      _aiResultCard(),
                      const SizedBox(height: 20),
                      if (issueName.isNotEmpty) _additionalCommentsCard(),
                      const SizedBox(height: 30),
                      _submitButton(),
                    ],
                  ),
                ),
                if (isLoading)
                  Positioned.fill( 
                    child: Container(
                      color: Colors.black.withOpacity(0.35),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageCard() {
    return _card(
      child: Column(
        children: [
          const Text("Upload Issue Photo",
              style:
                  TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      pickIssueImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Camera"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      pickIssueImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo),
                  label: const Text("Gallery"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (_issueImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.file(
                _issueImage!,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
        ],
      ),
    );
  }

  Widget _locationCard() {
    return _card(
      child: Row(
        children: [
          const Icon(Icons.location_on,
              color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Lat: ${_position!.latitude.toStringAsFixed(5)}\n"
              "Lng: ${_position!.longitude.toStringAsFixed(5)}",
              style:
                  const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiResultCard() {
  if (issueName.isEmpty) return const SizedBox();

  final String priority =
      aiPriority.toString().toLowerCase();

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

  String displayPriority = priority.isNotEmpty
      ? priority[0].toUpperCase() + priority.substring(1)
      : "Low";

  return _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          issueName,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(description),
        const SizedBox(height: 10),
        Row(
          children: [
            _badge(displayPriority, priorityColor),
            const SizedBox(width: 10),
            Text(
              "Confidence: ${aiConfidence.toStringAsFixed(1)}%",
            ),
          ],
        ),
      ],
    ),
  );
}

  Widget _additionalCommentsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Additional Comments (Optional)",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _additionalCommentsController,
            maxLines: 3,
            maxLength: 300,
            onChanged: (v) => _additionalComments = v,
            decoration: InputDecoration(
              hintText: "Any extra details about the issue...",
              hintStyle: const TextStyle(color: Colors.black38),
              filled: true,
              fillColor: const Color(0xFFF4F7FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _submitButton() {
    bool enabled =
        issueName.isNotEmpty &&
        _issueImage != null &&
        isCivicIssue;

    return GestureDetector(
      onTap:
          enabled ? submitComplaint : null,
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(15),
          gradient: enabled
              ? const LinearGradient(
                  colors: [
                    Color(0xFF4A90E2),
                    Color(0xFF357ABD),
                  ],
                )
              : null,
          color: enabled
              ? null
              : Colors.grey.shade400,
        ),
        alignment: Alignment.center,
        child: const Text(
          "Submit Complaint",
          style: TextStyle(
              color: Colors.white,
              fontWeight:
                  FontWeight.bold),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
              horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black
                  .withOpacity(0.05),
              blurRadius: 10,
              offset:
                  const Offset(0, 6))
        ],
      ),
      child: child,
    );
  }
}