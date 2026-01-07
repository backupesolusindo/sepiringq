import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:isi_piringku/bloc/nav/bottom_nav.dart';
import 'package:isi_piringku/util/colors.dart';
import 'package:isi_piringku/util/core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../model/user.dart';
import '../widgets/legend_widget.dart' as legend_widget;

/// Halaman Riwayat - Menampilkan grafik dan riwayat konsumsi kalori pengguna
///
/// Fitur utama:
/// - Grafik bar chart konsumsi kalori berdasarkan kategori makanan (Karbo, Lauk, Sayur, Buah)
/// - Filter berdasarkan rentang tanggal
/// - Daftar riwayat konsumsi kalori harian
/// - Visualisasi data dengan warna yang berbeda untuk setiap kategori makanan
class Riwayat extends StatefulWidget {
  const Riwayat({super.key});

  @override
  State<Riwayat> createState() => _RiwayatState();
}

class _RiwayatState extends State<Riwayat> {
  // Data untuk menyimpan daftar makanan dan grafik
  List<dynamic> makananList = [];
  List listBarGroup = [];
  List<dynamic> dataKonsumsi = [];
  Map<String, double> totalCaloriesByDate = {};

  // ID pengguna yang sedang login
  String userId = '';

  // Rentang tanggal untuk filter data (default: 7 hari terakhir)
  DateTime startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime endDate = DateTime.now();

  // Loading states
  bool isLoadingData = false;
  bool isInitialLoading = true;

