import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:isi_piringku/FAQ/listfaq.dart';
import 'package:isi_piringku/PedomanGizi/PdfPedomanGizi.dart';
import 'package:isi_piringku/util/colors.dart';
import 'package:page_transition/page_transition.dart';
import 'package:isi_piringku/Login/components/login_form.dart';
import 'package:isi_piringku/bloc/nav/bottom_nav.dart';
import 'package:isi_piringku/kalori/testingTotalKalori.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:isi_piringku/model/user.dart';

import 'package:isi_piringku/tambahDarah/tambahDarah.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../util/core.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  Map<String, dynamic>? forIMT;
  String imtText = '';
  String KeteranganImtText = '';

  List<dynamic> data = [];
  List<dynamic> articles = [];
  String Nama = '';
  String Email = '';

  String TB = '';
  String BB = '';
  String Id = '';
  String umur = '';

  @override
  void initState() {
    super.initState();
    loadUserData();
    fetchData();
    fetchData2();
    fetchData3();
  }

  Future<void> fetchData3() async {
    final response = await http.get(
      Uri.parse(base_url + 'api/DataUser/DataUser?id_user=36'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      forIMT = data['response'][0];

      final tinggiBadanCm = double.parse(forIMT!['tinggi_badan']);
      final beratBadanKg = double.parse(forIMT!['berat_badan']);

      final tinggiBadanM = tinggiBadanCm / 100;
      final imt = beratBadanKg / (tinggiBadanM * tinggiBadanM);

      imtText = '${imt.toStringAsFixed(2)}';
      double imtDouble = double.parse(imtText);
      if (imtDouble < 17.0) {
        KeteranganImtText = 'KURUS BERAT';
      } else if (imtDouble >= 17.0 && imtDouble <= 18.4) {
        KeteranganImtText = 'KURUS RINGAN';
      } else if (imtDouble >= 18.5 && imtDouble <= 25.0) {
        KeteranganImtText = 'NORMAL';
      } else if (imtDouble >= 25.1 && imtDouble <= 27.0) {
        KeteranganImtText = 'GEMUK RINGAN';
      } else if (imtDouble >= 27.1) {
        KeteranganImtText = 'GEMUK BERAT';
      }

      // ✅ Perbaikan: Cek mounted sebelum setState
      if (mounted) {
        setState(() {});
      }
    } else {
      throw Exception('Failed to load data from API');
    }
  }

  Future<void> fetchData2() async {
    final Uri apiUrl = Uri.parse(base_url + 'api/Artikel/getArtikel');
    final response = await http.get(apiUrl);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> responseList = data['response'];

      // ✅ Perbaikan: Cek mounted sebelum setState
      if (mounted) {
        setState(() {
          articles = responseList;
        });
      }
    } else {
      throw Exception('Failed to load data from API');
    }
  }

  Future<void> fetchData() async {
    final response =
        await http.get(Uri.parse(base_url + 'api/Gambar/getgambar'));
    if (response.statusCode == 200) {
      final decodedData = json.decode(response.body)['response'];

      // ✅ Perbaikan: Cek mounted sebelum setState
      if (mounted) {
        setState(() {
          data = decodedData;
        });
      }
    }
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');

    if (userDataString != null) {
      final userData = UserData.fromJson(json.decode(userDataString));
      print(userData.nama);

      // ✅ Perbaikan: Cek mounted sebelum setState
      if (mounted) {
        setState(() {
          Nama = userData.nama;
          Email = userData.email;
          TB = userData.tinggiBadan;
          BB = userData.beratBadan;
          Id = userData.idUser.toString();
          umur = userData.umur;
        });
      }
    }
  }

  Future<void> logoutUser() async {
    // Hapus token akses dari Shared Preferences
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('access_token');
    prefs.remove('user_data'); // Jika ada data pengguna lain yang perlu dihapus

    // Arahkan pengguna kembali ke halaman login
    Navigator.of(context).pushAndRemoveUntil(
      PageTransition(
        child: LoginForm(),
        type: PageTransitionType.fade,
        duration: const Duration(milliseconds: 500),
      ),
      (route) => false, // Hapus seluruh riwayat navigasi
    );
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      bottomNavigationBar: BottomNavBar(selected: 0),
      backgroundColor: BackgroundColor,
      body: ListView(
        children: [
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.only(left: 24),
            child: Text(
              'Hi, $Nama$Id',
              style: TextStyle(
                color: TextColordark,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Data Kesehatan Anda : ',
              style: TextStyle(
                color: PrimaryColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            child: Container(
              height: 150,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                          color: AccentColor.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(15.0),
                          boxShadow: [boxShadowPrimary]),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person,
                              color: TextColorLight,
                              size: 40,
                            ),
                            Text(
                              umur + ' Tahun',
                              style: TextStyle(
                                color: TextColorLight,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              'Umur\n',
                              style: TextStyle(
                                color: TextColorLight,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ]),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                          color: AccentColor.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(15.0),
                          boxShadow: [boxShadowPrimary]),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.height,
                              color: TextColorLight,
                              size: 40,
                            ),
                            Text(
                              TB + 'cm',
                              style: TextStyle(
                                color: TextColorLight,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              'Tinggi Badan',
                              style: TextStyle(
                                color: TextColorLight,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            child: Container(
              height: 150,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                          color: AccentColor.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(15.0),
                          boxShadow: [boxShadowPrimary]),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.monitor_weight_rounded,
                              color: TextColorLight,
                              size: 40,
                            ),
                            Text(
                              BB + 'kg',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              'Berat Badan',
                              style: TextStyle(
                                color: TextColorLight,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ]),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                          color: AccentColor.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(15.0),
                          boxShadow: [boxShadowPrimary]),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.fitness_center_rounded,
                              color: TextColorLight,
                              size: 40,
                            ),
                            forIMT == null
                                ? CircularProgressIndicator()
                                : Text(
                                    imtText,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                            Text(
                              KeteranganImtText,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              'IMT\n',
                              style: TextStyle(
                                color: TextColorLight,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ]),
                    ),
                  )
                ],
              ),
            ),
          ),
          SizedBox(height: 10),
          // === Perbaikan Visual: Ganti SingleChildScrollView horizontal dengan Text biasa ===
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Jaga Kesehatan Anda Dengan Menjaga Pola Makan Dan Olah Raga Yang Cukup',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          // === End Perbaikan ===
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              PageTransition(
                child: PdfPedomanGizi(),
                type: PageTransitionType.rightToLeft,
                duration: const Duration(milliseconds: 500),
              ),
            ),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                image: DecorationImage(
                  image: AssetImage('assets/images/sushi.png'),
                  fit: BoxFit.cover,
                ),
                boxShadow: [boxShadowPrimary],
              ),
              child: Container(
                padding: EdgeInsets.only(left: 8, right: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  color: Colors.black.withOpacity(0.6),
                ),
                child: Center(
                  child: Text(
                    "Pedoman Konsumsi Harian Seimbang Beragam",
                    style: TextStyle(
                      color: TextColorLight,
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Artikel Terbaru : ',
              style: TextStyle(
                color: PrimaryColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            height: 160,
            child: ListView.builder(
              itemCount: data.length,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (BuildContext context, int index) {
                List<List<Color>> gradients = [
                  [PrimaryColor, Colors.white],
                  [SecondaryColor, Colors.white],
                  [ThirdColor, Colors.white],
                  [PrimaryColor, Colors.white],
                  [SecondaryColor, Colors.white],
                ];

                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  width: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.0),
                    gradient: LinearGradient(
                      colors: gradients[index % gradients.length],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    // === Perbaikan Visual: Gunakan Stack + error handling ===
                    image: DecorationImage(
                      image: NetworkImage(data[index]['url']),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [boxShadowPrimary],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.0),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          data[index]['url'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                            );
                          },
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black54, Colors.transparent],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          left: 12,
                          right: 12,
                          child: Text(
                            data[index]['judul_artikel'],
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Informasi Nutrisi Makanan : ',
              style: TextStyle(
                color: PrimaryColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            height: size.height * 0.25,
            margin: EdgeInsets.symmetric(horizontal: 24),
            child: ListView.separated(
              itemCount: articles.length,
              separatorBuilder: (context, index) => SizedBox(height: 8),
              itemBuilder: (context, index) {
                final String imageUrl = articles[index]['gambar_artikel'];
                final String judul = articles[index]['judul'];

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: BackgroundColorWhite,
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [boxShadowWhite],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          width: 80,
                          height: 60,
                          fit: BoxFit.cover,
                          // === Perbaikan Visual: error handling ===
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 80,
                              height: 60,
                              color: Colors.grey[200],
                              child: Icon(Icons.image_not_supported, color: Colors.grey),
                            );
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          judul,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              PageTransition(
                child: ListFaq(),
                type: PageTransitionType.topToBottom,
                duration: const Duration(milliseconds: 500),
              ),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FAQ - Pusat Informasi : ',
                    style: TextStyle(
                      color: PrimaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: BackgroundColorWhite,
                      borderRadius: BorderRadius.circular(16.0),
                      boxShadow: [boxShadowWhite],
                    ),
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 50.0,
                          height: 50.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            image: DecorationImage(
                              image: AssetImage('assets/images/shusi.webp'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: Text(
                            'Memiliki Pertanyaan Seputar \nSEPIRINGQ?',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 30),
        ],
      ),
    );
  }
}