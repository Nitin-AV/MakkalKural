import 'package:flutter/material.dart';

class SuccessScreen extends StatefulWidget {
  final String? complaintId;
  const SuccessScreen({super.key, this.complaintId});

  @override
  State<SuccessScreen> createState() =>
      _SuccessScreenState();
}

class _SuccessScreenState
    extends State<SuccessScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this,
        duration:
            const Duration(milliseconds: 800))
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF4A90E2),
      body:
      Stack( 
        children: [
          Positioned(
            top: 60,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context, '/home', (_) => false);
              },
            ),
          ),
       Center(
        child: ScaleTransition(
          scale: CurvedAnimation(
              parent: _controller,
              curve: Curves.easeOutBack),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle,
                  color: Colors.white,
                  size: 120),
              const SizedBox(height: 20),
              const Text("Complaint Submitted!",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold)),
              if (widget.complaintId != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Your Complaint No.",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.complaintId!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
        ]),
    );
  }
}