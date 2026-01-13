// lib/kalori/kalori.dart
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:isi_piringku/bloc/nav/bottom_nav.dart';
import 'package:isi_piringku/kalori/tambah.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:isi_piringku/model/user.dart';
import 'package:isi_piringku/util/colors.dart';
import 'package:isi_piringku/util/core.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Kalori extends StatefulWidget {
  const Kalori({super.key});

  @override
  State<Kalori> createState() => _KaloriState();
}

class _KaloriState extends State<Kalori> {
  List<dynamic> articles2 = [];
  final Map<String, List<Map<String, dynamic>>> groupedData = {};
  bool isLoading = false;
  bool isLoadingJadwal = false;
  bool isLoadingKonsumsi = false;
  bool isLoadingGrafik = false;
  bool isLoadingIsiPiringku = false;
  double totalEnergi = 0.0;
  String Id = '';
  String KebutuhanKalori = '0';
  String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  DateTime selectedDate = DateTime.now();
  String clientId = "PKL2023";
  String clientSecret = "PKLSERU";
  String umur = "-";

  // AKG comparison data
  Map<String, dynamic> akgData = {};
  bool showAkgComparison = false;

  // User data
  Map<String, dynamic> userData = {};

  // Isi Piringku data
  Map<String, dynamic> isiPiringkuData = {};

  @override
  void initState() {
    super.initState();
    loadUserDataAndFetchData();
  }

