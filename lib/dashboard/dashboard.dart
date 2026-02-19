// lib/kalori/dashboard.dart

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
import 'package:isi_piringku/model/user.dart';
import 'package:isi_piringku/tambahDarah/tambahDarah.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../util/core.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);
    loadUserData();
    fetchData();
    fetchData2();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// REFRESH DATA KETIKA KEMBALI KE HALAMAN INI
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('Dashboard resumed - refreshing data...');
      refreshData();
    }
  }

  /// FUNGSI UNTUK REFRESH DATA IMT
  Future<void> refreshData() async {
    await loadUserData();
    await fetchData3();
  }

  /// FUNGSI PERHITUNGAN IMT YANG DIPERBAIKI
  /// Rumus: IMT = Berat Badan (kg) / (Tinggi Badan (m))²
  double calculateIMT(double beratBadanKg, double tinggiBadanCm) {
    if (tinggiBadanCm <= 0 || beratBadanKg <= 0) {
      return 0.0;
    }
    
    final tinggiBadanM = tinggiBadanCm / 100;
    final imt = beratBadanKg / (tinggiBadanM * tinggiBadanM);
    
    // Validasi hasil IMT
    if (imt.isNaN || !imt.isFinite || imt <= 0 || imt > 100) {
      return 0.0;
    }
    
    return imt;
  }

  /// FUNGSI KATEGORI IMT YANG DIPERBAIKI
  String getIMTCategory(double imt) {
    if (imt <= 0 || imt.isNaN || !imt.isFinite) {
      return 'DATA TIDAK VALID';
    }
    
    if (imt < 18.5) {
      return 'KURUS'; // termasuk ringan & berat
    } else if (imt >= 18.5 && imt < 25.0) {
      return 'NORMAL';
    } else if (imt >= 25.0 && imt < 27.0) {
      return 'GEMUK';
    } else if (imt >= 27.0) {
      return 'OBESITAS'; // bukan "Gemuk Berat"
    }
    
    return 'DATA TIDAK VALID';
  }

  /// FUNGSI UNTUK MENDAPATKAN WARNA BERDASARKAN KATEGORI IMT
  Color getIMTColor(double imt) {
    if (imt <= 0 || imt.isNaN || !imt.isFinite) {
      return Colors.grey;
    }
    
    if (imt < 18.5) {
      // Kurus (biru)
      return Color(0xFF4FC3F7); // Light Blue
    } else if (imt >= 18.5 && imt < 25.0) {
      // Normal (hijau)
      return Color(0xFF66BB6A); // Green
    } else if (imt >= 25.0 && imt < 27.0) {
      // Gemuk (orange)
      return Color(0xFFFFA726); // Orange
    } else if (imt >= 27.0) {
      // Obesitas (merah)
      return Color(0xFFEF5350); // Red
    }
    
    return Colors.grey;
  }

  /// FETCH DATA IMT - MENGAMBIL DARI DATA USER YANG SUDAH AUTO-UPDATE
  /// Data ini akan otomatis terbaru karena di TambahBB.dart sudah auto-update ke data_user
  Future<void> fetchData3() async {
    if (Id.isEmpty) {
      print('ID user belum tersedia, menunggu loadUserData selesai');
      return;
    }

    try {
      print('Fetching data IMT untuk user ID: $Id');
      
      final response = await http.get(
        Uri.parse(base_url + 'api/DataUser/DataUser?id_user=$Id'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['response'] != null && data['response'].isNotEmpty) {
          forIMT = data['response'][0];

          // Ambil tinggi badan dan berat badan dari SharedPreferences (data terbaru)
          final prefs = await SharedPreferences.getInstance();
          final userDataString = prefs.getString('user_data');
          
          double tinggiBadanCm = 0.0;
          double beratBadanKg = 0.0;
          
          if (userDataString != null) {
            final userData = UserData.fromJson(json.decode(userDataString));
            tinggiBadanCm = double.tryParse(userData.tinggiBadan) ?? 0.0;
            beratBadanKg = double.tryParse(userData.beratBadan) ?? 0.0;
          }

          print('📊 Dashboard - Data Terbaru dari SharedPreferences:');
          print('   TB: $tinggiBadanCm cm');
          print('   BB: $beratBadanKg kg (dari SharedPreferences)');

          // Hitung IMT dengan data terbaru
          final imt = calculateIMT(beratBadanKg, tinggiBadanCm);
          
          if (imt > 0) {
            imtText = imt.toStringAsFixed(1);
            KeteranganImtText = getIMTCategory(imt);
            print('   IMT: $imtText');
            print('   Kategori: $KeteranganImtText');
            print('   Warna: ${getIMTColor(imt)}');
          } else {
            imtText = '-';
            KeteranganImtText = 'DATA TIDAK VALID';
            print('   ⚠️ IMT tidak valid');
          }

          // Update state untuk IMT saja, BB sudah diupdate di loadUserData
          if (mounted) {
            setState(() {
              // Tidak perlu update BB lagi, sudah diupdate di loadUserData
            });
          }
        } else {
          print('⚠️ Response kosong atau tidak ada data user');
        }
      } else {
        throw Exception('Failed to load data from API. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching IMT data: $e');
      if (mounted) {
        setState(() {
          imtText = '-';
          KeteranganImtText = 'ERROR';
        });
      }
    }
  }

  Future<void> fetchData2() async {
    try {
      final Uri apiUrl = Uri.parse(base_url + 'api/Artikel/getArtikel');
      final response = await http.get(apiUrl);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> responseList = data['response'];

        if (mounted) {
          setState(() {
            articles = responseList;
          });
        }
      } else {
        throw Exception('Failed to load articles from API');
      }
    } catch (e) {
      print('Error fetching articles: $e');
    }
  }

  Future<void> fetchData() async {
    try {
      final response =
          await http.get(Uri.parse(base_url + 'api/Gambar/getgambar'));
      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body)['response'];

        if (mounted) {
          setState(() {
            data = decodedData;
          });
        }
      }
    } catch (e) {
      print('Error fetching images: $e');
    }
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');

    if (userDataString != null) {
      final userData = UserData.fromJson(json.decode(userDataString));
      print('✅ User data loaded: ${userData.nama}, ID: ${userData.idUser}');

      if (mounted) {
        setState(() {
          Nama = userData.nama;
          Email = userData.email;
          TB = userData.tinggiBadan;
          BB = userData.beratBadan;
          Id = userData.idUser.toString();
          umur = userData.umur;
        });
        
        // Fetch data IMT setelah ID tersedia
        fetchData3();
      }
    }
  }

  Future<void> logoutUser() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('access_token');
    prefs.remove('user_data');

    Navigator.of(context).pushAndRemoveUntil(
      PageTransition(
        child: LoginForm(),
        type: PageTransitionType.fade,
        duration: const Duration(milliseconds: 500),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      bottomNavigationBar: BottomNavBar(selected: 0),
      backgroundColor: BackgroundColor,
      body: RefreshIndicator(
        onRefresh: refreshData,
        color: AccentColor,
        child: ListView(
          children: [
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.only(left: 24),
              child: Text(
                'Hi, $Nama',
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
                                TB + ' cm',
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
                                BB + ' kg',
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
                          // 👇 Warna container sekarang dinamis berdasarkan IMT
                          color: getIMTColor(double.tryParse(imtText) ?? 0.0),
                          borderRadius: BorderRadius.circular(15.0),
                          boxShadow: [boxShadowPrimary],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.fitness_center_rounded,
                              color: TextColorLight,
                              size: 40,
                            ),
                            SizedBox(height: 4),
                            forIMT == null
                                ? CircularProgressIndicator(
                                    color: TextColorLight,
                                  )
                                : Column(
                                    children: [
                                      Text(
                                        imtText,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: 4),
                                      // 🔹 Teks Keterangan IMT diletakkan di bawah IMT
                                      Text(
                                        KeteranganImtText,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                            SizedBox(height: 4),
                            Text(
                              'IMT',
                              style: TextStyle(
                                color: TextColorLight,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Jaga Kesehatan Anda Dengan Menjaga Pola Makan Dan Olah Raga Yang Cukup',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
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
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    width: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.0),
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
      ),
    );
  }
}