import 'dart:convert';

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
    }
  }

  List<FlSpot> arBeratBadan = [];
  List<FlSpot> arIMT = [];
  List labelData = [];

  Future<void> fetchData() async {
    String start = DateFormat('yyyy-MM-dd').format(startDate);
    String end = DateFormat('yyyy-MM-dd').format(endDate);
    if (id.isEmpty) {
      return;
    }

    arBeratBadan = [];
    arIMT = [];

    String fetchUrl =
        "${base_url}api/BeratBadan/getBeratBadan?id_user=$id&start=$start&end=$end";
    final response = await http.get(Uri.parse(fetchUrl));

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      setState(() {
        var data = jsonResponse['response']['dataGraf'];
        labelData = jsonResponse['response']['dataLabel'];
        for (var i = 0; i < data.length; i++) {
          double beratBadan = double.parse(data[i]['bb']);
          arBeratBadan.add(FlSpot(i.toDouble(), beratBadan));

          // Hitung IMT jika tinggi badan tersedia
          if (tinggiBadan > 0) {
            double tinggiMeter = tinggiBadan / 100;
            double imt = beratBadan / (tinggiMeter * tinggiMeter);
            arIMT.add(FlSpot(i.toDouble(), imt));
          }
        }
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  String getIMTCategory(double imt) {
    if (imt < 18.5) return 'Kurus';
    if (imt < 25.0) return 'Normal';
    if (imt < 30.0) return 'Gemuk';
    return 'Obesitas';
  }

  Color getIMTColor(double imt) {
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
    loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BERAT BADAN',
          style: TextStyle(
            color: TextColordark,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(selected: 5),
      body: Container(
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              boxShadow,
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
                                            "Start Date: ${DateFormat('yyyy-MM-dd').format(startDate)}"),
                                        ElevatedButton(
                                          onPressed: () =>
                                              _selectStartDate(context),
                                          child: const Text("Select Start Date",
                                              style: TextStyle(
                                                  color: PrimaryColor)),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Text(
                                            "End Date: ${DateFormat('dd-MM-yyyy').format(endDate)}"),
                                        ElevatedButton(
                                          onPressed: () =>
                                              _selectEndDate(context),
                                          child: const Text("Select End Date",
                                              style: TextStyle(
                                                  color: PrimaryColor)),
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
                                              width: 16,
                                              height: 3,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                    colors: gradientColors),
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Text("Berat Badan (kg)",
                                                style: TextStyle(fontSize: 12)),
                                          ],
                                        ),
                                      if (tinggiBadan > 0 && showIMT)
                                        Row(
                                          children: [
                                            Container(
                                              width: 16,
                                              height: 3,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                    colors: imtGradientColors),
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Text("IMT",
                                                style: TextStyle(fontSize: 12)),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),

                              AspectRatio(
                                aspectRatio: 1.5,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      left: 0, right: 24, top: 16, bottom: 8),
                                  child: (showBeratBadan ||
                                          (tinggiBadan > 0 && showIMT))
                                      ? LineChart(mainData())
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
                                            "IMT Terakhir: ${arIMT.last.y.toStringAsFixed(1)} - ${getIMTCategory(arIMT.last.y)}",
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              boxShadow,
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.topLeft,
                            children: <Widget>[
                              ClipRRect(
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(8.0)),
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
      fontSize: 11,
    );
    String label = (labelData.isNotEmpty) ? labelData[value.toInt()] : "";
    Widget text;
    text = Text(
      label,
      style: style,
    );

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: text,
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

    // Tambahkan grafik Berat Badan jika diaktifkan
    if (showBeratBadan) {
      lineBarsData.add(
        LineChartBarData(
          spots: arBeratBadan,
          isCurved: true,
          gradient: LinearGradient(
            colors: gradientColors,
          ),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(
            show: true,
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

    // Tambahkan grafik IMT jika tersedia dan diaktifkan
    if (tinggiBadan > 0 && showIMT && arIMT.isNotEmpty) {
      lineBarsData.add(
        LineChartBarData(
          spots: arIMT,
          isCurved: true,
          gradient: LinearGradient(
            colors: imtGradientColors,
          ),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(
            show: true,
          ),
          belowBarData: BarAreaData(
            show: false,
          ),
        ),
      );
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 1,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return const FlLine(
            color: AppColors.mainGridLineColor,
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return const FlLine(
            color: AppColors.mainGridLineColor,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: bottomTitleWidgets,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 42,
            interval: showIMT && arIMT.isNotEmpty ? 5 : 10,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: const Color(0xff37434d)),
      ),
      minX: 0,
      minY: 0,
      maxY: showIMT && arIMT.isNotEmpty ? 150 : 150,
      lineBarsData: lineBarsData,
    );
  }

  // LineChartData avgData() {
  //   return LineChartData(
  //     lineTouchData: const LineTouchData(enabled: false),
  //     gridData: FlGridData(
  //       show: true,
  //       drawHorizontalLine: true,
  //       verticalInterval: 1,
  //       horizontalInterval: 1,
  //       getDrawingVerticalLine: (value) {
  //         return const FlLine(
  //           color: Color(0xff37434d),
  //           strokeWidth: 1,
  //         );
  //       },
  //       getDrawingHorizontalLine: (value) {
  //         return const FlLine(
  //           color: Color(0xff37434d),
  //           strokeWidth: 1,
  //         );
  //       },
  //     ),
  //     titlesData: FlTitlesData(
  //       show: true,
  //       bottomTitles: AxisTitles(
  //         sideTitles: SideTitles(
  //           showTitles: true,
  //           reservedSize: 30,
  //           getTitlesWidget: bottomTitleWidgets,
  //           interval: 1,
  //         ),
  //       ),
  //       leftTitles: AxisTitles(
  //         sideTitles: SideTitles(
  //           showTitles: true,
  //           getTitlesWidget: leftTitleWidgets,
  //           reservedSize: 42,
  //           interval: 1,
  //         ),
  //       ),
  //       topTitles: const AxisTitles(
  //         sideTitles: SideTitles(showTitles: false),
  //       ),
  //       rightTitles: const AxisTitles(
  //         sideTitles: SideTitles(showTitles: false),
  //       ),
  //     ),
  //     borderData: FlBorderData(
  //       show: true,
  //       border: Border.all(color: const Color(0xff37434d)),
  //     ),
  //     minX: 0,
  //     maxX: 11,
  //     minY: 0,
  //     maxY: 6,
  //     lineBarsData: [
  //       LineChartBarData(
  //         spots: const [
  //           FlSpot(0, 3.44),
  //           FlSpot(2.6, 3.44),
  //           FlSpot(4.9, 3.44),
  //           FlSpot(6.8, 3.44),
  //           FlSpot(8, 3.44),
  //           FlSpot(9.5, 3.44),
  //           FlSpot(11, 3.44),
  //         ],
  //         isCurved: true,
  //         gradient: LinearGradient(
  //           colors: [
  //             ColorTween(begin: gradientColors[0], end: gradientColors[1])
  //                 .lerp(0.2)!,
  //             ColorTween(begin: gradientColors[0], end: gradientColors[1])
  //                 .lerp(0.2)!,
  //           ],
  //         ),
  //         barWidth: 5,
  //         isStrokeCapRound: true,
  //         dotData: const FlDotData(
  //           show: false,
  //         ),
  //         belowBarData: BarAreaData(
  //           show: true,
  //           gradient: LinearGradient(
  //             colors: [
  //               ColorTween(begin: gradientColors[0], end: gradientColors[1])
  //                   .lerp(0.2)!
  //                   .withOpacity(0.1),
  //               ColorTween(begin: gradientColors[0], end: gradientColors[1])
  //                   .lerp(0.2)!
  //                   .withOpacity(0.1),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }
}