  // ✅ NEW: Get age-based portion recommendations
  Map<String, double> getAgeBasedPortions(int age) {
    if (age >= 4 && age <= 6) {
      // ✅ UNTUK ANAK 4-6 TAHUN: Buah dan Sayur DIGABUNG
      return {
        'makanan_pokok_percent': 35.0,
        'lauk_pauk_percent': 35.0,
        'buah_sayur_percent': 30.0, // Buah & Sayur digabung
        'makanan_pokok': 150.0,
        'lauk_pauk': 75.0,
        'buah_sayur': 125.0, // Gabungan buah dan sayur
        'is_child': 1.0, // Flag untuk menandakan anak kecil
      };
    } else if (age >= 7 && age <= 12) {
      // Anak 7-12 tahun: terpisah seperti sebelumnya
      return {
        'makanan_pokok': 150.0,
        'lauk_pauk': 75.0,
        'sayuran': 100.0,
        'buah_buahan': 150.0,
        'makanan_pokok_percent': 31.6,
        'lauk_pauk_percent': 15.8,
        'sayuran_percent': 21.1,
        'buah_buahan_percent': 31.6,
        'is_child': 0.0,
      };
    } else {
      // Remaja & Dewasa (13+)
      return {
        'makanan_pokok': 175.0,
        'lauk_pauk': 87.5,
        'sayuran': 175.0,
        'buah_buahan': 175.0,
        'makanan_pokok_percent': 28.5,
        'lauk_pauk_percent': 14.3,
        'sayuran_percent': 28.5,
        'buah_buahan_percent': 28.5,
        'is_child': 0.0,
      };
    }
  }

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: PrimaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: PrimaryColor),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
      });
      if (Id.isNotEmpty) {
        await refreshAllData();
      }
    }
  }

  Future<void> fetchData2() async {
    setState(() {
      isLoadingJadwal = true;
    });
    try {
      final Uri apiUrl2 = Uri.parse(base_url + 'API/JadwalMakan/jadwal');
      final response = await http.get(apiUrl2);
      print("🔵 Response Jadwal Makanan");
      print(response.body);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> responseList = data['response'];
        setState(() {
          articles2 = responseList;
        });
        print('✅ Jadwal loaded: ${articles2.length} items');
      } else {
        throw Exception('Failed to load data from API');
      }
    } catch (e) {
      print('❌ Error fetching jadwal: $e');
    } finally {
      setState(() {
        isLoadingJadwal = false;
      });
    }
  }

  Future<void> loadUserDataAndFetchData() async {
    await loadUserData();
    if (Id.isNotEmpty) {
      await refreshAllData();
    }
  }

  Future<void> refreshAllData() async {
    print('🔄 Refreshing all data...');
    await Future.wait([
      fetchData(),
      fetchData2(),
    ]);
    print('✅ All data refreshed');
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');

    if (userDataString != null) {
      final userData = UserData.fromJson(json.decode(userDataString));
      print('✅ User loaded: ${userData.nama}');

      setState(() {
        Id = userData.idUser.toString();
      });
    } else {
      print('⚠️ User data not found');
    }
  }

  List<dynamic> data = [];

  Future<void> fetchData() async {
    if (Id.isEmpty) {
      print('⚠️ Cannot fetch data: Id is empty');
      return;
    }

    setState(() {
      isLoading = true;
    });
    try {
      print('🔵 Fetching konsumsi for user: $Id, date: $formattedDate');
      String fetkal = base_url + "API/Makanan/konsumsi?id_user=$Id&waktu=$formattedDate";
      final response = await http.get(
        Uri.parse(fetkal),
      );

      print("🔵 Response Konsumsi");
      print(response.body);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print('✅ Konsumsi response received');

        setState(() {
          data = jsonResponse['response'];
          print('📊 Total food items: ${data.length}');

          data.forEach((item) {
            print('  - ${item['nama_makanan']} (${item['keterangan']}) = ${item['kalori']} kkal');
          });

          KebutuhanKalori = jsonResponse['dataUser']['kalori'].toString();
          if (jsonResponse['dataUser']['akg'] != null) {
            akgData = jsonResponse['dataUser']['akg'];
            showAkgComparison = true;
          }
          if (jsonResponse['dataUser']['user'] != null) {
            userData = jsonResponse['dataUser']['user'];
          }
          if (jsonResponse['dataUser']['umur'] != null) {
            umur = jsonResponse['dataUser']['umur'].toString();
          }
          totalEnergi = data
              .map((item) => double.parse(item['kalori']))
              .fold(0.0, (prev, curr) => prev + curr);

          print('✅ Total energi: $totalEnergi kkal');
        });
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching konsumsi: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  List<dynamic> dataKonsumsi = [];

  Future<void> fetchDataKonsumsi(String keterangan) async {
    if (Id.isEmpty) {
      return;
    }

    setState(() {
      isLoadingKonsumsi = true;
    });
    try {
      print('🔵 Fetching detail for: $keterangan');
      String fetkal = base_url + "API/Makanan/konsumsi?id_user=$Id&waktu=$formattedDate&keterangan=$keterangan";
      final response = await http.get(
        Uri.parse(fetkal),
      );

      print("🔵 Response Konsumsi Keterangan: $keterangan");
      print(response.body);
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        setState(() {
          dataKonsumsi = jsonResponse['response'];
          print('✅ Detail items: ${dataKonsumsi.length}');

          dataKonsumsi.forEach((item) {
            print('  Food: ${item['nama_makanan']}');
            print('    - kuantitas/jumlah: ${item['kuantitas'] ?? item['jumlah'] ?? item['qty'] ?? 'N/A'}');
            print('    - Available keys: ${item.keys.toList()}');
          });

          isLoadingKonsumsi = false;
          showMaterialModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (context) => mDetailKalori(),
          );
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('❌ Error fetching konsumsi detail: $e');
      setState(() {
        isLoadingKonsumsi = false;
      });
    }
  }

  Map<String, double> dataMap = {};
  double totalKaloriKonsumsi = 0;
  int totalKebutuhanKonsumsi = 0;
  int persentaseKecukupanKalori = 0;
  String keteranganKalori = "";

  Future<void> fetchGrafikKonsumsi(String keterangan) async {
    totalKaloriKonsumsi = 0;
    if (Id.isEmpty) {
      return;
    }

    setState(() {
      isLoadingGrafik = true;
    });
    try {
      print('🔵 Fetching grafik for: $keterangan');
      String fetkal = base_url + "API/Makanan/kalorikonsumsi?id_user=$Id&waktu=$formattedDate&keterangan=$keterangan";
      final response = await http.get(
        Uri.parse(fetkal),
      );

      print("🔵 Response Konsumsi Grafik: $keterangan");
      print(response.body);
      double totalKarbohidrat = 0;
      double totalLemak = 0;
      double totalProtein = 0;
      double totalZatBesi = 0;
      double totalVitaminA = 0;
      double totalVitaminC = 0;
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        dataKonsumsi = jsonResponse['response'];
        setState(() {
          dataKonsumsi.forEach((item) {
            totalKarbohidrat += double.parse(item['karbohidrat']);
            totalLemak += double.parse(item['lemak']);
            totalProtein += double.parse(item['protein']);
            totalZatBesi += double.parse(item['besi']);
            totalVitaminA += double.parse(item['vitamina']);
            totalVitaminC += double.parse(item['vitaminc']);
            totalKaloriKonsumsi += double.parse(item['kalori']);
          });
          totalKarbohidrat = double.parse(totalKarbohidrat.toStringAsFixed(2));
          totalLemak = double.parse(totalLemak.toStringAsFixed(2));
          totalProtein = double.parse(totalProtein.toStringAsFixed(2));
          totalZatBesi = double.parse(totalZatBesi.toStringAsFixed(2));
          totalVitaminA = double.parse(totalVitaminA.toStringAsFixed(2));
          totalVitaminC = double.parse(totalVitaminC.toStringAsFixed(2));
          totalKebutuhanKonsumsi = int.parse(jsonResponse['datauser']['konsumsi_kalori'].toString());
          persentaseKecukupanKalori = int.parse(jsonResponse['datauser']['persentase_kalori'].toString());
          keteranganKalori = jsonResponse['datauser']['keterangan'];
          dataMap = {
            "Total Karbohidrat : $totalKarbohidrat": totalKarbohidrat,
            "Total Lemak : $totalLemak": totalLemak,
            "Total Protein : $totalProtein": totalProtein,
            "Total Zat Besi : $totalZatBesi": totalZatBesi,
            "Total Vitamin A : $totalVitaminA": totalVitaminA,
            "Total Vitamin C : $totalVitaminC": totalVitaminC,
          };
          print('✅ Grafik loaded');
          isLoadingGrafik = false;
          showMaterialModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (context) => mGrafikKalori(),
          );
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('❌ Error fetching grafik: $e');
      setState(() {
        isLoadingGrafik = false;
      });
    }
  }

  // ✅ UPDATED: Fetch Isi Piringku data using GRAM (besaran) instead of kalori
  Future<void> fetchIsiPiringku(String keterangan) async {
    if (Id.isEmpty) {
      return;
    }

    setState(() {
      isLoadingIsiPiringku = true;
    });
    try {
      print('🔵 Fetching Isi Piringku for: $keterangan');
      String fetkal = base_url + "API/Makanan/konsumsi?id_user=$Id&waktu=$formattedDate&keterangan=$keterangan";
      final response = await http.get(
        Uri.parse(fetkal),
      );

      print("🔵 Response Isi Piringku: $keterangan");
      print(response.body);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final List<dynamic> konsumsiList = jsonResponse['response'];

        int userAge = 20; // default
        if (jsonResponse['dataUser'] != null && jsonResponse['dataUser']['umur'] != null) {
          userAge = int.tryParse(jsonResponse['dataUser']['umur'].toString()) ?? 20;
        }
        print('👤 User age: $userAge');

        // Group by category and calculate GRAM (besaran) not kalori
        Map<String, List<Map<String, dynamic>>> groupedByCategory = {};
        double makananPokokGram = 0;
        double laukPaukGram = 0;
        double buahBuahanGram = 0;
        double sayuranGram = 0;
        double buahSayurGram = 0; // ✅ NEW: Gabungan buah dan sayur untuk anak 4-6 tahun

        for (var item in konsumsiList) {
          String kategori = (item['nama_kategori'] ?? '').toString().toLowerCase();

          double besaran = 0;

          if (item['besaran'] != null) {
            besaran = double.tryParse(item['besaran'].toString()) ?? 0;
          } else if (item['berat'] != null) {
            besaran = double.tryParse(item['berat'].toString()) ?? 0;
          } else if (item['gram'] != null) {
            besaran = double.tryParse(item['gram'].toString()) ?? 0;
          } else if (item['ukuran'] != null) {
            besaran = double.tryParse(item['ukuran'].toString()) ?? 0;
          }

          int quantity = int.tryParse((item['kuantitas'] ?? item['jumlah'] ?? item['qty'] ?? '1').toString()) ?? 1;

          besaran = besaran * quantity;

          print('  - ${item['nama_makanan']}: $besaran gram (kategori: $kategori)');

          if (kategori.contains('karbo') || kategori.contains('pokok')) {
            makananPokokGram += besaran;
          } else if (kategori.contains('lauk')) {
            laukPaukGram += besaran;
          } else if (kategori.contains('buah')) {
            buahBuahanGram += besaran;
            buahSayurGram += besaran; // ✅ Add to combined for children
          } else if (kategori.contains('sayur')) {
            sayuranGram += besaran;
            buahSayurGram += besaran; // ✅ Add to combined for children
          }

          if (!groupedByCategory.containsKey(kategori)) {
            groupedByCategory[kategori] = [];
          }
          groupedByCategory[kategori]!.add(item as Map<String, dynamic>);
        }

        setState(() {
          isiPiringkuData = {
            'makanan_pokok': makananPokokGram,
            'lauk_pauk': laukPaukGram,
            'buah_buahan': buahBuahanGram,
            'sayuran': sayuranGram,
            'buah_sayur': buahSayurGram, // ✅ NEW: Combined for children
            'grouped_data': groupedByCategory,
            'total_gram': makananPokokGram + laukPaukGram + buahBuahanGram + sayuranGram,
            'user_age': userAge,
          };

          print('✅ Isi Piringku loaded (GRAM)');
          print('   Makanan Pokok: $makananPokokGram gram');
          print('   Lauk Pauk: $laukPaukGram gram');
          print('   Buah-buahan: $buahBuahanGram gram');
          print('   Sayuran: $sayuranGram gram');
          print('   Buah+Sayur (combined): $buahSayurGram gram'); // ✅ NEW
          print('   User age: $userAge tahun');

          isLoadingIsiPiringku = false;
          showMaterialModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (context) => mIsiPiringku(),
          );
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('❌ Error fetching Isi Piringku: $e');
      setState(() {
        isLoadingIsiPiringku = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      bottomNavigationBar: const BottomNavBar(selected: 1),
      body: SingleChildScrollView(
        child: Stack(children: [
          Container(
            height: 130,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/head2.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Container(
                width: MediaQuery.of(context).size.width,
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(padding: EdgeInsets.only(top: 64)),
                        const SizedBox(height: 20),
                        Center(
                          child: Container(
                            width: MediaQuery.of(context).size.height * 0.4,
                            height: 30,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color.fromARGB(255, 250, 154, 0),
                                  Color.fromARGB(255, 246, 80, 20),
                                  Color.fromARGB(255, 235, 38, 16),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: kElevationToShadow[1],
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 0,
                            ),
                            child: const Center(
                              child: Text(
                                'Kalori Harian',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Container(
                          padding: const EdgeInsets.only(left: 15),
                          child: Row(children: [
                            IconButton(
                              icon: const Icon(
                                Icons.calendar_month,
                                color: Colors.redAccent,
                                size: 30,
                              ),
                              onPressed: () => selectDate(context),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                alignment: Alignment.center,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  formattedDate,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 30),
                        // Budget Kalori Section
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 15),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [boxShadow],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Budget Kalori Harian',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$KebutuhanKalori Kkal',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                alignment: Alignment.center,
                                height: 50,
                                width: 100,
                                decoration: BoxDecoration(
                                    color: SecondaryColor,
                                    borderRadius: BorderRadius.circular(10)),
                                child: isLoading
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        "${totalEnergi.toInt()} Kkal",
                                        style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center,
                                      ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // AKG Comparison Widget
                        if (showAkgComparison) ...[
                          Row(
                            children: [
                              // Calorie Status Box
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.only(left: 15, right: 7.5),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color.fromARGB(255, 250, 154, 0),
                                        Color.fromARGB(255, 246, 80, 20),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [boxShadow],
                                  ),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'Status Kalori',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 6,
                                              offset: Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '${akgData['kalori_persen']}%',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: _getStatusColor(int.parse(akgData['kalori_persen'].toString())),
                                                ),
                                              ),
                                              Text(
                                                _getStatusText(int.parse(akgData['kalori_persen'].toString())),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: _getStatusColor(int.parse(akgData['kalori_persen'].toString())),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        '${akgData['kalori_kons']} / ${akgData['energi']}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        'kkal',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // User Data Box
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.only(left: 7.5, right: 15),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [boxShadow],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Data Pengguna',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      if (userData.isNotEmpty) ...[
                                        _buildUserDataRow('Nama', userData['nama'] ?? '-'),
                                        _buildUserDataRow('Umur', '${umur} tahun'),
                                        _buildUserDataRow('Tinggi', '${userData['tinggi_badan'] ?? '-'} cm'),
                                        _buildUserDataRow('Berat', '${userData['berat_badan'] ?? '-'} kg'),
                                        _buildUserDataRow('Jenis Kelamin', userData['jekel'] ?? '-'),
                                        _buildUserDataRow(
                                          'IMT',
                                          userData['nilai_imt'] ?? 'Belum dihitung',
                                        ),
                                      ] else ...[
                                        Text(
                                          'Data pengguna tidak tersedia',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Other Nutrients
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 15),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [boxShadow],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Status Nutrisi Lainnya',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildNutritionBarWithStatus(
                                  'Karbohidrat',
                                  '${akgData['karbohidrat_kons']} / ${akgData['karbohidrat']} g',
                                  int.parse(akgData['karbohidrat_persen'].toString()),
                                  Colors.blue,
                                ),
                                _buildNutritionBarWithStatus(
                                  'Protein',
                                  '${akgData['protein_kons']} / ${akgData['protein']} g',
                                  int.parse(akgData['protein_persen'].toString()),
                                  Colors.green,
                                ),
                                _buildNutritionBarWithStatus(
                                  'Lemak',
                                  '${akgData['lemak_kons']} / ${akgData['lemak']} g',
                                  int.parse(akgData['lemak_persen'].toString()),
                                  Colors.red,
                                ),
                                _buildNutritionBarWithStatus(
                                  'Zat Besi',
                                  '${akgData['besi_kons']} / ${akgData['besi']} mg',
                                  int.parse(akgData['besi_persen'].toString()),
                                  Colors.brown,
                                ),
                                _buildNutritionBarWithStatus(
                                  'Vitamin A',
                                  '${akgData['vitamina_kons']} / ${akgData['vitamina']} mcg',
                                  int.parse(akgData['vitamina_persen'].toString()),
                                  Colors.purple,
                                ),
                                _buildNutritionBarWithStatus(
                                  'Vitamin C',
                                  '${akgData['vitaminc_kons']} / ${akgData['vitaminc']} mg',
                                  int.parse(akgData['vitaminc_persen'].toString()),
                                  Colors.cyan,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        // Meal Schedule Section
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Jadwal Makan Hari Ini',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                height: 350,
                                child: isLoadingJadwal
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            CircularProgressIndicator(),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Memuat jadwal makan...',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : articles2.isEmpty
                                        ? Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.restaurant_menu,
                                                  size: 48,
                                                  color: Colors.grey[400],
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  'Belum ada jadwal makan',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : ListView(
                                            children: articles2.map((article2) {
                                              final String imageUrl2 = article2['gambar'];
                                              String keterangan = article2['nama'];

                                              final scheduleFoods = data.where((item) {
                                                final itemKeterangan = item['keterangan'].toString().trim().toLowerCase();
                                                final searchKeterangan = keterangan.trim().toLowerCase();
                                                return itemKeterangan == searchKeterangan;
                                              }).toList();

                                              // Calculate aggregated nutrition
                                              double totalKalori = 0;
                                              double totalKarbohidrat = 0;
                                              double totalProtein = 0;
                                              double totalLemak = 0;
                                              double totalVitaminA = 0;
                                              double totalVitaminC = 0;
                                              double totalBesi = 0;

                                              for (var item in scheduleFoods) {
                                                totalKalori += double.parse(item['kalori']);
                                                totalKarbohidrat += double.parse(item['karbohidrat']);
                                                totalProtein += double.parse(item['protein']);
                                                totalLemak += double.parse(item['lemak']);
                                                totalVitaminA += double.parse(item['vitamina']);
                                                totalVitaminC += double.parse(item['vitaminc']);
                                                totalBesi += double.parse(item['besi']);
                                              }

                                              bool hasData = scheduleFoods.isNotEmpty;

                                              return Container(
                                                margin: const EdgeInsets.only(bottom: 12),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(15.0),
                                                  boxShadow: [boxShadow],
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(12.0),
                                                  child: Column(
                                                    children: [
                                                      Row(
                                                        children: [
                                                          ClipRRect(
                                                            borderRadius: BorderRadius.circular(8),
                                                            child: Image.network(
                                                              imageUrl2,
                                                              width: 60,
                                                              height: 60,
                                                              fit: BoxFit.cover,
                                                              errorBuilder: (context, error, stackTrace) {
                                                                return Container(
                                                                  width: 60,
                                                                  height: 60,
                                                                  color: Colors.grey[200],
                                                                  child: Icon(
                                                                    Icons.restaurant,
                                                                    color: Colors.grey[400],
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                          const SizedBox(width: 12),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                
                                                                Text(
                                                                  keterangan,
                                                                  style: TextStyle(
                                                                    fontSize: 16,
                                                                    fontWeight: FontWeight.bold,
                                                                    color: Colors.black87,
                                                                  ),
                                                                ),
                                                                if (hasData) ...[
                                                                  const SizedBox(height: 4),
                                                                  Text(
                                                                    '${scheduleFoods.length} makanan • ${totalKalori.toStringAsFixed(0)} kkal',
                                                                    style: TextStyle(
                                                                      fontSize: 12,
                                                                      color: Colors.green[600],
                                                                      fontWeight: FontWeight.w500,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ],
                                                            ),
                                                          ),
                                                          hasData
                                                              ? Row(
                                                                  mainAxisSize: MainAxisSize.min,
                                                                  children: [
                                                                    IconButton(
                                                                      icon: Icon(
                                                                        Icons.pie_chart_outline,
                                                                        color: Colors.purple,
                                                                        size: 20,
                                                                      ),
                                                                      onPressed: isLoadingIsiPiringku
                                                                          ? null
                                                                          : () {
                                                                              fetchIsiPiringku(keterangan);
                                                                            },
                                                                    ),
                                                                    IconButton(
                                                                      icon: Icon(
                                                                        Icons.info_outline,
                                                                        color: SecondaryColor,
                                                                        size: 20,
                                                                      ),
                                                                      onPressed: isLoadingKonsumsi
                                                                          ? null
                                                                          : () {
                                                                              fetchDataKonsumsi(keterangan);
                                                                            },
                                                                    ),
                                                                    IconButton(
                                                                      icon: Icon(
                                                                        Icons.analytics_outlined,
                                                                        color: PrimaryColor,
                                                                        size: 20,
                                                                      ),
                                                                      onPressed: isLoadingGrafik
                                                                          ? null
                                                                          : () {
                                                                              fetchGrafikKonsumsi(keterangan);
                                                                            },
                                                                    ),
                                                                  ],
                                                                )
                                                              : IconButton(
                                                                  icon: Icon(
                                                                    Icons.add_circle_outline,
                                                                    color: PrimaryColor,
                                                                    size: 24,
                                                                  ),
                                                                  onPressed: () async {
                                                                    final result = await Navigator.push(
                                                                      context,
                                                                      MaterialPageRoute(
                                                                        builder: (context) => TambahKalori(
                                                                              keterangan: keterangan,
                                                                            ),
                                                                      ),
                                                                    );

                                                                    if (result == true) {
                                                                      print('🔄 Refreshing data after add...');
                                                                      await refreshAllData();
                                                                    }
                                                                  },
                                                                ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 12),
                                                      if (hasData)
                                                        Container(
                                                          padding: const EdgeInsets.all(12),
                                                          decoration: BoxDecoration(
                                                            color: Colors.grey[50],
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                             Text(
  'Ringkasan Nutrisi',
  style: TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  ),
),
const SizedBox(height: 8),

// ✅ TAMBAHKAN BAGIAN INI (BARU)
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: scheduleFoods.map((food) {
    final urt = food['urt'] ?? food['URT'] ?? '-';
    final qty = int.tryParse((food['kuantitas'] ?? food['jumlah'] ?? food['qty'] ?? '1').toString()) ?? 1;
    final nama = food['nama_makanan'] ?? 'Unknown';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '• $nama',
              style: TextStyle(
                fontSize: 11,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Text(
              'URT: $urt × $qty',
              style: TextStyle(
                fontSize: 10,
                color: Colors.blue[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }).toList(),
),
const SizedBox(height: 12),
Divider(color: Colors.grey[300], height: 1),
const SizedBox(height: 12),
// ✅ AKHIR BAGIAN BARU

Wrap(
  spacing: 6,
  runSpacing: 6,
  children: [
    _buildCompactNutritionChip(
      Icons.local_fire_department,
      'Kalori',
      // ... chips lainnya tetap sama,
                                                                    totalKalori.toStringAsFixed(1),
                                                                    'kkal',
                                                                    Colors.orange,
                                                                  ),
                                                                  _buildCompactNutritionChip(
                                                                    Icons.grain,
                                                                    'Karbo',
                                                                    totalKarbohidrat.toStringAsFixed(1),
                                                                    'g',
                                                                    Colors.blue,
                                                                  ),
                                                                  _buildCompactNutritionChip(
                                                                    Icons.fitness_center,
                                                                    'Protein',
                                                                    totalProtein.toStringAsFixed(1),
                                                                    'g',
                                                                    Colors.green,
                                                                  ),
                                                                  _buildCompactNutritionChip(
                                                                    Icons.water_drop,
                                                                    'Lemak',
                                                                    totalLemak.toStringAsFixed(1),
                                                                    'g',
                                                                    Colors.red,
                                                                  ),
                                                                  _buildCompactNutritionChip(
                                                                    Icons.wb_sunny_outlined,
                                                                    'Vit A',
                                                                    totalVitaminA.toStringAsFixed(1),
                                                                    'mcg',
                                                                    Colors.purple,
                                                                  ),
                                                                  _buildCompactNutritionChip(
                                                                    Icons.spa_outlined,
                                                                    'Vit C',
                                                                    totalVitaminC.toStringAsFixed(1),
                                                                    'mg',
                                                                    Colors.cyan,
                                                                  ),
                                                                  _buildCompactNutritionChip(
                                                                    Icons.science_outlined,
                                                                    'Besi',
                                                                    totalBesi.toStringAsFixed(1),
                                                                    'mg',
                                                                    Colors.brown,
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        )
                                                      else
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                          decoration: BoxDecoration(
                                                            color: Colors.grey[50],
                                                            borderRadius: BorderRadius.circular(12),
                                                            border: Border.all(color: Colors.grey[300]!),
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                Icons.info_outline,
                                                                size: 18,
                                                                color: Colors.grey[500],
                                                              ),
                                                              const SizedBox(width: 8),
                                                              Text(
                                                                'Belum ada data nutrisi',
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors.grey[600],
                                                                  fontStyle: FontStyle.italic,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          child: Column(
                            children: [
                              SizedBox(
                                height: 50,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildCompactNutritionChip(IconData icon, String label, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Text(
            '$value $unit',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget mDetailKalori() {
    var size = MediaQuery.of(context).size;
    return Container(
      height: size.height * 0.6,
      width: size.width,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'Detail Kalori',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: isLoadingKonsumsi
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Memuat detail kalori...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : dataKonsumsi.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.no_food,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada data konsumsi',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: dataKonsumsi.length,
                        itemBuilder: (context, index) {
                          final item = dataKonsumsi[index];
                          final String namaMakanan = item['nama_makanan'];
                          final String kategori = item['nama_kategori'] ?? 'Karbo';
                          final urt = item['urt'] ?? item['URT'] ?? '-';

                          final int quantity = int.tryParse((item['kuantitas'] ?? item['jumlah'] ?? item['qty'] ?? item['quantity'] ?? '1').toString()) ?? 1;

                          final double kalori = double.parse(item['kalori']);
                          final double karbohidrat = double.parse(item['karbohidrat']);
                          final double protein = double.parse(item['protein']);
                          final double lemak = double.parse(item['lemak']);
                          final double vitaminA = double.parse(item['vitamina']);
                          final double vitaminC = double.parse(item['vitaminc']);
                          final double besi = double.parse(item['besi']);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [boxShadow],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.orange[400]!,
                                            Colors.orange[600]!,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.orange.withOpacity(0.3),
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${quantity}x',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        namaMakanan,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        kategori,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      // ✅ TAMBAHKAN BAGIAN INI (BARU)
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Text(
          'URT: $urt × $quantity',
          style: TextStyle(
            fontSize: 11,
            color: Colors.blue[700],
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      // ✅ AKHIR BAGIAN BARU
    ],
  ),
),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${kalori.toStringAsFixed(0)} kkal',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    _buildNutritionChip('Karbo', karbohidrat),
                                    _buildNutritionChip('Protein', protein),
                                    _buildNutritionChip('Lemak', lemak),
                                    _buildNutritionChip('Vit A', vitaminA, isVitamin: true, color: Colors.blue[100]),
                                    _buildNutritionChip('Vit C', vitaminC, isVitamin: true, color: Colors.green[100]),
                                    _buildNutritionChip('Besi', besi),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionChip(String label, double value, {bool isVitamin = false, Color? color}) {
    return Chip(
      label: Text(
        '$label: ${value.toStringAsFixed(2)}',
        style: const TextStyle(fontSize: 11),
      ),
      backgroundColor: isVitamin ? color : Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[300]!),
      ),
    );
  }

  Widget mGrafikKalori() {
    var size = MediaQuery.of(context).size;
    return Container(
      height: size.height * 0.7,
      width: size.width,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            'Analisis Kalori',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: isLoadingGrafik
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Memuat analisis kalori...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        if (dataMap.isNotEmpty)
                          Container(
                            margin: EdgeInsets.symmetric(vertical: 16),
                            child: PieChart(
                              dataMap: dataMap,
                              animationDuration: Duration(milliseconds: 800),
                              chartLegendSpacing: 16,
                              legendOptions: LegendOptions(
                                showLegendsInRow: false,
                                legendPosition: LegendPosition.left,
                                showLegends: true,
                                legendTextStyle: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              chartValuesOptions: ChartValuesOptions(
                                showChartValueBackground: false,
                                showChartValues: true,
                                showChartValuesInPercentage: false,
                                showChartValuesOutside: false,
                                decimalPlaces: 1,
                              ),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _buildStatRow('Total Kalori', '${totalKaloriKonsumsi.toInt()} Kkal'),
                              _buildStatRow('Kebutuhan Kalori', '${totalKebutuhanKonsumsi.toInt()} Kkal'),
                              _buildStatRow('Persentase Kecukupan', '${persentaseKecukupanKalori.toInt()}%'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _getStatusColor(persentaseKecukupanKalori).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getStatusColor(persentaseKecukupanKalori),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Status Kecukupan Kalori',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(persentaseKecukupanKalori),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _getStatusText(persentaseKecukupanKalori),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                keteranganKalori,
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ✅ UPDATED: Isi Piringku Modal - using GRAM and age-based recommendations
  Widget mIsiPiringku() {
    var size = MediaQuery.of(context).size;

    final double makananPokokGram = isiPiringkuData['makanan_pokok'] ?? 0;
    final double laukPaukGram = isiPiringkuData['lauk_pauk'] ?? 0;
    final double buahBuahanGram = isiPiringkuData['buah_buahan'] ?? 0;
    final double sayuranGram = isiPiringkuData['sayuran'] ?? 0;
    final double buahSayurGram = isiPiringkuData['buah_sayur'] ?? 0; // ✅ NEW: Combined for children
    final double totalGram = isiPiringkuData['total_gram'] ?? 1;
    final int userAge = isiPiringkuData['user_age'] ?? 20;

    // Get age-based recommendations
    final ageRecommendations = getAgeBasedPortions(userAge);

    // Calculate percentages based on actual consumption
    final double makananPokokPercent = totalGram > 0 ? (makananPokokGram / totalGram) * 100 : 0;
    final double laukPaukPercent = totalGram > 0 ? (laukPaukGram / totalGram) * 100 : 0;

    // ✅ UPDATED: Conditional percentages based on age
    double buahBuahanPercent = 0;
    double sayuranPercent = 0;
    double buahSayurPercent = 0;

    if (userAge >= 4 && userAge <= 6) {
      // Anak 4-6 tahun: buah dan sayur digabung
      buahSayurPercent = totalGram > 0 ? (buahSayurGram / totalGram) * 100 : 0;
    } else {
      // Usia lain: terpisah
      buahBuahanPercent = totalGram > 0 ? (buahBuahanGram / totalGram) * 100 : 0;
      sayuranPercent = totalGram > 0 ? (sayuranGram / totalGram) * 100 : 0;
    }

    // Get age category text
    String ageCategory = '';
    if (userAge >= 4 && userAge <= 6) {
      ageCategory = 'Anak 4-6 tahun';
    } else if (userAge >= 7 && userAge <= 12) {
      ageCategory = 'Anak 7-12 tahun';
    } else {
      ageCategory = 'Remaja & Dewasa (13+ tahun)';
    }

    return Container(
      height: size.height * 0.8,
      width: size.width,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'Isi Piringku',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Komposisi Makanan Berdasarkan Kategori',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: isLoadingIsiPiringku
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Memuat Isi Piringku...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // Age category badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.purple[50],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.purple[200]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person, size: 16, color: Colors.purple[700]),
                              const SizedBox(width: 4),
                              Text(
                                '$ageCategory ($userAge tahun)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.purple[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Custom Circular Diagram
                        Container(
                          width: 250,
                          height: 250,
                          child: CustomPaint(
                            painter: IsiPiringkuPainter(
                              makananPokokPercent: makananPokokPercent,
                              laukPaukPercent: laukPaukPercent,
                              buahBuahanPercent: userAge >= 4 && userAge <= 6 ? 0 : buahBuahanPercent,
                              sayuranPercent: userAge >= 4 && userAge <= 6 ? 0 : sayuranPercent,
                              buahSayurPercent: userAge >= 4 && userAge <= 6 ? buahSayurPercent : 0,
                              isChild: userAge >= 4 && userAge <= 6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Conditional display based on age
                        if (userAge >= 4 && userAge <= 6) ...[
                          // Untuk anak 4-6 tahun: buah dan sayur digabung
                          _buildIsiPiringkuItemGram(
                            'Makanan Pokok (Karbo)',
                            makananPokokGram,
                            makananPokokPercent,
                            Color(0xFFFFB300),
                            '${ageRecommendations['makanan_pokok']!.toInt()}g (${ageRecommendations['makanan_pokok_percent']!.toStringAsFixed(1)}%)',
                            ageRecommendations['makanan_pokok']!,
                          ),
                          const SizedBox(height: 16),
                          _buildIsiPiringkuItemGram(
                            'Lauk Pauk',
                            laukPaukGram,
                            laukPaukPercent,
                            Color(0xFFE91E63),
                            '${ageRecommendations['lauk_pauk']!.toInt()}g (${ageRecommendations['lauk_pauk_percent']!.toStringAsFixed(1)}%)',
                            ageRecommendations['lauk_pauk']!,
                          ),
                          const SizedBox(height: 16),
                          _buildIsiPiringkuItemGram(
                            'Buah & Sayuran',
                            buahSayurGram,
                            buahSayurPercent,
                            Color(0xFF4CAF50), // Hijau untuk kombinasi buah+sayur
                            '${ageRecommendations['buah_sayur']!.toInt()}g (${ageRecommendations['buah_sayur_percent']!.toStringAsFixed(1)}%)',
                            ageRecommendations['buah_sayur']!,
                          ),
                        ] else ...[
                          // Untuk usia lain: terpisah
                          _buildIsiPiringkuItemGram(
                            'Makanan Pokok (Karbo)',
                            makananPokokGram,
                            makananPokokPercent,
                            Color(0xFFFFB300),
                            '${ageRecommendations['makanan_pokok']!.toInt()}g (${ageRecommendations['makanan_pokok_percent']!.toStringAsFixed(1)}%)',
                            ageRecommendations['makanan_pokok']!,
                          ),
                          const SizedBox(height: 16),
                          _buildIsiPiringkuItemGram(
                            'Lauk Pauk',
                            laukPaukGram,
                            laukPaukPercent,
                            Color(0xFFE91E63),
                            '${ageRecommendations['lauk_pauk']!.toInt()}g (${ageRecommendations['lauk_pauk_percent']!.toStringAsFixed(1)}%)',
                            ageRecommendations['lauk_pauk']!,
                          ),
                          const SizedBox(height: 16),
                          _buildIsiPiringkuItemGram(
                            'Buah-buahan',
                            buahBuahanGram,
                            buahBuahanPercent,
                            Color(0xFF4CAF50),
                            '${ageRecommendations['buah_buahan']!.toInt()}g (${ageRecommendations['buah_buahan_percent']!.toStringAsFixed(1)}%)',
                            ageRecommendations['buah_buahan']!,
                          ),
                          const SizedBox(height: 16),
                          _buildIsiPiringkuItemGram(
                            'Sayuran',
                            sayuranGram,
                            sayuranPercent,
                            Color(0xFF2196F3),
                            '${ageRecommendations['sayuran']!.toInt()}g (${ageRecommendations['sayuran_percent']!.toStringAsFixed(1)}%)',
                            ageRecommendations['sayuran']!,
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Total Summary
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Konsumsi',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    '${totalGram.toStringAsFixed(0)} gram',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Info Box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  userAge >= 4 && userAge <= 6
                                      ? 'Untuk anak 4-6 tahun, buah dan sayuran digabung menjadi satu kategori sesuai panduan gizi.'
                                      : 'Isi Piringku adalah panduan gizi seimbang. Rekomendasi di atas disesuaikan dengan kategori umur Anda ($ageCategory).',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue[900],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Overall Status Summary
                        Builder(
                          builder: (context) {
                            // Calculate status for each category
                            List<Map<String, dynamic>> statuses = [];

                            if (userAge >= 4 && userAge <= 6) {
                              // Untuk anak: 3 kategori
                              statuses.add(_getPortionStatus(makananPokokGram, ageRecommendations['makanan_pokok']!));
                              statuses.add(_getPortionStatus(laukPaukGram, ageRecommendations['lauk_pauk']!));
                              statuses.add(_getPortionStatus(buahSayurGram, ageRecommendations['buah_sayur']!));
                            } else {
                              // Untuk usia lain: 4 kategori
                              statuses.add(_getPortionStatus(makananPokokGram, ageRecommendations['makanan_pokok']!));
                              statuses.add(_getPortionStatus(laukPaukGram, ageRecommendations['lauk_pauk']!));
                              statuses.add(_getPortionStatus(buahBuahanGram, ageRecommendations['buah_buahan']!));
                              statuses.add(_getPortionStatus(sayuranGram, ageRecommendations['sayuran']!));
                            }

                            // Count categories by status
                            int cukupCount = 0;
                            int kurangCount = 0;
                            int lebihCount = 0;
                            int belumAdaCount = 0;

                            for (var status in statuses) {
                              if (status['text'] == 'CUKUP') cukupCount++;
                              else if (status['text'] == 'KURANG') kurangCount++;
                              else if (status['text'] == 'LEBIH') lebihCount++;
                              else if (status['text'] == 'BELUM ADA') belumAdaCount++;
                            }

                            String overallMessage = '';
                            Color overallColor = Colors.grey;
                            IconData overallIcon = Icons.info_outline;

                            if (cukupCount == statuses.length) {
                              overallMessage = '🎉 Sempurna! Semua kategori sudah sesuai rekomendasi';
                              overallColor = Colors.green;
                              overallIcon = Icons.celebration;
                            } else if (cukupCount >= statuses.length - 1) {
                              overallMessage = '👍 Bagus! Sebagian besar kategori sudah sesuai';
                              overallColor = Colors.lightGreen;
                              overallIcon = Icons.thumb_up;
                            } else if (belumAdaCount >= 2) {
                              overallMessage = '⚠️ Perhatian! Beberapa kategori belum dikonsumsi';
                              overallColor = Colors.grey;
                              overallIcon = Icons.warning_amber;
                            } else if (kurangCount >= 2) {
                              overallMessage = '📊 Konsumsi beberapa kategori masih kurang';
                              overallColor = Colors.orange;
                              overallIcon = Icons.trending_down;
                            } else {
                              overallMessage = '💪 Terus tingkatkan konsumsi sesuai rekomendasi';
                              overallColor = Colors.blue;
                              overallIcon = Icons.fitness_center;
                            }

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: overallColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: overallColor.withOpacity(0.3), width: 2),
                              ),
                              child: Row(
                                children: [
                                  Icon(overallIcon, color: overallColor, size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Evaluasi Keseluruhan',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: overallColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          overallMessage,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: [
                                            if (cukupCount > 0)
                                              _buildStatusChip('✓ Cukup: $cukupCount', Colors.green),
                                            if (kurangCount > 0)
                                              _buildStatusChip('↓ Kurang: $kurangCount', Colors.red),
                                            if (lebihCount > 0)
                                              _buildStatusChip('↑ Lebih: $lebihCount', Colors.orange),
                                            if (belumAdaCount > 0)
                                              _buildStatusChip('○ Belum ada: $belumAdaCount', Colors.grey),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ✅ NEW: Get portion status based on actual vs recommended
  Map<String, dynamic> _getPortionStatus(double actualGram, double recommendedGram) {
    if (actualGram == 0) {
      return {
        'text': 'BELUM ADA',
        'color': Colors.grey,
        'message': 'Belum ada konsumsi',
      };
    }

    // Calculate percentage of actual vs recommended
    double percentOfRecommended = (actualGram / recommendedGram) * 100;

    // Tolerance: 80-120% is considered CUKUP
    if (percentOfRecommended < 80) {
      return {
        'text': 'KURANG',
        'color': Colors.red,
        'message': 'Konsumsi masih kurang dari rekomendasi',
      };
    } else if (percentOfRecommended >= 80 && percentOfRecommended <= 120) {
      return {
        'text': 'CUKUP',
        'color': Colors.green,
        'message': 'Konsumsi sudah sesuai rekomendasi',
      };
    } else {
      return {
        'text': 'LEBIH',
        'color': Colors.orange,
        'message': 'Konsumsi melebihi rekomendasi',
      };
    }
  }

  // ✅ NEW: Build status chip for overall summary
  Widget _buildStatusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      )
    );
  }

  // ✅ UPDATED: Build item with GRAM display and status notification
  Widget _buildIsiPiringkuItemGram(String label, double gram, double percentage, Color color, String recommendation, double recommendedGram) {
    // Get status
    final status = _getPortionStatus(gram, recommendedGram);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              // ✅ NEW: Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: status['color'],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status['text'],
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${gram.toStringAsFixed(0)} gram',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                recommendation,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          // ✅ NEW: Status message
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                status['text'] == 'CUKUP'
                    ? Icons.check_circle_outline
                    : status['text'] == 'KURANG'
                        ? Icons.warning_amber_rounded
                        : status['text'] == 'LEBIH'
                            ? Icons.error_outline
                            : Icons.info_outline,
                size: 14,
                color: status['color'],
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  status['message'],
                  style: TextStyle(
                    fontSize: 10,
                    color: status['color'],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionBarWithStatus(String label, String value, int percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStatusColor(percentage),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(percentage),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(percentage),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (percentage / 100).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: _getStatusColor(percentage),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(int percentage) {
    if (percentage < 70) {
      return 'KURANG';
    } else if (percentage >= 70 && percentage <= 110) {
      return 'CUKUP';
    } else {
      return 'LEBIH';
    }
  }

  Color _getStatusColor(int percentage) {
    if (percentage < 70) {
      return Colors.red;
    } else if (percentage >= 70 && percentage <= 110) {
      return Colors.green;
    } else {
      return Colors.orange;
    }
  }
}

// Custom Painter for Isi Piringku Circular Diagram
class IsiPiringkuPainter extends CustomPainter {
  final double makananPokokPercent;
  final double laukPaukPercent;
  final double buahBuahanPercent;
  final double sayuranPercent;
  final double buahSayurPercent;
  final bool isChild;

  IsiPiringkuPainter({
    required this.makananPokokPercent,
    required this.laukPaukPercent,
    required this.buahBuahanPercent,
    required this.sayuranPercent,
    this.buahSayurPercent = 0,
    this.isChild = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    final makananPokokColor = Color(0xFFFFB300);
    final laukPaukColor = Color(0xFFE91E63);
    final buahBuahanColor = Color(0xFF4CAF50);
    final sayuranColor = Color(0xFF2196F3);
    final buahSayurColor = Color(0xFF4CAF50); // Hijau untuk kombinasi

    double startAngle = -math.pi / 2;
    int segmentCount = isChild ? 3 : 4;

    if (isChild) {
      // Untuk anak: 3 segment (makanan pokok, lauk pauk, buah+sayur)
      final makananPokokSweep = (makananPokokPercent / 100) * 2 * math.pi;
      final makananPokokPaint = Paint()
        ..color = makananPokokColor
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        makananPokokSweep,
        true,
        makananPokokPaint,
      );
      startAngle += makananPokokSweep;

      final laukPaukSweep = (laukPaukPercent / 100) * 2 * math.pi;
      final laukPaukPaint = Paint()
        ..color = laukPaukColor
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        laukPaukSweep,
        true,
        laukPaukPaint,
      );
      startAngle += laukPaukSweep;

      final buahSayurSweep = (buahSayurPercent / 100) * 2 * math.pi;
      final buahSayurPaint = Paint()
        ..color = buahSayurColor
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        buahSayurSweep,
        true,
        buahSayurPaint,
      );
    } else {
      // Untuk non-anak: 4 segment
      final makananPokokSweep = (makananPokokPercent / 100) * 2 * math.pi;
      final makananPokokPaint = Paint()
        ..color = makananPokokColor
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        makananPokokSweep,
        true,
        makananPokokPaint,
      );
      startAngle += makananPokokSweep;

      final laukPaukSweep = (laukPaukPercent / 100) * 2 * math.pi;
      final laukPaukPaint = Paint()
        ..color = laukPaukColor
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        laukPaukSweep,
        true,
        laukPaukPaint,
      );
      startAngle += laukPaukSweep;

      final buahBuahanSweep = (buahBuahanPercent / 100) * 2 * math.pi;
      final buahBuahanPaint = Paint()
        ..color = buahBuahanColor
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        buahBuahanSweep,
        true,
        buahBuahanPaint,
      );
      startAngle += buahBuahanSweep;

      final sayuranSweep = (sayuranPercent / 100) * 2 * math.pi;
      final sayuranPaint = Paint()
        ..color = sayuranColor
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sayuranSweep,
        true,
        sayuranPaint,
      );
    }

    // Draw dividing lines
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    startAngle = -math.pi / 2;

    for (int i = 0; i < segmentCount; i++) {
      double sweepAngle;
      if (isChild) {
        if (i == 0) sweepAngle = (makananPokokPercent / 100) * 2 * math.pi;
        else if (i == 1) sweepAngle = (laukPaukPercent / 100) * 2 * math.pi;
        else sweepAngle = (buahSayurPercent / 100) * 2 * math.pi;
      } else {
        if (i == 0) sweepAngle = (makananPokokPercent / 100) * 2 * math.pi;
        else if (i == 1) sweepAngle = (laukPaukPercent / 100) * 2 * math.pi;
        else if (i == 2) sweepAngle = (buahBuahanPercent / 100) * 2 * math.pi;
        else sweepAngle = (sayuranPercent / 100) * 2 * math.pi;
      }

      final endAngle = startAngle + sweepAngle;
      final endX = center.dx + radius * math.cos(endAngle);
      final endY = center.dy + radius * math.sin(endAngle);

      canvas.drawLine(center, Offset(endX, endY), borderPaint);
      startAngle = endAngle;
    }

    final outerBorderPaint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, outerBorderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}