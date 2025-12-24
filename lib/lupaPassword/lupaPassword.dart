import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:isi_piringku/Signup/signup_screen.dart';
import 'package:isi_piringku/components/already_have_an_account_acheck.dart';
import 'package:isi_piringku/components/constants.dart';
import 'package:isi_piringku/dashboard/dashboard.dart';
import 'package:isi_piringku/lupaPassword/inputPasswordBaru.dart';
import 'package:isi_piringku/lupaPassword/lupaPassword.dart';
import 'package:isi_piringku/model/user.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

import '../util/core.dart';

class Lupa extends StatefulWidget {
  const Lupa({
    Key? key,
  }) : super(key: key);

  @override
  State<Lupa> createState() => _LupaState();
}

class _LupaState extends State<Lupa> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _tglLahirController = TextEditingController();

  String clientId = "PKL2023";
  String clientSecret = "PKLSERU";
  String tokenUrl = base_url + "api/Token/token";

  String accessToken = "";
  late UserData userData;

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

  Future<void> _login() async {
    final String email = _emailController.text;
    final String tglLahir = _tglLahirController.text;

    await getToken(); // Memanggil fungsi getToken untuk mendapatkan token OAuth2

    // Membuat request body
    final Map<String, String> data = {
      "email": email,
      "tgl_lahir": tglLahir,
    };

    // Mengirim permintaan HTTP POST ke API dengan menyertakan token
    final response = await http.post(
      Uri.parse(base_url + 'api/Login/lupaPassword'),
      headers: {
        'Authorization':
            'Bearer $accessToken', // Menyertakan token dalam header
      },
      body: data,
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);

      // Simpan data pengguna ke SharedPreferences

      print(responseData);
      userData = UserData.fromJson(responseData['response']);
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('access_token', accessToken);
      // Simpan data pengguna lainnya jika diperlukan
      prefs.setString('user_data', json.encode(userData.toJson()));

      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => pasBaru(),
          ));
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
  void initState() {
    super.initState();
    // Ambil token saat halaman login dimuat
    getToken();

    // Periksa apakah token akses sudah ada
    // checkUserSession();
  }

  // Future<void> checkUserSession() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final savedAccessToken = prefs.getString('access_token');

  //   if (savedAccessToken != null) {
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(builder: (context) => Dashboard()),
  //     );
  //     // Token akses sudah ada, mungkin pengguna sudah masuk
  //     // Anda dapat memeriksa validitas token di sini
  //     // Misalnya, jika token kedaluwarsa, Anda dapat mengarahkan pengguna untuk logout
  //     // atau memperbarui token.
  //   }
  // }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lupa Password'),
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
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Masukan Email Anda'),
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: _tglLahirController,
              keyboardType: TextInputType.number,
              maxLength: 8,
              decoration: InputDecoration(
                  labelText: 'Tanggal Lahir Anda : 10122002 (ddmmyyyy)'),
            ),
            Container(
                child: ElevatedButton(
              onPressed: () {
                _login();
              },
              child: Text('Verifikasi'),
            ))
          ],
        ),
      ),
    );
  }
}
