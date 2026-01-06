import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import '../util/core.dart';

class TestingTotal extends StatefulWidget {
  const TestingTotal({super.key});

  @override
  State<TestingTotal> createState() => _TestingTotalState();
}

class _TestingTotalState extends State<TestingTotal> {
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

        // Setelah Anda mendapatkan token, panggil fetchData untuk mengambil data makanan
        await fetchData();
      } else {
        // Handle error, misalnya, menampilkan pesan kesalahan
        print('Gagal mendapatkan token: ${response.statusCode}');
      }
    } catch (e) {
      // Handle exception, misalnya, menampilkan pesan kesalahan
      print('Gagal mendapatkan token: $e');
    }
  }

  Future<void> fetchData() async {
    try {
      final response = await http.get(
        Uri.parse(base_url + 'api/Makanan/konsumsi?id_user=36&waktu=2023-10-4'),
        headers: {
          'Authorization': 'Bearer $accessToken', // Menggunakan token akses
        },
      );  

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> makananList = data['response'];

        // Inisialisasi variabel total
        double totalBesaran = 0;

        // Iterasi melalui data makanan dan tambahkan besaran ke total
        for (var makanan in makananList) {
          final besaran = double.parse(makanan['energi']);
          totalBesaran += besaran;
        }
        int roundedTotal = totalBesaran.round();

        // Cetak total besaran
        print('Total Besaran: $totalBesaran');
        print(roundedTotal);
      } else {
        // Handle error, misalnya, menampilkan pesan kesalahan
        print('Gagal mengambil data dari API: ${response.statusCode}');
      }
    } catch (e) {
      // Handle exception, misalnya, menampilkan pesan kesalahan
      print('Gagal mengambil data dari API: $e');
    }
  }

  @override
void initState() {
  super.initState();
  getToken(); // fetchData dipanggil DI DALAM getToken()
}

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SingleChildScrollView(
          child: Center(
        child: Text('data'),
      )),
    );
  }
}
