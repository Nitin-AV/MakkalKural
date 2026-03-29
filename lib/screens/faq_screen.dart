import 'package:flutter/material.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final List<_FaqItem> _faqs = [
    _FaqItem(
      question: "What is Makkal Kural?",
      answer:
          "Makkal Kural (\"Voice of the People\") is a crowdsourced civic issue reporting platform. "
          "Citizens can photograph problems in their ward — potholes, broken streetlights, garbage dumps, water leaks, and more — "
          "and submit them directly to the responsible local authority for resolution.",
    ),
    _FaqItem(
      question: "How do I report a civic issue?",
      answer:
          "Tap the 'Report Civic Issue' button on the home screen. "
          "Take or select a photo of the problem. "
          "The app uses AI to automatically detect the type of issue, its priority level, and a description. "
          "Your GPS location is captured automatically. "
          "Optionally add any additional comments, then tap 'Submit Complaint'.",
    ),
    _FaqItem(
      question: "What happens after I submit a complaint?",
      answer:
          "Your complaint is logged with a unique Complaint ID and routed to the ward office based on your GPS location. "
          "An admin reviews the complaint and assigns a field worker to resolve it. "
          "You can track the status (Open → In Progress → Resolved) in real time from 'View Complaints'.",
    ),
    _FaqItem(
      question: "How does the AI detection work?",
      answer:
          "When you upload a photo, Makkal Kural sends it to an AI vision model that analyses the image and returns: "
          "the issue name (e.g., 'Pothole'), a description, a priority level (High / Medium / Low), "
          "and a confidence score. This saves you from typing and ensures accurate categorisation.",
    ),
    _FaqItem(
      question: "What do the complaint statuses mean?",
      answer:
          "• Open – Complaint submitted and awaiting assignment.\n"
          "• In Progress – A field worker has been assigned and is working on the issue.\n"
          "• Resolved – The issue has been fixed. You can review and rate the resolution.",
    ),
    _FaqItem(
      question: "How are priorities determined?",
      answer:
          "Priority is set automatically by the AI based on the severity of the issue detected in the photo:\n"
          "• High – Urgent safety hazards (e.g., exposed wires, large potholes on main roads).\n"
          "• Medium – Issues affecting daily life (e.g., overflowing drains, broken benches).\n"
          "• Low – Minor inconveniences (e.g., faded road markings, missing signage).",
    ),
    _FaqItem(
      question: "Can I submit multiple complaints for the same issue?",
      answer:
          "The app automatically filters duplicate complaints. If the same issue is detected more than once, "
          "only the most recent submission is shown in your list to keep things tidy. "
          "The underlying complaint is still tracked.",
    ),
    _FaqItem(
      question: "How will I know when my complaint is resolved?",
      answer:
          "You will receive an in-app notification when:\n"
          "• A worker is assigned to your complaint.\n"
          "• Your complaint status changes (e.g., marked as Resolved).\n"
          "• Your review is requested after resolution.\n"
          "Check the bell icon on any screen for new notifications.",
    ),
    _FaqItem(
      question: "How do I rate a resolved complaint?",
      answer:
          "Once your complaint is marked as Resolved, it appears under the 'Resolved' tab in 'View Complaints'. "
          "Tap 'Leave a Review' to give a star rating (1–5) and optional written feedback. "
          "Your feedback helps improve response quality.",
    ),
    _FaqItem(
      question: "What is the 'Additional Comments' field?",
      answer:
          "When reporting an issue, you can add up to 300 characters of extra context in the 'Additional Comments' field — "
          "for example, the exact landmark, time of occurrence, or any safety risk. "
          "This information is visible to the assigned field worker.",
    ),
    _FaqItem(
      question: "Is my location data shared?",
      answer:
          "Your GPS coordinates are used only to associate the complaint with the correct ward and to generate a Maps link for the field worker. "
          "Location data is never used for advertising or shared with third parties.",
    ),
    _FaqItem(
      question: "What if the AI misidentifies my issue?",
      answer:
          "The AI result (issue name, description, priority) is shown before you submit. "
          "If the detection looks incorrect, you should not submit — go back, retake the photo with better lighting and framing, and try again. "
          "More accurate photos lead to better AI results.",
    ),
    _FaqItem(
      question: "Who handles the complaints?",
      answer:
          "Complaints are reviewed and assigned by ward-level admins from the local governing body. "
          "Registered field workers are assigned to the complaint, travel to the location, fix the issue, "
          "and upload a completion photo as proof of resolution.",
    ),
    _FaqItem(
      question: "How do I contact support?",
      answer:
          "For technical issues or queries, please contact your ward office or reach out through the official helpline provided by your local authority. "
          "In-app support chat is coming in a future update.",
    ),
  ];

  final Set<int> _expanded = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 60, 20, 25),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4A90E2), Color(0xFF70C6FB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
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
                      padding: EdgeInsets.only(right: 48.0),
                      child: Text(
                        "Help & FAQ",
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

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: const [
                Icon(Icons.info_outline, color: Color(0xFF4A90E2), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Frequently asked questions about Makkal Kural",
                    style: TextStyle(
                        fontSize: 13, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: _faqs.length,
              itemBuilder: (context, i) {
                final faq = _faqs[i];
                final isOpen = _expanded.contains(i);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.10),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => setState(() {
                        if (isOpen) {
                          _expanded.remove(i);
                        } else {
                          _expanded.add(i);
                        }
                      }),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4A90E2)
                                        .withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Text(
                                      "Q",
                                      style: TextStyle(
                                        color: Color(0xFF4A90E2),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    faq.question,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Icon(
                                  isOpen
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                            if (isOpen) ...[
                              const SizedBox(height: 12),
                              const Divider(height: 1, color: Color(0xFFE0E0E0)),
                              const SizedBox(height: 12),
                              Text(
                                faq.answer,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  color: Colors.black87,
                                  height: 1.55,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});
}
