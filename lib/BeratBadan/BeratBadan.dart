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
    
    // Validasi jika id kosong
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
          
          // Validasi jika data tidak null
          if (data != null && data is List) {
            for (var i = 0; i < data.length; i++) {
              try {
                double beratBadan = double.tryParse(data[i]['bb'].toString()) ?? 0.0;
                arBeratBadan.add(FlSpot(i.toDouble(), beratBadan));

                // Hitung IMT jika tinggi badan tersedia
                if (tinggiBadan > 0) {
                  double tinggiMeter = tinggiBadan / 100;
                  // Validasi untuk menghindari pembagian dengan 0
                  if (tinggiMeter > 0) {
                    double imt = beratBadan / (tinggiMeter * tinggiMeter);
                    // Pastikan IMT bukan NaN atau Infinity
                    if (!imt.isNaN && imt.isFinite) {
                      arIMT.add(FlSpot(i.toDouble(), imt));
                    }
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
    if (imt.isNaN || !imt.isFinite) return 'Invalid';
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
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Container(
              margin: const EdgeInsets.only(left: 16, right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 16),

                  // Header dengan toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Grafik Berat Badan & IMT",
                          style: TextStyle(
                            color: TextColordark,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          )),
                      Column(
                        children: [
                          // Toggle untuk Berat Badan
                          Row(
                            children: [
                              const Text("BB", style: TextStyle(fontSize: 12)),
                              Switch(
                                value: showBeratBadan,
                                onChanged: (value) {
                                  setState(() {
                                    showBeratBadan = value;
                                  });
                                },
                                activeThumbColor: PrimaryColor,
                              ),
                            ],
                          ),
                          // Toggle untuk IMT (hanya jika tinggi badan tersedia)
                          if (tinggiBadan > 0)
                            Row(
                              children: [
                                const Text("IMT", style: TextStyle(fontSize: 12)),
                                Switch(
                                  value: showIMT,
                                  onChanged: (value) {
                                    setState(() {
                                      showIMT = value;
                                    });
                                  },
                                  activeThumbColor: PrimaryColor,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),

                  // Info tinggi badan
                  if (tinggiBadan > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        "Tinggi Badan: ${tinggiBadan.toStringAsFixed(0)} cm",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                              margin: const EdgeInsets.only(top: 16),
                              padding: const EdgeInsets.only(top: 8),
                              decoration: BoxDecoration(
                                color: BackgroundColorWhite,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  boxShadowWhite,
                                ],
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding:
                                        const EdgeInsets.only(left: 20, right: 20),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Text(
                                                "Start: ${DateFormat('dd-MM-yy').format(startDate)}",
                                                style: const TextStyle(fontSize: 12)),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AccentColor,
                                                foregroundColor: TextColorLight,
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 12, vertical: 8),
                                                elevation: 2,
                                              ),
                                              onPressed: () =>
                                                  _selectStartDate(context),
                                              child: const Text("Pilih Tanggal",
                                                  style: TextStyle(
                                                      fontSize: 11)),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Text(
                                                "End: ${DateFormat('dd-MM-yy').format(endDate)}",
                                                style: const TextStyle(fontSize: 12)),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AccentColor,
                                                foregroundColor: TextColorLight,
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 12, vertical: 8),
                                                elevation: 2,
                                              ),
                                              onPressed: () =>
                                                  _selectEndDate(context),
                                              child: const Text("Pilih Tanggal",
                                                  style: TextStyle(
                                                      fontSize: 11)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Legend
                                  if (showBeratBadan ||
                                      (tinggiBadan > 0 && showIMT))
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 8),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          if (showBeratBadan)
                                            Row(
                                              children: [
                                                Container(
                                                  width: 20,
                                                  height: 3,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                        colors: gradientColors),
                                                    borderRadius:
                                                        BorderRadius.circular(2),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                const Text("BB (kg)",
                                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                                              ],
                                            ),
                                          if (tinggiBadan > 0 && showIMT)
                                            Row(
                                              children: [
                                                Container(
                                                  width: 20,
                                                  height: 3,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                        colors: imtGradientColors),
                                                    borderRadius:
                                                        BorderRadius.circular(2),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                const Text("IMT",
                                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),

                                  AspectRatio(
                                    aspectRatio: 1.4,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          left: 8, right: 24, top: 16, bottom: 8),
                                      child: (showBeratBadan ||
                                              (tinggiBadan > 0 && showIMT))
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

                                  // IMT Categories Info
                                  if (tinggiBadan > 0 &&
                                      showIMT &&
                                      arIMT.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Kategori IMT:",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            children: [
                                              _buildIMTCategory(
                                                  "Kurus", "< 18.5", Colors.blue),
                                              _buildIMTCategory("Normal",
                                                  "18.5-24.9", Colors.green),
                                              _buildIMTCategory("Gemuk", "25-29.9",
                                                  Colors.orange),
                                              _buildIMTCategory(
                                                  "Obesitas", "≥ 30", Colors.red),
                                            ],
                                          ),
                                          if (arIMT.isNotEmpty)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 12),
                                              child: Text(
                                                "IMT Terakhir: ${arIMT.last.y.isNaN || !arIMT.last.y.isFinite ? "Invalid" : arIMT.last.y.toStringAsFixed(1)} - ${getIMTCategory(arIMT.last.y)}",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: getIMTColor(arIMT.last.y),
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                ],
                              )),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TambahBB(),
                              ));
                        },
                        child: Container(
                          height: 110,
                          decoration: BoxDecoration(
                            color: BackgroundColorWhite,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              boxShadowWhite,
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.topLeft,
                            children: <Widget>[
                              ClipRRect(
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(16.0)),
                                child: SizedBox(
                                  height: 90,
                                  child: AspectRatio(
                                    aspectRatio: 1.714,
                                    child:
                                        Image.asset("assets/images/back.png"),
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Row(
                                    children: <Widget>[
                                      Padding(
                                        padding: EdgeInsets.only(
                                          left: 110,
                                          right: 16,
                                          top: 29,
                                        ),
                                        child: Text(
                                          "Berapa Berat Kamu Hari Ini ?",
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                            letterSpacing: 0.0,
                                            color: PrimaryColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 110,
                                      bottom: 12,
                                      top: 4,
                                      right: 16,
                                    ),
                                    child: Text(
                                      "Tambah Berat Badan\nSimpan riwayat berat badan Anda untuk Analisa!",
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 10,
                                        letterSpacing: 0.0,
                                        color:
                                            Colors.grey.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Positioned(
                                top: 0,
                                left: 0,
                                child: SizedBox(
                                  width: 110,
                                  height: 110,
                                  child:
                                      Image.asset("assets/images/runner.png"),
                                ),
                              )
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          )),
    );
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 9,
      color: Colors.black87,
    );
    
    // Validasi index dengan lebih ketat
    int index = value.toInt();
    
    // Pastikan index valid dan bukan NaN atau Infinity
    if (index.isNaN || !index.isFinite || 
        index < 0 || 
        index >= labelData.length ||
        labelData.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Untuk data banyak, tampilkan label secara selektif
    if (labelData.length > 10 && index % 2 != 0) {
      return const SizedBox.shrink();
    }
    
    String label;
    try {
      label = labelData[index].toString();
    } catch (e) {
      label = "";
    }
    
    // Rotasi label jika terlalu banyak data
    Widget text = Transform.rotate(
      angle: labelData.length > 10 ? -0.5 : 0,
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
      space: 4,
      child: text,
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 10,
      color: Colors.black87,
    );
    
    // Validasi nilai
    if (value.isNaN || !value.isFinite) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.only(right: 4),
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
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
        Text(
          range,
          style: const TextStyle(fontSize: 9, color: Colors.grey),
        ),
      ],
    );
  }

  LineChartData mainData() {
    List<LineChartBarData> lineBarsData = [];

    // Validasi data
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
      
      // Pastikan range minimal
      if (maxBB - minBB < 10) {
        maxBB = minBB + 10;
      }
    }

    // Hitung min dan max untuk IMT
    double minIMT = 0;
    double maxIMT = 50;
    
    if (tinggiBadan > 0 && showIMT && arIMT.isNotEmpty) {
      minIMT = arIMT.map((e) => e.y).reduce((a, b) => a < b ? a : b);
      maxIMT = arIMT.map((e) => e.y).reduce((a, b) => a > b ? a : b);
      
      // Pastikan range minimal
      if (maxIMT - minIMT < 5) {
        maxIMT = minIMT + 5;
      }
    }

    // Normalisasi data IMT ke skala BB untuk visualisasi yang lebih baik
    List<FlSpot> normalizedIMT = [];
    if (tinggiBadan > 0 && showIMT && arIMT.isNotEmpty) {
      for (var spot in arIMT) {
        // Validasi nilai IMT
        if (spot.y.isNaN || !spot.y.isFinite) continue;
        
        // Konversi IMT (0-50) ke skala BB
        double normalizedValue;
        if (maxIMT - minIMT > 0) {
          normalizedValue = ((spot.y - minIMT) / (maxIMT - minIMT)) * (maxBB - minBB) + minBB;
        } else {
          normalizedValue = minBB + (maxBB - minBB) / 2;
        }
        
        normalizedIMT.add(FlSpot(spot.x, normalizedValue));
      }
    }

    // Tambahkan grafik Berat Badan jika diaktifkan
    if (showBeratBadan && arBeratBadan.isNotEmpty) {
      lineBarsData.add(
        LineChartBarData(
          spots: arBeratBadan,
          isCurved: true,
          gradient: LinearGradient(
            colors: gradientColors,
          ),
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

    // Tambahkan grafik IMT jika tersedia dan diaktifkan (gunakan data yang dinormalisasi)
    if (tinggiBadan > 0 && showIMT && normalizedIMT.isNotEmpty) {
      lineBarsData.add(
        LineChartBarData(
          spots: normalizedIMT,
          isCurved: true,
          gradient: LinearGradient(
            colors: imtGradientColors,
          ),
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
          belowBarData: BarAreaData(
            show: false,
          ),
        ),
      );
    }

    // Tentukan padding untuk Y axis
    double yPadding = (maxBB - minBB) * 0.15;
    double adjustedMinY = (minBB - yPadding).clamp(0, double.infinity);
    double adjustedMaxY = maxBB + yPadding;
    
    // Hitung interval yang baik untuk Y axis
    double yRange = adjustedMaxY - adjustedMinY;
    double yInterval = _calculateNiceInterval(yRange / 5);
    
    // Pastikan interval valid
    if (yInterval.isNaN || !yInterval.isFinite || yInterval <= 0) {
      yInterval = 10;
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: yInterval,
        verticalInterval: labelData.length <= 10 ? 1 : 2,
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
            reservedSize: 45,
            interval: _calculateNiceInterval((maxIMT - minIMT) / 5),
            getTitlesWidget: (value, meta) {
              // Validasi nilai
              if (value.isNaN || !value.isFinite) {
                return const SizedBox.shrink();
              }
              
              // Konversi nilai normalized kembali ke IMT untuk label
              double imtValue;
              if (maxBB - minBB > 0) {
                imtValue = ((value - minBB) / (maxBB - minBB)) * (maxIMT - minIMT) + minIMT;
              } else {
                imtValue = minIMT;
              }
              
              // Validasi imtValue
              if (imtValue.isNaN || !imtValue.isFinite) {
                return const SizedBox.shrink();
              }
              
              // Hanya tampilkan label yang dalam range
              if (imtValue < minIMT - 1 || imtValue > maxIMT + 1) {
                return const SizedBox.shrink();
              }
              
              return Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  imtValue.toStringAsFixed(0),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    color: Colors.orange,
                  ),
                  textAlign: TextAlign.left,
                ),
              );
            },
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
            reservedSize: 32,
            interval: labelData.length <= 10 ? 1 : 2,
            getTitlesWidget: bottomTitleWidgets,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
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
              Color color = Colors.white;
              
              if (spot.barIndex == 0 && showBeratBadan) {
                // BB tooltip
                label = 'BB: ${spot.y.toStringAsFixed(1)} kg';
                color = Colors.white;
              } else if (showIMT && arIMT.isNotEmpty) {
                // IMT tooltip - konversi nilai normalized kembali ke IMT asli
                double imtValue;
                if (maxBB - minBB > 0) {
                  imtValue = ((spot.y - minBB) / (maxBB - minBB)) * (maxIMT - minIMT) + minIMT;
                } else {
                  imtValue = minIMT;
                }
                
                label = 'IMT: ${imtValue.toStringAsFixed(1)}';
                color = Colors.white;
              }
              
              return LineTooltipItem(
                label,
                TextStyle(
                  color: color,
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

  // Helper function untuk menghitung interval yang bagus
  double _calculateNiceInterval(double rawInterval) {
    if (rawInterval.isNaN || !rawInterval.isFinite || rawInterval <= 0) {
      return 10;
    }
    
    // Bulatkan ke nilai yang "nice" (1, 2, 5, 10, 20, 50, dll)
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