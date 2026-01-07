// lib/kalori/kalori.dart
import 'dart:convert';

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

  @override
  void initState() {
    super.initState();
    loadUserDataAndFetchData();
    fetchData2();
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
        fetchData();
        fetchData2();
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
      print("Response Jadwal Makanan");
      print(response.body);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> responseList = data['response'];
        setState(() {
          articles2 = responseList;
        });
      } else {
        throw Exception('Failed to load data from API');
      }
    } catch (e) {
      print('Error fetching jadwal: $e');
    } finally {
      setState(() {
        isLoadingJadwal = false;
      });
    }
  }

  Future<void> loadUserDataAndFetchData() async {
    await loadUserData();
    if (Id.isNotEmpty) {
      fetchData();
      fetchData2();
    }
  }

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

  List<dynamic> data = [];

  Future<void> fetchData() async {
    if (Id.isEmpty) {
      return;
    }

    setState(() {
      isLoading = true;
    });
    try {
      print(Id);
      String fetkal = base_url + "API/Makanan/konsumsi?id_user=$Id&waktu=$formattedDate";
      final response = await http.get(
        Uri.parse(fetkal),
      );

      print("Response Konsumsi");
      print(response.body);
      print(Id);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print(jsonResponse);

        setState(() {
          data = jsonResponse['response'];
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
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching  $e');
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
      print(Id);
      String fetkal = base_url + "API/Makanan/konsumsi?id_user=$Id&waktu=$formattedDate&keterangan=$keterangan";
      final response = await http.get(
        Uri.parse(fetkal),
      );

      print("Response Konsumsi Keterangan");
      print(keterangan);
      print(response.body);
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        setState(() {
          dataKonsumsi = jsonResponse['response'];
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
      print('Error fetching konsumsi: $e');
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
      print(Id);
      String fetkal = base_url + "API/Makanan/kalorikonsumsi?id_user=$Id&waktu=$formattedDate&keterangan=$keterangan";
      final response = await http.get(
        Uri.parse(fetkal),
      );

      print("Response Konsumsi Grafik");
      print(keterangan);
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
      print('Error fetching grafik: $e');
      setState(() {
        isLoadingGrafik = false;
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
                                              
                                              // === AGGREGATION LOGIC ===
                                              final scheduleFoods = data.where((item) => 
                                                item['keterangan'].toLowerCase() == keterangan.toLowerCase()
                                              ).toList();
                                              
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
                                              // === END AGGREGATION ===
                                              
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
                                                          // Meal Image
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
                                                          // Meal Info
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
                                                          // Action Buttons
                                                          hasData
                                                              ? Row(
                                                                  mainAxisSize: MainAxisSize.min,
                                                                  children: [
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
                                                                    // Wait for result from TambahKalori page
                                                                    final result = await Navigator.push(
                                                                      context,
                                                                      MaterialPageRoute(
                                                                        builder: (context) => TambahKalori(
                                                                              keterangan: keterangan,
                                                                            ),
                                                                      ),
                                                                    );
                                                                    
                                                                    // Refresh data if food was successfully added
                                                                    if (result == true) {
                                                                      fetchData();  // Refresh consumption data
                                                                      fetchData2(); // Refresh schedule data
                                                                    }
                                                                  },
                                                                ),
                                                        ],
                                                      ),
                                                      // === NUTRITION SUMMARY (REPLACES FOOD LIST) ===
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
                                                              Wrap(
                                                                spacing: 6,
                                                                runSpacing: 6,
                                                                children: [
                                                                  _buildCompactNutritionChip(
                                                                    Icons.local_fire_department,
                                                                    'Kalori',
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
                                                      // === END NUTRITION SUMMARY ===
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

  // === NEW HELPER WIDGET FOR COMPACT NUTRITION CHIPS ===
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
                                          Text(
                                            kategori,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
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
