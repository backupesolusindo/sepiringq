import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:isi_piringku/util/core.dart';
import 'package:isi_piringku/util/colors.dart';

class ListFaq extends StatefulWidget {
  const ListFaq({Key? key}) : super(key: key);

  @override
  State<ListFaq> createState() => _ListFaqState();
}

class _ListFaqState extends State<ListFaq> {
  String clientId = "PKL2023";
  String clientSecret = "PKLSERU";
  String tokenUrl = base_url + "api/Token/token";
  String accessToken = "";

  Future<String> getToken() async {
    try {
      final response = await http.post(
        Uri.parse(tokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'client_credentials',
          'client_id': clientId,
          'client_secret': clientSecret,
        },
      );

      if (response.statusCode == 200) {
        final tokenData = jsonDecode(response.body);
        accessToken = tokenData['access_token'] ?? '';
        return accessToken;
      } else {
        throw Exception('Gagal ambil token: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error koneksi token: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchData(String token) async {
    final response = await http.get(
      Uri.parse(base_url + 'api/FAQ/getAllFAQ'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final data = body['response'];
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Data tidak valid: response bukan array');
      }
    } else if (response.statusCode == 401) {
      throw Exception('Token tidak valid');
    } else {
      final errorMsg = jsonDecode(response.body)['message'] ?? 'Gagal ambil data';
      throw Exception('Error: $errorMsg');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQ - Pusat Informasi'),
        backgroundColor: SecondaryColor,
      ),
      body: FutureBuilder<String>(
        future: getToken(),
        builder: (context, tokenSnapshot) {
          if (tokenSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (tokenSnapshot.hasError) {
            return _buildError('Gagal ambil token: ${tokenSnapshot.error}');
          }

          final token = tokenSnapshot.data!;
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: fetchData(token),
            builder: (context, faqSnapshot) {
              if (faqSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (faqSnapshot.hasError) {
                return _buildError('Gagal ambil FAQ: ${faqSnapshot.error}');
              }

              final faqData = faqSnapshot.data!;
              if (faqData.isEmpty) {
                return _buildEmpty();
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
                itemCount: faqData.length,
                itemBuilder: (context, index) {
                  final faq = faqData[index];
                  final pertanyaan = faq['pertanyaan'] ?? '';
                  final jawaban = faq['jawaban'] ?? '';
                  final no = index + 1;
                  return Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [boxShadow],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$no) $pertanyaan',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          jawaban,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildError(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Fluttertoast.showToast(
        msg: '❌ $message',
        backgroundColor: Colors.red,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
    });
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Gagal memuat FAQ. Silakan coba lagi nanti.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Belum ada pertanyaan yang tersedia.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}