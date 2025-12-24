import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:isi_piringku/model/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../components/constants.dart';
import '../util/core.dart';

class pasBaru extends StatefulWidget {
  const pasBaru({super.key});

  @override
  State<pasBaru> createState() => _pasBaruState();
}

class _pasBaruState extends State<pasBaru> {
  String Id = '';
  final TextEditingController PasswordController = TextEditingController();
  final TextEditingController RePasswordController = TextEditingController();

  String clientId = "PKL2023";
  String clientSecret = "PKLSERU";
  String tokenUrl = base_url + "api/Token/token";

  String accessToken = "";

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');

    if (userDataString != null) {
      final userData = UserData.fromJson(json.decode(userDataString));
      print(userData.nama);

      setState(() {
        Id = userData.idUser.toString();
        print(Id);
      });
    }
  }

  Future<void> getToken() async {
    try {
      var response = await http.post(
        Uri.parse(tokenUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'client_credentials',
          'client_id': clientId,
          'client_secret': clientSecret,
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> tokenData = jsonDecode(response.body);
        accessToken = tokenData['access_token'];
        print('Token Akses: $accessToken');
      } else {
        print('Gagal mendapatkan token: ${response.statusCode}');
      }
    } catch (e) {
      print('Gagal mendapatkan token: $e');
    }
  }

  Future<void> _resetPass() async {
    if (PasswordController.text != RePasswordController.text) {
      Fluttertoast.showToast(
        msg: "Password tidak sama",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }
    await getToken(); // Memanggil fungsi getToken untuk mendapatkan token OAuth2

    // Membuat request body
    final Map<String, String> data = {
      "id_user": Id,
      "password": PasswordController.text,
    };

    // Mengirim permintaan HTTP POST ke API dengan menyertakan token
    final response = await http.post(
      Uri.parse(base_url + 'api/UpdatePassword/updatePassword'),
      headers: {
        'Authorization':
            'Bearer $accessToken', // Menyertakan token dalam header
      },
      body: data,
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);

      Navigator.pop(context);
    } else {
      final responseData = json.decode(response.body);

      if (responseData['response'] != null) {
        final errorMessage = 'username atau password salah';
        Fluttertoast.showToast(
          msg: errorMessage,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      } else {
        print('Gagal masuk: ${response.statusCode}');
        print('Pesan kesalahan: ${response.body}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reset Password'),
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/bg_login.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            TextFormField(
              controller: PasswordController,
              textInputAction: TextInputAction.done,
              obscureText: true,
              cursorColor: kPrimaryColor,
              decoration: InputDecoration(
                hintText: "Masukan Password Baru Anda",
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(defaultPadding),
                  child: Icon(Icons.lock),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: RePasswordController,
              textInputAction: TextInputAction.done,
              obscureText: true,
              cursorColor: kPrimaryColor,
              decoration: InputDecoration(
                hintText: "Masukan Ulang Password Baru Anda",
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(defaultPadding),
                  child: Icon(Icons.lock),
                ),
              ),
            ),
            Container(
                child: ElevatedButton(
              onPressed: () {
                _resetPass();
              },
              child: Text('Submit'),
            ))
          ],
        ),
      ),
    );
  }
}
