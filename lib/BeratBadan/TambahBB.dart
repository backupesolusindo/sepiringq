import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:isi_piringku/bloc/nav/bottom_nav.dart';
import 'package:isi_piringku/kalori/kalori.dart';
import 'package:isi_piringku/model/user.dart';
import 'package:isi_piringku/util/colors.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../util/core.dart';

class TambahBB extends StatefulWidget {
  const TambahBB({super.key});

  @override
  State<TambahBB> createState() => _TambahBBState();
}

class _TambahBBState extends State<TambahBB> {
  List<int> cardValues = [];
  List<Map<String, dynamic>> selectedFoods = [];

  TextEditingController beratbadanController = TextEditingController();
  List<Map<String, dynamic>> filteredFoodData = [];
  String clientId = "PKL2023";
  String clientSecret = "PKLSERU";
  String tokenUrl = base_url + "api/Token/token";
  String apiUrl = base_url + "api/BeratBadan/tambahBB";
  String accessToken = "";
  List<Map<String, dynamic>> foodData = [];
  bool isSearching = false;
  int cardValue = 0;
  String Id = '';

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');

    if (userDataString != null) {
      final userData = UserData.fromJson(json.decode(userDataString));
      print(userData.nama);

      setState(() {
        Id = userData.idUser.toString();
      });
    }
  }

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

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> kirimData() async {
    try {
      var response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id_user': Id,
          'beratbadan': beratbadanController.text,
        }),
      );

      print('Response Simpan Data');
      print(response.body);
      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: 'Berhasil Kirim Data',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        Navigator.pop(context);
      } else {
        print('Gagal mengirim data: ${response.statusCode}');
      }
    } catch (e) {
      print('Gagal mengirim data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tambah Berat Badan'),
        backgroundColor: SecondaryColor,
      ),
      // floatingActionButton: FloatingActionButton(
      //   tooltip: "Tambah Kalori",
      //   onPressed: () {
      //     kirimData();
      //   },
      //   child: Icon(Icons.save),
      //   backgroundColor: SecondaryColor,
      // ),
      body: SingleChildScrollView(
        child: Stack(children: [
          SafeArea(
            child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.0),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'Berapa Berat Badan Kamu Hari Ini?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(left: 20, right: 20),
                            child: TextFormField(
                              controller: beratbadanController,
                              keyboardType: TextInputType.number,
                              maxLength: 3,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                prefixIcon: Icon(Icons.sports_kabaddi),
                                suffixText: "Kg",
                                hintText: "Berat Badan Kamu ...",
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          GestureDetector(
                            onTap: () {
                              kirimData();
                            },
                            child: Container(
                              width: 120,
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: SecondaryColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.save,
                                      color: Colors.white,
                                    ),
                                    Text(
                                      'Simpan',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    )
                                  ]),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                )),
          ),
        ]),
      ),
    );
  }
}
