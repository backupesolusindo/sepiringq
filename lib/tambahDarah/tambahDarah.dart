import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import 'package:isi_piringku/bloc/nav/bottom_nav.dart';
import 'package:http/http.dart' as http;
import 'package:isi_piringku/util/colors.dart';
import 'package:isi_piringku/util/core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

import '../model/user.dart';

class InputDarah extends StatefulWidget {
  @override
  _InputDarahState createState() => _InputDarahState();
}

class _InputDarahState extends State<InputDarah> {
  String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String clientId = "PKL2023";
  String clientSecret = "PKLSERU";
  String txtNama = "";
  List<dynamic> arTambahDarah = [];

  // Simulated database (replace with your actual database implementation)
  List _database = [];
  String ID = '';
  bool _isBelumMinum = true;

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');

    if (userDataString != null) {
      final userData = UserData.fromJson(json.decode(userDataString));
      print(userData.nama);

      setState(() {
        ID = userData.idUser.toString();
        fetchDataDarah();
      });
    }
  }

  Future<void> _saveDataToDatabase(String status) async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');

    if (userDataString != null) {
      print(userDataString);
      final userData = UserData.fromJson(json.decode(userDataString));
      print(userData.nama);

      setState(() {
        ID = userData.idUser.toString();
      });
    }
    print(ID);

    final url = Uri.parse(base_url + 'API/Darah/darah');

    // Create a Map for the data to be sent
    final data = {
      "tanggal": currentDate,
      "id_user": ID,
      "status": status, // 'sudah' atau 'belum'
    };

    final response = await http.post(
      url,
      body: data, // Konversi objek data ke dalam bentuk JSON
    );

    if (response.statusCode == 200) {
      fetchDataDarah(); // Refresh data setelah simpan
      // Navigator.of(context).pop(); // Optional: kembali ke halaman sebelumnya
    } else {
      // Handle error here, e.g., show an error message to the user
      print('Error: ${response.statusCode}, ${response.body}');
    }
  }

  Future<void> fetchDataDarah() async {
    final Uri uri =
        Uri.parse(base_url + 'API/Darah/tambahdarahall?id_user=$ID');
    final response = await http.get(uri);

    arTambahDarah.clear();

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final responseList = jsonData['response'] as List;

      int no = 0;
      setState(() {
        var datenow = DateTime.now();
        var angkatgl = datenow.day.toString();
        var angkabln = datenow.month.toString();
        if (datenow.day < 10) {
          angkatgl = "0" + angkatgl.toString();
        }
        if (datenow.month < 10) {
          angkabln = "0" + angkabln.toString();
        }
        // ✅ Perbaikan: Gunakan format yyyy-MM-dd untuk pengecekan
        var tanggalHariIni = "${datenow.year}-${angkabln}-${angkatgl}";
        
        responseList.forEach((element) {
          arTambahDarah.add(element['tanggal']);
        });

        // ✅ Perbaikan: Bandingkan dengan format yang sama
        if (arTambahDarah.contains(tanggalHariIni)) {
          _isBelumMinum = false;
        }
        print("Belum Minum$tanggalHariIni");
      });
    } else {
      print(response.body);
    }
    print(arTambahDarah);
  }

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const BottomNavBar(selected: 4),
      appBar: AppBar(
        title: Text('Tambah Darah'),
        backgroundColor: SecondaryColor,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Container(
              width: MediaQuery.of(context).size.width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                'assets/images/calendar.png',
                                width: 30.0,
                                height: 30.0,
                              ),
                              SizedBox(
                                width: 10.0,
                              ),
                              Text(
                                'Tambah Darah Hari Ini',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          if (_isBelumMinum)
                            Container(
                              width: 400,
                              padding: EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 5,
                                    blurRadius: 7,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tanggal:',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    txtNama,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.deepOrange,
                                    ),
                                  ),
                                  Text(
                                    'Apakah anda sudah minum tablet tambah darah?',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      SizedBox(width: 70),
                                      ElevatedButton(
                                        onPressed: () {
                                          _saveDataToDatabase('sudah');
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                        ),
                                        child: Text('Sudah'),
                                      ),
                                      SizedBox(width: 30),
                                      ElevatedButton(
                                        onPressed: () {
                                          _saveDataToDatabase('belum');
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        child: Text('Belum'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              width: 400,
                              padding: EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 5,
                                    blurRadius: 7,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tanggal:',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    txtNama,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.deepOrange,
                                    ),
                                  ),
                                  Text(
                                    'Anda sudah mencatat minum tablet tambah darah hari ini.',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Silakan cek kembali di kalender.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Container(
                            margin: EdgeInsets.only(top: 20.0),
                            padding: EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 5,
                                  blurRadius: 7,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: TableCalendar(
                              locale: 'en_US',
                              firstDay: DateTime.utc(2010, 10, 16),
                              lastDay: DateTime.utc(2030, 3, 14),
                              focusedDay: DateTime.now(),
                              calendarFormat: CalendarFormat.month,
                              headerStyle: HeaderStyle(
                                formatButtonVisible: false,
                              ),
                              calendarStyle: CalendarStyle(
                                todayDecoration: BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                                selectedDecoration: BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              eventLoader: (day) {
                                var angkatgl = day.day.toString();
                                var angkabln = day.month.toString();
                                if (day.day < 10) {
                                  angkatgl = "0" + angkatgl.toString();
                                }
                                if (day.month < 10) {
                                  angkabln = "0" + angkabln.toString();
                                }
                                var tanggal = "${day.year}-${angkabln}-${angkatgl}";
                                if (arTambahDarah.contains(tanggal)) {
                                  return [Event('Event A'), Event('Event B')];
                                }
                                return [];
                              },
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Event {
  final String title;

  const Event(this.title);

  @override
  String toString() => title;
}