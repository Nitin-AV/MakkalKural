import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_civic_connect/screens/homescreen.dart';
import 'package:smart_civic_connect/screens/login/namescreen.dart';
import 'package:smart_civic_connect/services/local_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthScreen extends StatefulWidget {
  final String location;
  final int locationCode;

  const AuthScreen({
    super.key,
    required this.location,
    required this.locationCode,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with TickerProviderStateMixin {

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  String verificationId = "";
  bool codeSent = false;
  bool loading = false;

  late AnimationController _timerController;

  Duration get duration =>
      _timerController.duration! * _timerController.value;

  bool get expired => duration.inSeconds == 0;

  @override
  void initState() {
    super.initState();
    _timerController =
        AnimationController(vsync: this, duration: const Duration(seconds: 30));
  }

  @override
  void dispose() {
    phoneController.dispose();
    otpController.dispose();
    _timerController.dispose();
    super.dispose();
  }

  // ---------------- SEND OTP ----------------

  Future<void> sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    await _auth.verifyPhoneNumber(
      phoneNumber: "+91${phoneController.text.trim()}",
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message ?? "")));
        setState(() => loading = false);
      },
      codeSent: (String verId, int? resendToken) {
        setState(() {
          verificationId = verId;
          codeSent = true;
          loading = false;
        });

        _timerController.reset();
        _timerController.reverse(from: 1);
      },
      codeAutoRetrievalTimeout: (String verId) {
        verificationId = verId;
      },
    );
  }

  // ---------------- VERIFY OTP ----------------

 Future<void> verifyOTP() async {
  if (otpController.text.trim() != "123456") {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Invalid OTP")));
    return;
  }

  final phone = phoneController.text.trim();
  final supabase = Supabase.instance.client;

  final existingUser = await supabase
      .from('users')
      .select()
      .eq('phone', phone)
      .maybeSingle();

  if (existingUser == null) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NameScreen(
          phone: phone,
          location: widget.location,
          locationCode: widget.locationCode,
        ),
      ),
    );
  } else {
    await AppLocalStorage .saveLogin(phone);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }
}

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF70C6FB),
              Colors.white,
            ],
            begin: FractionalOffset(0.0, 0.0),
            end: FractionalOffset(0.5, 0.5),
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [

                    // 🔵 LOGO
                    Image.asset(
                      "images/logo.png",
                      height: 140,
                    ),

                    const SizedBox(height: 20),


                    const SizedBox(height: 30),

                    loading
                        ? const CircularProgressIndicator()
                        : codeSent
                            ? buildOtpWidget()
                            : buildPhoneWidget(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- PHONE UI ----------------

  Widget buildPhoneWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35),
      child: Column(
        children: [

          const Text(
            "Enter Registered Mobile Number",
            style: TextStyle(fontSize: 16),
          ),

          const SizedBox(height: 15),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              const SizedBox(
                width: 50,
                child: Text(
                  "+91",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
              ),

              const SizedBox(width: 15),

              SizedBox(
                width: 200,
                child: TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  textAlign: TextAlign.center,
                  decoration:
                      const InputDecoration(counterText: ""),
                  validator: (val) {
                    if (val == null || val.length != 10) {
                      return "Enter valid mobile number";
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          const Text(
            "OTP will be sent to your registered mobile number",
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          buildButton("Send OTP", sendOTP),
        ],
      ),
    );
  }

  // ---------------- OTP UI ----------------

  Widget buildOtpWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35),
      child: Column(
        children: [

          const Text(
            "Enter OTP",
            style: TextStyle(fontSize: 16),
          ),

          const SizedBox(height: 15),

          SizedBox(
            width: 220,
            child: TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              decoration:
                  const InputDecoration(counterText: ""),
            ),
          ),

          const SizedBox(height: 15),

          AnimatedBuilder(
            animation: _timerController,
            builder: (context, child) {
              return duration.inSeconds != 0
                  ? Text(
                      "Resend in 00:${duration.inSeconds.toString().padLeft(2, '0')}",
                      style: const TextStyle(color: Colors.red),
                    )
                  : TextButton(
                      onPressed: sendOTP,
                      child: const Text("Resend OTP"),
                    );
            },
          ),

          const SizedBox(height: 40),

          buildButton("Verify", verifyOTP),
        ],
      ),
    );
  }

  // ---------------- BUTTON ----------------

  Widget buildButton(String title, VoidCallback onTap) {
    return SizedBox(
      width: 250,
      height: 45,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: onTap,
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }
}
