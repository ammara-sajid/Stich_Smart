import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tailors_app/add_customer_screen.dart';
import 'package:tailors_app/login_page.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _FormKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();


  Future<void> registerUser() async {
    if (_FormKey.currentState!.validate()) {
      try {
        print("Trying to create user...");
        UserCredential userCredential =
        await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        await userCredential.user!.reload();
        User? user = _auth.currentUser;

        print("Saving user data to Firestore...");
        await _firestore
            .collection('tailors')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .set({
          'fullName': _fullNameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'uid': userCredential.user!.uid,
          'password':_passwordController.text.trim(),

        });


        print("User data saved!");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User Registered Successfully!',  style: TextStyle(color: Colors.white),
            ),duration: const Duration(seconds: 2), // Timer: 3 seconds
              behavior: SnackBarBehavior.floating, // Makes it float above other widgets
              backgroundColor: Colors.grey[700], // Customize background
              shape: RoundedRectangleBorder( // Rounded corners
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );

          await Future.delayed(const Duration(seconds: 1));

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginPage(
            )),
          );
        }

      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('This email is already registered.', style: TextStyle(color: Colors.white),),
              duration: const Duration(seconds: 2), // Timer: 3 seconds
              behavior: SnackBarBehavior.floating, // Makes it float above other widgets
              backgroundColor: Colors.grey[700], // Customize background
              shape: RoundedRectangleBorder( // Rounded corners
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
          return;
        } else if (e.code == 'invalid-email') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid email format.', style: TextStyle(color: Colors.white),),
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
        else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.message}')),
          );
        }

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields correctly', style: TextStyle(color: Colors.white),),
          duration: const Duration(seconds: 2), // Timer: 3 seconds
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
      appBar: AppBar(
        title: const Text('Registration Form'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,

      ),
      body: Form(
        key: _FormKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            SingleChildScrollView(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: ListView(
                  children: [
                    const SizedBox(
                      height: 40,
                    ),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: InputDecoration(

                        labelText: 'Full Name',
                        labelStyle:
                            const TextStyle(color: Colors.black, fontSize: 18),
                        hintText: "Enter your full name!",
                        hintStyle:
                            const TextStyle(fontSize: 13, color: Colors.grey),
                        errorStyle: TextStyle(color: Colors.grey[800]),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide:
                                const BorderSide(color: Colors.grey, width: 2)),


                      ),
                      keyboardType: TextInputType.text,
                      style: TextStyle(color: Colors.grey[800]),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "This field is required"; // Validator message appears if field is empty
                        }
                        return null;
                      },
                    ),
                    const SizedBox(
                      height: 25,
                    ),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle:
                            const TextStyle(color: Colors.black, fontSize: 18),
                        hintText: "Enter your email!",
                        hintStyle:
                            const TextStyle(fontSize: 13, color: Colors.grey),
                        errorStyle: TextStyle(color: Colors.grey[800]),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide:
                                const BorderSide(color: Colors.grey, width: 2)),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "This field is required"; // Validator message appears if field is empty
                        }
                        return null;
                      },
                    ),
                    const SizedBox(
                      height: 25,
                    ),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'PhoneNumber',
                        labelStyle:
                            const TextStyle(color: Colors.black, fontSize: 18),
                        hintText: "Enter your phoneNumber!",
                        hintStyle:
                            const TextStyle(fontSize: 13, color: Colors.grey),
                        errorStyle: TextStyle(color: Colors.grey[800]),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide:
                                BorderSide(color: Colors.grey, width: 2)),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "This field is required"; // Validator message appears if field is empty
                        }
                        return null;
                      },
                    ),
                    const SizedBox(
                      height: 25,
                    ),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: const TextStyle(color: Colors.black, fontSize: 18),
                        hintText: "Enter 6 character password!",
                        hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                        errorStyle: TextStyle(color: Colors.grey[800]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.grey, width: 2),
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
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.black),
                      validator: (value) =>
                      value!.length < 6 ? 'Password must be at least 6 characters' : null,
                    ),

                    const SizedBox(
                      height: 25,
                    ),
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        labelStyle:
                            const TextStyle(color: Colors.black, fontSize: 18),
                        hintText: "Confirm your password!",
                        hintStyle:
                            const TextStyle(fontSize: 13, color: Colors.grey),
                        errorStyle: TextStyle(color: Colors.grey[800]),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide:
                                BorderSide(color: Colors.grey, width: 2)
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      keyboardType: TextInputType.text,
                      obscureText: _obscureConfirmPassword,
                      style: const TextStyle(color: Colors.black),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(
                      height: 120,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: registerUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder( // Shape
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Complete Sign_up'),
              ),

            ),
            SizedBox(height: 10,)
          ],
        ),
      ),
    );
  }
}
