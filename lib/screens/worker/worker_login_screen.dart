import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_civic_connect/screens/worker/worker_home_screen.dart';
import 'package:smart_civic_connect/services/local_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkerLoginScreen extends StatefulWidget {
  const WorkerLoginScreen({super.key});

  @override
  State<WorkerLoginScreen> createState() => _WorkerLoginScreenState();
}

class _WorkerLoginScreenState extends State<WorkerLoginScreen>
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

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
        vsync: this, duration: const Duration(seconds: 30));
  }

  @override
  void dispose() {
    phoneController.dispose();
    otpController.dispose();
    _timerController.dispose();
    super.dispose();
  }

  Future<void> sendOTP() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);

    await _auth.verifyPhoneNumber(
      phoneNumber: "+91${phoneController.text.trim()}",
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.message ?? "")));
          setState(() => loading = false);
        }
      },
      codeSent: (String verId, int? resendToken) {
        if (mounted) {
          setState(() {
            verificationId = verId;
            codeSent = true;
            loading = false;
          });
          _timerController.reset();
          _timerController.reverse(from: 1);
        }
      },
      codeAutoRetrievalTimeout: (String verId) {
        verificationId = verId;
      },
    );
  }

  Future<void> verifyOTP() async {
    if (otpController.text.trim().length != 6) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Enter valid OTP")));
      return;
    }

    try {
      setState(() => loading = true);

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpController.text.trim(),
      );

      await _auth.signInWithCredential(credential);

      final phone = phoneController.text.trim();
      final supabase = Supabase.instance.client;

      // Check workers table for this phone number
      final workerData = await supabase
          .from('workers')
          .select('id, name, phone, ward_name')
          .eq('phone', phone)
          .maybeSingle();

      if (workerData == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You are not registered as a worker. Contact admin."),
            backgroundColor: Colors.red,
          ),
        );
        await _auth.signOut();
        setState(() => loading = false);
        return;
      }

      await AppLocalStorage.saveWorkerLogin(phone, workerData['id'] as int);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => WorkerHomeScreen(workerData: workerData),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? "Invalid OTP")));
      }
    } finally {
      if (mounted) setState(() => loading = false);
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
            padding: const EdgeInsets.fromLTRB(20, 70, 20, 40),
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
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Worker Login",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Icon(Icons.engineering, color: Colors.white, size: 56),
                const SizedBox(height: 10),
                const Text(
                  "Field Worker Verification",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          Expanded(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : codeSent
                          ? _buildOtpWidget()
                          : _buildPhoneWidget(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Enter Your Registered Mobile Number",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 20),
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Row(
            children: [
              const Text("+91",
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  decoration: const InputDecoration(
                    counterText: "",
                    border: InputBorder.none,
                    hintText: "Enter mobile number",
                  ),
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
        ),
        const SizedBox(height: 40),
        _buildButton("Send OTP", sendOTP),
      ],
    );
  }

  Widget _buildOtpWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Enter OTP",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 20),
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: TextField(
            controller: otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              counterText: "",
              border: InputBorder.none,
              hintText: "Enter 6-digit OTP",
            ),
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
        _buildButton("Verify", verifyOTP),
      ],
    );
  }

  Widget _buildButton(String title, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 6,
        ),
        onPressed: onTap,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
