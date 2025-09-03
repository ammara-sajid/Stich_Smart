import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tailors_app/add_customer_screen.dart';
import 'package:tailors_app/registration_screen.dart';
import 'package:tailors_app/welcome_splash_screen.dart';
import 'main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;


  /// **Check if user exists in Firestore**
  void checkUserExists(BuildContext context) async {
    String name = _nameController.text.trim();
    String password = _passwordController.text.trim(); // NEW

    if (name.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please enter both name and password',
            style: TextStyle(color: Colors.white),
          ),
          duration: const Duration(seconds: 2), // Timer: 3 seconds
          behavior: SnackBarBehavior.floating, // Makes it float above other widgets
          backgroundColor: Colors.grey[700], // Customize background
          shape: RoundedRectangleBorder( // Rounded corners
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
      return;
    }



    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('tailors')
          .where(Filter.or(
        Filter('fullName', isEqualTo: name),
        Filter('email', isEqualTo: name),
      ))
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var userDoc = querySnapshot.docs.first;
        String storedPassword = userDoc['password']; // Assuming password is stored

        if (password == storedPassword) {
          String fullName = userDoc['fullName'];
          String tailorId = userDoc.id;

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('loggedInUser', fullName);
          await prefs.setString('tailorId', tailorId);

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => WelcomeSplashScreen()),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Incorrect password', style: TextStyle(color: Colors.white)
            ),
              duration: Duration(seconds: 2), // Timer: 3 seconds
              behavior: SnackBarBehavior.floating, // Makes it float above other widgets
              backgroundColor: Colors.grey[700], // Customize background
              shape: RoundedRectangleBorder( // Rounded corners
                borderRadius: BorderRadius.circular(16),
              ),

            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not registered! Please register first.', style: TextStyle(color: Colors.white)
          ),duration: Duration(seconds: 2), // Timer: 3 seconds
            behavior: SnackBarBehavior.floating, // Makes it float above other widgets
            backgroundColor: Colors.grey[700], // Customize background
            shape: RoundedRectangleBorder( // Rounded corners
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}', style: TextStyle(color: Colors.white)
        ),duration: Duration(seconds: 2), // Timer: 3 seconds
          behavior: SnackBarBehavior.floating, // Makes it float above other widgets
          backgroundColor: Colors.grey[700], // Customize background
          shape: RoundedRectangleBorder( // Rounded corners
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Expanded(
            child: Center(
              child: CircleAvatar(
                radius: 120,
                backgroundImage: AssetImage('assets/image/Logo.png'),
              ),
            ),
          ),
          Column(
            children: [
              const Text(
                "Your smart tailoring assistant - Log in to get started!",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Username/email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  keyboardType: TextInputType.text,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),

                  keyboardType: TextInputType.text,
                ),
              ),

              const SizedBox(height: 10),

              // Start/Login Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: ElevatedButton(
                  onPressed: () {
                    checkUserExists(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Sign-in'),
                ),
              ),
              const SizedBox(height: 10),

              // Register Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => RegistrationScreen()
                        )
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text("Sign-Up"),
                ),
              ),
              const SizedBox(height: 25),
            ],
          ),
        ],
      ),
    );
  }
}
