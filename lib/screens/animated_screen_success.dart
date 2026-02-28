import 'package:flutter/material.dart';

class SuccessScreen extends StatefulWidget {
  const SuccessScreen({super.key});

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
                Navigator.of(context).popUntil((route) => route.isFirst);
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
            children: const [
              Icon(Icons.check_circle,
                  color: Colors.white,
                  size: 120),
              SizedBox(height: 20),
              Text("Complaint Submitted!",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold)),
            ],
          ),
        ),
      ),
        ]),
    );
  }
}