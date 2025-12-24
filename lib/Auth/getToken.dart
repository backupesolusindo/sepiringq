import 'dart:convert';

import 'package:http/http.dart' as http;

import '../util/core.dart';

String clientId = "PKL2023";
String clientSecret = "PKLSERU";
String tokenUrl = base_url + "api/Token/token";

String accessToken = "";
List<Map<String, dynamic>> foodData = [];

Future<void> getToken() async {
  try {
    // Buat permintaan untuk mendapatkan token menggunakan client_credentials
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
      // Handle error, misalnya, menampilkan pesan kesalahan
      print('Gagal mendapatkan token: ${response.statusCode}');
    }
  } catch (e) {
    // Handle exception, misalnya, menampilkan pesan kesalahan
    print('Gagal mendapatkan token: $e');
  }
}