  /// Menampilkan date picker untuk memilih tanggal mulai
  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != startDate) {
      setState(() {
        startDate = picked;
      });
      await fetchData();
    }
  }

  /// Menampilkan date picker untuk memilih tanggal akhir
  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != endDate) {
      setState(() {
        endDate = picked;
      });
      await fetchData();
    }
  }

  // Konstanta warna untuk setiap kategori makanan
  final karboColor = KarboColor;
  final laukColor = LaukColor;
  final sayurColor = SayurColor;
  final buahColor = BuahColor;
  final betweenSpace = 0.1;

  /// Membuat data grup untuk bar chart dengan 4 kategori makanan
  ///
  /// [x] - posisi x pada chart
  /// [karboVal] - nilai kalori karbohidrat
  /// [laukVal] - nilai kalori lauk pauk
  /// [sayurVal] - nilai kalori sayuran
  /// [buahVal] - nilai kalori buah-buahan
  BarChartGroupData generateGroupData(
    int x,
    double karboVal,
    double laukVal,
    double sayurVal,
    double buahVal,
  ) {
    return BarChartGroupData(
      x: x,
      groupVertically: true,
      barRods: [
        BarChartRodData(
          fromY: 0,
          toY: karboVal,
          color: karboColor,
          width: 5,
        ),
        BarChartRodData(
          fromY: karboVal + betweenSpace,
          toY: karboVal + betweenSpace + laukVal,
          color: laukColor,
          width: 5,
        ),
        BarChartRodData(
          fromY: karboVal + betweenSpace + laukVal + betweenSpace,
          toY: karboVal + betweenSpace + laukVal + betweenSpace + sayurVal,
          color: sayurColor,
          width: 5,
        ),
        BarChartRodData(
          fromY: karboVal +
              betweenSpace +
              laukVal +
              betweenSpace +
              sayurVal +
              betweenSpace,
          toY: karboVal +
              betweenSpace +
              laukVal +
              betweenSpace +
              sayurVal +
              betweenSpace +
              buahVal,
          color: buahColor,
          width: 5,
        ),
      ],
    );
  }

  /// Membuat label tanggal untuk sumbu X pada chart
  Widget bottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(fontSize: 10);
    String text = DateFormat('dd/MM')
        .format(startDate.add(Duration(days: value.toInt())));

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(text, style: style),
    );
  }

  /// Mengambil data konsumsi kalori dari API berdasarkan rentang tanggal
  Future<void> fetchData() async {
    if (!mounted) return;

    setState(() {
      isLoadingData = true;
    });

    try {
      String start = DateFormat('yyyy-MM-dd').format(startDate);
      String end = DateFormat('yyyy-MM-dd').format(endDate);
      String url =
          '${base_url}API/Makanan/allKonsumsi?id_user=$userId&start=$start&end=$end';

      final Uri uri = Uri.parse(url);
      final response = await http.get(uri);

      // Debug: Print URL dan response untuk development
      debugPrint("Fetching data from: $url");
      debugPrint("Response: ${response.body}");

      listBarGroup.clear();

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final responseList = jsonData['resGraf'];
        dataKonsumsi = jsonData['response'];

        int no = 0;
        if (mounted) {
          setState(() {
            responseList.forEach((element) {
              listBarGroup.add(generateGroupData(
                  no++,
                  double.parse(element['karbo'].toString()),
                  double.parse(element['lauk'].toString()),
                  double.parse(element['sayur'].toString()),
                  double.parse(element['buah'].toString())));
            });
            isLoadingData = false;
            isInitialLoading = false;
          });
        }
      } else {
        debugPrint("Error fetching data: ${response.body}");
        if (mounted) {
          setState(() {
            isLoadingData = false;
            isInitialLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal memuat data riwayat'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Exception in fetchData: $e");
      if (mounted) {
        setState(() {
          isLoadingData = false;
          isInitialLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan saat memuat data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  /// Memuat data pengguna dari SharedPreferences dan mengambil data konsumsi
  Future<void> loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');

      if (userDataString != null) {
        final userData = UserData.fromJson(json.decode(userDataString));
        debugPrint("User loaded: ${userData.nama}");

        setState(() {
          userId = userData.idUser.toString();
        });

        // Fetch data setelah user ID tersedia
        await fetchData();
      } else {
        debugPrint("No user data found in SharedPreferences");
        if (mounted) {
          setState(() {
            isInitialLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data pengguna tidak ditemukan'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
      if (mounted) {
        setState(() {
          isInitialLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show initial loading screen
    if (isInitialLoading) {
      return Scaffold(
        bottomNavigationBar: const BottomNavBar(selected: 2),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Memuat data riwayat...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      bottomNavigationBar: const BottomNavBar(selected: 2),
      body: SingleChildScrollView(
        child: Stack(children: [
          // Header background image
          Container(
            height: 130,
            width: double.infinity,
            decoration: const BoxDecoration(
                image: DecorationImage(
                    image: AssetImage('assets/images/head2.jpg'),
                    fit: BoxFit.cover)),
          ),
          SafeArea(
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 64),
                      const SizedBox(height: 20),

                      // Title section
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
                              'Riwayat Konsumsi Kalori',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Date picker section
                      _buildDatePickerSection(),

                      const SizedBox(height: 24),

                      // Chart section
                      _buildChartSection(),

                      const SizedBox(height: 24),

                      // History list section
                      _buildHistorySection(),
                    ],
                  ),
                )),
          ),

          // Loading overlay
          if (isLoadingData)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Memuat data...',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }

  /// Widget untuk section pemilihan tanggal
  Widget _buildDatePickerSection() {
    return Card(
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Periode',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tanggal Mulai',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM yyyy').format(startDate),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isLoadingData
                              ? null
                              : () => _selectStartDate(context),
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: const Text("Pilih"),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: PrimaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tanggal Akhir',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM yyyy').format(endDate),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isLoadingData
                              ? null
                              : () => _selectEndDate(context),
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: const Text("Pilih"),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: PrimaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.blue.shade700, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Periode: ${endDate.difference(startDate).inDays + 1} hari',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget untuk section grafik konsumsi kalori
  Widget _buildChartSection() {
    return Card(
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Grafik Konsumsi Kalori per Kategori',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Menampilkan distribusi kalori dari berbagai kategori makanan',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),

            // Legend
            legend_widget.LegendsListWidget(
              legends: [
                legend_widget.Legend('Karbohidrat', karboColor),
                legend_widget.Legend('Lauk Pauk', laukColor),
                legend_widget.Legend('Sayuran', sayurColor),
                legend_widget.Legend('Buah-buahan', buahColor),
              ],
            ),

            const SizedBox(height: 16),

            // Chart
            if (listBarGroup.isNotEmpty)
              AspectRatio(
                aspectRatio: 2,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceBetween,
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                      topTitles: const AxisTitles(),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: bottomTitles,
                          reservedSize: 20,
                        ),
                      ),
                    ),
                    barTouchData: BarTouchData(enabled: false),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                    barGroups: listBarGroup.cast<BarChartGroupData>(),
                    maxY: 16 + (betweenSpace * 4),
                    extraLinesData: ExtraLinesData(
                      horizontalLines: [
                        HorizontalLine(
                          y: 4,
                          color: karboColor,
                          strokeWidth: 1,
                          dashArray: [20, 4],
                        ),
                        HorizontalLine(
                          y: 8,
                          color: laukColor,
                          strokeWidth: 1,
                          dashArray: [20, 4],
                        ),
                        HorizontalLine(
                          y: 12,
                          color: sayurColor,
                          strokeWidth: 1,
                          dashArray: [20, 4],
                        ),
                        HorizontalLine(
                          y: 16,
                          color: buahColor,
                          strokeWidth: 1,
                          dashArray: [20, 4],
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 200,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bar_chart, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'Tidak ada data untuk ditampilkan',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        'Silakan pilih rentang tanggal yang berbeda',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Widget untuk section daftar riwayat konsumsi
  Widget _buildHistorySection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Riwayat Konsumsi Harian',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: PrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${dataKonsumsi.length} hari',
                    style: TextStyle(
                      fontSize: 12,
                      color: PrimaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Detail konsumsi kalori per hari dalam periode yang dipilih',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            if (dataKonsumsi.isNotEmpty)
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.3,
                child: ListView.builder(
                  itemCount: dataKonsumsi.length,
                  itemBuilder: (context, index) {
                    final item = dataKonsumsi[index];
                    final date =
                        DateTime.tryParse(item['tanggal']) ?? DateTime.now();
                    final dayName = DateFormat('EEEE', 'id_ID').format(date);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [boxShadow],
                        border: Border(
                          left: BorderSide(
                            color: PrimaryColor,
                            width: 4,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: PrimaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.restaurant,
                              color: PrimaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('dd MMMM yyyy').format(date),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  dayName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${item['kalori']} kal',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: PrimaryColor,
                                ),
                              ),
                              const Text(
                                'Total Kalori',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                height: 120,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'Belum ada riwayat konsumsi',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        'Mulai catat konsumsi makanan Anda',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
