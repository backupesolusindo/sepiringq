//lib/BeratBadan/BeratBadan.dart

import 'dart:convert';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isi_piringku/util/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../bloc/nav/bottom_nav.dart';
import '../model/user.dart';
import '../resources/app_resources.dart';
import '../util/core.dart';
import 'TambahBB.dart';

class BeratBadan extends StatefulWidget {
  const BeratBadan({super.key});

  @override
  State<BeratBadan> createState() => _BeratBadanState();
}

class _BeratBadanState extends State<BeratBadan> {
  List<Color> gradientColors = [
    SecondaryColor,
    PrimaryColor,
  ];

  List<Color> imtGradientColors = [
    Colors.orange,
    Colors.red,
  ];

  String id = "";
  double tinggiBadan = 0.0;
  DateTime startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime endDate = DateTime.now();
  bool showIMT = true;
  bool showBeratBadan = true;
  bool isLoading = true;

  /// FUNGSI PERHITUNGAN IMT - SAMA DENGAN DASHBOARD
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

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');

    if (userDataString != null) {
      final userData = UserData.fromJson(json.decode(userDataString));

      setState(() {
        id = userData.idUser.toString();
        tinggiBadan = double.tryParse(userData.tinggiBadan) ?? 0.0;
        fetchData();
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  List<FlSpot> arBeratBadan = [];
  List<FlSpot> arIMT = [];
  List labelData = [];

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });
    
    String start = DateFormat('yyyy-MM-dd').format(startDate);
    String end = DateFormat('yyyy-MM-dd').format(endDate);
    
    if (id.isEmpty) {
      setState(() {
        isLoading = false;
        arBeratBadan = [];
        arIMT = [];
        labelData = [];
      });
      return;
    }

    arBeratBadan = [];
    arIMT = [];
    labelData = [];

    try {
      String fetchUrl =
          "${base_url}api/BeratBadan/getBeratBadan?id_user=$id&start=$start&end=$end";
      final response = await http.get(Uri.parse(fetchUrl));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        setState(() {
          var data = jsonResponse['response']['dataGraf'];
          labelData = jsonResponse['response']['dataLabel'] ?? [];
          
          if (data != null && data is List) {
            for (var i = 0; i < data.length; i++) {
              try {
                double beratBadan = double.tryParse(data[i]['bb'].toString()) ?? 0.0;
                arBeratBadan.add(FlSpot(i.toDouble(), beratBadan));

                // GUNAKAN FUNGSI CALCULATE IMT YANG SAMA DENGAN DASHBOARD
                if (tinggiBadan > 0 && beratBadan > 0) {
                  double imt = calculateIMT(beratBadan, tinggiBadan);
                  
                  if (imt > 0) {
                    arIMT.add(FlSpot(i.toDouble(), imt));
                  }
                }
              } catch (e) {
                print("Error processing data at index $i: $e");
              }
            }
          }
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching data: $e");
    }
  }

  String getIMTCategory(double imt) {
    if (imt.isNaN || !imt.isFinite || imt <= 0) return 'Invalid';
    if (imt < 18.5) return 'Kurus';
    if (imt < 25.0) return 'Normal';
    if (imt < 30.0) return 'Gemuk';
    return 'Obesitas';
  }

  Color getIMTColor(double imt) {
    if (imt.isNaN || !imt.isFinite) return Colors.grey;
    if (imt < 18.5) return Colors.blue;
    if (imt < 25.0) return Colors.green;
    if (imt < 30.0) return Colors.orange;
    return Colors.red;
  }

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
      fetchData();
    }
  }

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
      fetchData();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AccentColor,
                AccentColor.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 2,
        title: const Text(
          'BERAT BADAN',
          style: TextStyle(
            color: TextColorLight,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: TextColorLight),
      ),
      bottomNavigationBar: const BottomNavBar(selected: 5),
      backgroundColor: BackgroundColor,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              margin: const EdgeInsets.only(left: 16, right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          _buildInputBeratBadanCard(),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Text(
                                  "Grafik Berat Badan & IMT",
                                  style: TextStyle(
                                    color: TextColordark,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text("BB", 
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Switch(
                                        value: showBeratBadan,
                                        onChanged: (value) {
                                          setState(() {
                                            showBeratBadan = value;
                                          });
                                        },
                                        activeThumbColor: PrimaryColor,
                                        activeColor: PrimaryColor.withValues(alpha: 0.5),
                                      ),
                                    ],
                                  ),
                                  if (tinggiBadan > 0)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text("IMT", 
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Switch(
                                          value: showIMT,
                                          onChanged: (value) {
                                            setState(() {
                                              showIMT = value;
                                            });
                                          },
                                          activeThumbColor: Colors.orange,
                                          activeColor: Colors.orange.withValues(alpha: 0.5),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                          if (tinggiBadan > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                "Tinggi Badan: ${tinggiBadan.toStringAsFixed(1)} cm",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          Container(
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: BackgroundColorWhite,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [boxShadowWhite],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Tanggal Mulai",
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            InkWell(
                                              onTap: () => _selectStartDate(context),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AccentColor.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: AccentColor.withValues(alpha: 0.3),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.calendar_today,
                                                      size: 14,
                                                      color: AccentColor,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      DateFormat('dd MMM yy').format(startDate),
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                        color: AccentColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            const Text(
                                              "Tanggal Akhir",
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            InkWell(
                                              onTap: () => _selectEndDate(context),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AccentColor.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: AccentColor.withValues(alpha: 0.3),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.calendar_today,
                                                      size: 14,
                                                      color: AccentColor,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      DateFormat('dd MMM yy').format(endDate),
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                        color: AccentColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (showBeratBadan || (tinggiBadan > 0 && showIMT))
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        if (showBeratBadan)
                                          Row(
                                            children: [
                                              Container(
                                                width: 24,
                                                height: 3,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: gradientColors,
                                                  ),
                                                  borderRadius: BorderRadius.circular(2),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              const Text(
                                                "Berat Badan (kg)",
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        if (tinggiBadan > 0 && showIMT)
                                          Row(
                                            children: [
                                              Container(
                                                width: 24,
                                                height: 3,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: imtGradientColors,
                                                  ),
                                                  borderRadius: BorderRadius.circular(2),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              const Text(
                                                "IMT",
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                AspectRatio(
                                  aspectRatio: 1.4,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 8,
                                      right: 24,
                                      top: 16,
                                      bottom: 8,
                                    ),
                                    child: (showBeratBadan || (tinggiBadan > 0 && showIMT))
                                        ? arBeratBadan.isEmpty && (tinggiBadan == 0 || arIMT.isEmpty)
                                            ? const Center(
                                                child: Text(
                                                  "Tidak ada data untuk ditampilkan",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.grey,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              )
                                            : LineChart(mainData())
                                        : const Center(
                                            child: Text(
                                              "Pilih minimal satu grafik untuk ditampilkan",
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                  ),
                                ),
                                if (tinggiBadan > 0 && showIMT && arIMT.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Kategori IMT (Indeks Massa Tubuh):",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                                          children: [
                                            _buildIMTCategory("Kurus", "< 18.5", Colors.blue),
                                            _buildIMTCategory("Normal", "18.5-24.9", Colors.green),
                                            _buildIMTCategory("Gemuk", "25-29.9", Colors.orange),
                                            _buildIMTCategory("Obesitas", "≥ 30", Colors.red),
                                          ],
                                        ),
                                        if (arIMT.isNotEmpty)
                                          Container(
                                            margin: const EdgeInsets.only(top: 12),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: getIMTColor(arIMT.last.y).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: getIMTColor(arIMT.last.y).withValues(alpha: 0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Text(
                                                  "IMT Terakhir:",
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  "${arIMT.last.y.toStringAsFixed(1)} - ${getIMTCategory(arIMT.last.y)}",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: getIMTColor(arIMT.last.y),
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInputBeratBadanCard() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TambahBB(),
          ),
        ).then((_) {
          fetchData();
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AccentColor.withValues(alpha: 0.1),
              AccentColor.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AccentColor.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AccentColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AccentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.monitor_weight_outlined,
                size: 40,
                color: AccentColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Berapa Berat Kamu Hari Ini?",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: PrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Tap untuk input berat badan",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AccentColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          size: 16,
                          color: TextColorLight,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "Tambah Data",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: TextColorLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AccentColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 9,
      color: Colors.black87,
    );
    
    int index = value.toInt();
    
    if (index.isNaN || !index.isFinite || 
        index < 0 || 
        index >= labelData.length ||
        labelData.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Logika pemfilteran label berdasarkan jumlah data
    int dataLength = labelData.length;
    bool shouldShow = false;
    
    if (dataLength <= 7) {
      // Tampilkan semua label jika data <= 7
      shouldShow = true;
    } else if (dataLength <= 15) {
      // Tampilkan setiap 2 label jika data 8-15
      shouldShow = index % 2 == 0;
    } else if (dataLength <= 30) {
      // Tampilkan setiap 3 label jika data 16-30
      shouldShow = index % 3 == 0;
    } else {
      // Tampilkan setiap 5 label jika data > 30
      shouldShow = index % 5 == 0;
    }
    
    // Selalu tampilkan label pertama dan terakhir
    if (index == 0 || index == dataLength - 1) {
      shouldShow = true;
    }
    
    if (!shouldShow) {
      return const SizedBox.shrink();
    }
    
    String label;
    try {
      label = labelData[index].toString();
    } catch (e) {
      label = "";
    }
    
    // Rotasi label jika data banyak untuk menghindari tumpang tindih
    double rotationAngle = dataLength > 15 ? -0.4 : 0;
    
    Widget text = Transform.rotate(
      angle: rotationAngle,
      child: Text(
        label,
        style: style,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: dataLength > 15 ? 6 : 4,
      child: text,
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 10,
      color: Colors.black87,
    );
    
    if (value.isNaN || !value.isFinite) {
      return const SizedBox.shrink();
    }
    
    // Hanya tampilkan nilai bulat untuk menghindari tumpang tindih
    if (value != value.roundToDouble()) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Text(
        value.toInt().toString(),
        style: style,
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget _buildIMTCategory(String title, String range, Color color) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          range,
          style: const TextStyle(
            fontSize: 9,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  List<double> _displayedIMTLabels = [];

  /// PERBAIKAN UTAMA: Label IMT di axis kanan tidak menumpuk
  /// Strategi: Track label yang sudah ditampilkan untuk menghindari duplikasi
  Widget rightTitleWidgets(double value, TitleMeta meta) {
    if (value.isNaN || !value.isFinite) {
      return const SizedBox.shrink();
    }
    
    // Reset list jika ini adalah panggilan pertama (value mendekati min)
    double minBB = arBeratBadan.isNotEmpty 
        ? arBeratBadan.map((e) => e.y).reduce((a, b) => a < b ? a : b)
        : 0;
    double maxBB = arBeratBadan.isNotEmpty
        ? arBeratBadan.map((e) => e.y).reduce((a, b) => a > b ? a : b)
        : 100;
    
    if (maxBB - minBB < 10) {
      double center = (minBB + maxBB) / 2;
      minBB = max(0, center - 5);
      maxBB = center + 5;
    }
    
    double yPadding = (maxBB - minBB) * 0.15;
    double adjustedMinY = max(0, minBB - yPadding);
    double adjustedMaxY = maxBB + yPadding;
    
    // Reset tracking list di awal render
    if ((value - adjustedMinY).abs() < 0.1) {
      _displayedIMTLabels.clear();
    }
    
    double minIMT = arIMT.isNotEmpty
        ? arIMT.map((e) => e.y).reduce((a, b) => a < b ? a : b)
        : 0;
    double maxIMT = arIMT.isNotEmpty
        ? arIMT.map((e) => e.y).reduce((a, b) => a > b ? a : b)
        : 50;
    
    if (maxIMT - minIMT < 5) {
      double center = (minIMT + maxIMT) / 2;
      minIMT = max(0, center - 2.5);
      maxIMT = center + 2.5;
    }
    
    // Konversi nilai BB ke IMT
    double imtValue;
    if (adjustedMaxY - adjustedMinY > 0) {
      imtValue = ((value - adjustedMinY) / (adjustedMaxY - adjustedMinY)) * (maxIMT - minIMT) + minIMT;
    } else {
      imtValue = minIMT;
    }
    
    if (imtValue.isNaN || !imtValue.isFinite) {
      return const SizedBox.shrink();
    }
    
    // Hitung interval yang tepat
    double imtRange = maxIMT - minIMT;
    int targetLabels = 4;
    
    double rawInterval = imtRange / targetLabels;
    double magnitude = pow(10, (log(max(rawInterval, 0.1)) / ln10).floor()).toDouble();
    double normalized = rawInterval / magnitude;
    
    double interval;
    if (normalized <= 1.5) {
      interval = 1 * magnitude;
    } else if (normalized <= 3) {
      interval = 2 * magnitude;
    } else if (normalized <= 7) {
      interval = 5 * magnitude;
    } else {
      interval = 10 * magnitude;
    }
    
    if (interval < 1) {
      interval = 1;
    }
    
    // Bulatkan ke kelipatan interval
    double roundedIMT = (imtValue / interval).round() * interval;
    
    // Cek apakah nilai ini dekat dengan kelipatan interval
    double tolerance = interval * 0.08; // Toleransi sangat ketat
    if ((imtValue - roundedIMT).abs() > tolerance) {
      return const SizedBox.shrink();
    }
    
    // Pastikan dalam range
    if (roundedIMT < minIMT - 0.5 || roundedIMT > maxIMT + 0.5) {
      return const SizedBox.shrink();
    }
    
    // CEK DUPLIKASI: Jika label ini sudah ditampilkan, skip
    for (double displayed in _displayedIMTLabels) {
      if ((roundedIMT - displayed).abs() < interval * 0.5) {
        return const SizedBox.shrink();
      }
    }
    
    // Tambahkan ke list label yang sudah ditampilkan
    _displayedIMTLabels.add(roundedIMT);
    
    // Format angka
    String labelText;
    if (roundedIMT == roundedIMT.roundToDouble()) {
      labelText = roundedIMT.toInt().toString();
    } else {
      labelText = roundedIMT.toStringAsFixed(1);
    }
    
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        labelText,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 10,
          color: Colors.orange,
        ),
        textAlign: TextAlign.left,
      ),
    );
  }

  LineChartData mainData() {
    List<LineChartBarData> lineBarsData = [];

    if (arBeratBadan.isEmpty && arIMT.isEmpty) {
      return LineChartData(
        lineBarsData: [],
        titlesData: const FlTitlesData(show: false),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 1,
        minY: 0,
        maxY: 1,
      );
    }

    // Hitung min dan max untuk BB
    double minBB = 0;
    double maxBB = 100;
    
    if (showBeratBadan && arBeratBadan.isNotEmpty) {
      minBB = arBeratBadan.map((e) => e.y).reduce((a, b) => a < b ? a : b);
      maxBB = arBeratBadan.map((e) => e.y).reduce((a, b) => a > b ? a : b);
      
      if (maxBB - minBB < 10) {
        double center = (minBB + maxBB) / 2;
        minBB = max(0, center - 5);
        maxBB = center + 5;
      }
    }

    // Hitung min dan max untuk IMT
    double minIMT = 0;
    double maxIMT = 50;
    
    if (tinggiBadan > 0 && showIMT && arIMT.isNotEmpty) {
      minIMT = arIMT.map((e) => e.y).reduce((a, b) => a < b ? a : b);
      maxIMT = arIMT.map((e) => e.y).reduce((a, b) => a > b ? a : b);
      
      if (maxIMT - minIMT < 5) {
        double center = (minIMT + maxIMT) / 2;
        minIMT = max(0, center - 2.5);
        maxIMT = center + 2.5;
      }
    }

    // Normalisasi data IMT ke skala BB
    List<FlSpot> normalizedIMT = [];
    if (tinggiBadan > 0 && showIMT && arIMT.isNotEmpty) {
      for (var spot in arIMT) {
        if (spot.y.isNaN || !spot.y.isFinite || spot.y <= 0) continue;
        
        double normalizedValue;
        if (maxIMT - minIMT > 0) {
          normalizedValue = ((spot.y - minIMT) / (maxIMT - minIMT)) * (maxBB - minBB) + minBB;
        } else {
          normalizedValue = minBB + (maxBB - minBB) / 2;
        }
        
        normalizedIMT.add(FlSpot(spot.x, normalizedValue));
      }
    }

    // Tambahkan grafik Berat Badan
    if (showBeratBadan && arBeratBadan.isNotEmpty) {
      lineBarsData.add(
        LineChartBarData(
          spots: arBeratBadan,
          isCurved: true,
          gradient: LinearGradient(colors: gradientColors),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: PrimaryColor,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: gradientColors
                  .map((color) => color.withValues(alpha: 0.3))
                  .toList(),
            ),
          ),
        ),
      );
    }

    // Tambahkan grafik IMT
    if (tinggiBadan > 0 && showIMT && normalizedIMT.isNotEmpty) {
      lineBarsData.add(
        LineChartBarData(
          spots: normalizedIMT,
          isCurved: true,
          gradient: LinearGradient(colors: imtGradientColors),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Colors.orange,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(show: false),
        ),
      );
    }

    // Padding dan interval untuk Y axis
    double yPadding = (maxBB - minBB) * 0.15;
    double adjustedMinY = max(0, minBB - yPadding);
    double adjustedMaxY = maxBB + yPadding;
    
    double yRange = adjustedMaxY - adjustedMinY;
    double yInterval = _calculateNiceInterval(yRange / 5);
    
    if (yInterval.isNaN || !yInterval.isFinite || yInterval <= 0) {
      yInterval = 10;
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: yInterval,
        verticalInterval: 1, // Interval grid vertikal tetap 1
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.withValues(alpha: 0.2),
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: Colors.grey.withValues(alpha: 0.1),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: tinggiBadan > 0 && showIMT && arIMT.isNotEmpty,
            reservedSize: 50,
            interval: 1, // Interval akan dikontrol di rightTitleWidgets
            getTitlesWidget: rightTitleWidgets,
          ),
          axisNameWidget: tinggiBadan > 0 && showIMT && arIMT.isNotEmpty
              ? const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 4),
                  child: Text(
                    'IMT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                )
              : null,
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: labelData.isNotEmpty,
            reservedSize: labelData.length > 15 ? 38 : 32,
            interval: 1, // Interval akan dikontrol di bottomTitleWidgets
            getTitlesWidget: bottomTitleWidgets,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            interval: yInterval,
            getTitlesWidget: leftTitleWidgets,
          ),
          axisNameWidget: showBeratBadan
              ? const Padding(
                  padding: EdgeInsets.only(right: 4, bottom: 4),
                  child: Text(
                    'BB (kg)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: PrimaryColor,
                    ),
                  ),
                )
              : null,
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      minX: 0,
      maxX: labelData.isNotEmpty ? (labelData.length - 1).toDouble() : 1,
      minY: adjustedMinY,
      maxY: adjustedMaxY,
      lineBarsData: lineBarsData,
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.blueGrey.withValues(alpha: 0.8),
          tooltipRoundedRadius: 8,
          tooltipPadding: const EdgeInsets.all(8),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              String label = '';
              
              if (spot.barIndex == 0 && showBeratBadan) {
                label = 'BB: ${spot.y.toStringAsFixed(1)} kg';
              } else if (showIMT && arIMT.isNotEmpty) {
                double imtValue;
                if (maxBB - minBB > 0) {
                  imtValue = ((spot.y - minBB) / (maxBB - minBB)) * (maxIMT - minIMT) + minIMT;
                } else {
                  imtValue = minIMT;
                }
                
                label = 'IMT: ${imtValue.toStringAsFixed(1)}';
              }
              
              return LineTooltipItem(
                label,
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  double _calculateNiceInterval(double rawInterval) {
    if (rawInterval.isNaN || !rawInterval.isFinite || rawInterval <= 0) {
      return 10;
    }
    
    double magnitude = pow(10, (log(rawInterval) / ln10).floor()).toDouble();
    double normalized = rawInterval / magnitude;
    
    double niceInterval;
    if (normalized < 1.5) {
      niceInterval = 1 * magnitude;
    } else if (normalized < 3) {
      niceInterval = 2 * magnitude;
    } else if (normalized < 7) {
      niceInterval = 5 * magnitude;
    } else {
      niceInterval = 10 * magnitude;
    }
    
    return niceInterval;
  }
}