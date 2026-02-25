import 'package:flutter/material.dart';
import 'package:smart_civic_connect/screens/homescreen.dart';
import 'package:smart_civic_connect/services/local_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class NameScreen extends StatefulWidget {
  final String phone;
  final String location;
  final int locationCode;

  const NameScreen({
    super.key,
    required this.phone,
    required this.location,
    required this.locationCode,
  });

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {

  final firstController = TextEditingController();
  final lastController = TextEditingController();

  bool loading = false;

  Future<void> saveUser() async {
    setState(() => loading = true);

    final supabase = Supabase.instance.client;

    try {
      await supabase.from('users').insert({
        'phone': widget.phone,
        'first_name': firstController.text.trim(),
        'last_name': lastController.text.trim(),
        'location': widget.location,
        'location_code': widget.locationCode,
      });

      await AppLocalStorage.saveLogin(widget.phone);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save user")),
      );
    }

    setState(() => loading = false);
  }

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
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [

                  /// 🔷 LOGO
                  Image.asset(
                    "images/logo.png",
                    height: 110,
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Complete Your Profile",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 30),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 35),
                    child: Column(
                      children: [

                        buildInputField(
                          controller: firstController,
                          hint: "First Name",
                        ),

                        const SizedBox(height: 20),

                        buildInputField(
                          controller: lastController,
                          hint: "Last Name",
                        ),

                        const SizedBox(height: 40),

                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: loading ? null : saveUser,
                            child: loading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text(
                                    "Continue",
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildInputField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }
}