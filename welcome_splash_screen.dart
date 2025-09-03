import 'package:flutter/material.dart';
import 'package:tailors_app/add_customer_screen.dart';
import 'package:tailors_app/home_screen.dart';

class WelcomeSplashScreen extends StatefulWidget {
  const WelcomeSplashScreen({super.key});

  @override
  State<WelcomeSplashScreen> createState() => _WelcomeSplashScreenState();
}

class _WelcomeSplashScreenState extends State<WelcomeSplashScreen> {
  void initState() {
    super.initState();
    // Add a 2-second delay then navigate to AddCustomerScreen
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(
        )),
      );
    });
  }
  @override

  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 100,
              backgroundImage: AssetImage('assets/image/Logo.png'),
            ),
            SizedBox(height: 20,),
            Text("Welcome to your Samrt Tailoring assistant!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20,),
            CircularProgressIndicator(
              color: Colors.black,
            ),
          ],
        ),
      ),
    );
  }
}
