import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:smart_civic_connect/constants/location_constants.dart';
import 'package:smart_civic_connect/screens/login/login_screen.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  String? selectedLocation;
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF70C6FB), // Aavin top blue
              Colors.white,
            ],
            begin: FractionalOffset(0.0, 0.0),
            end: FractionalOffset(0.5, 0.5),
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Image.asset(
                    "images/logo1.png",
                    height: 140,
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    "Select Your Location",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Color.fromARGB(255, 3, 65, 174),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 40),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedLocation,
                      hint: const Text("Location"),
                      underline: Container(
                        height: 1,
                        color: Colors.grey,
                      ),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedLocation = newValue;
                        });
                      },
                      items: LocationConstants.locationNames
                      .map((location) => DropdownMenuItem(
                            value: location,
                            child: Text(location),
                          ))
                      .toList(),
                    ),
                  ),

                  const SizedBox(height: 60),

                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    height: 45,
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(15.0),
                        ),
                      ),
                      onPressed: () {
                        if (selectedLocation != null) {
                          _showConfirmationDialog();
                        } else {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            const SnackBar(
                              content:
                                  Text("Please select a location"),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        "Next",
                        style: TextStyle(
                            color: Colors.white, fontSize: 18),
                      ),
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

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Location"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'You have selected ',
                      style: TextStyle(fontSize: 16),
                    ),
                    TextSpan(
                      text: selectedLocation,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Note: This selection can’t be changed later.",
                style: TextStyle(
                  color: Colors.red,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(),
              child: const Text("No"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();

                Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => AuthScreen(
      location: selectedLocation!,
      locationCode: LocationConstants.locationCode[selectedLocation]!,
    ),
  ),
);

                if (kDebugMode) {
                  print("Selected Location: $selectedLocation");
                }
              },
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );
  }
}
