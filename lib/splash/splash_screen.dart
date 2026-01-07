import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isi_piringku/Login/login_screen.dart';
import 'package:isi_piringku/dashboard/dashboard.dart';
import 'package:isi_piringku/model/user.dart';
import 'package:isi_piringku/model/provider.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');

      // Delay untuk menampilkan splash screen sebentar
      await Future.delayed(const Duration(seconds: 2));

      if (userDataString != null && userDataString.isNotEmpty) {
        // User data ada, parse dan set ke provider
        final userDataJson = jsonDecode(userDataString);
        final userData = UserData.fromJson(userDataJson);

        // Update user provider
        if (mounted) {
          Provider.of<UserProvider>(context, listen: false)
              .updateUser(userData);

          // Redirect ke dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Dashboard()),
          );
        }
      } else {
        // User data tidak ada, redirect ke login
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    } catch (e) {
      print('Error checking login status: $e');
      // Jika ada error, redirect ke login
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo atau icon aplikasi
            Icon(
              Icons.restaurant_menu,
              size: 80,
              color: Colors.green[600],
            ),
            const SizedBox(height: 20),
            Text(
              'Isi Piringku',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green[600],
              ),
            ),
            const SizedBox(height: 40),
            // Loading indicator
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
            ),
          ],
        ),
      ),
    );
  }
}
