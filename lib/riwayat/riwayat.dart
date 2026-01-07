import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:isi_piringku/bloc/nav/bottom_nav.dart';
import 'package:isi_piringku/util/colors.dart';
import 'package:isi_piringku/util/core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:isi_piringku/model/makanan.dart';

import '../model/user.dart';
import '../resources/app_resources.dart';
import '../widgets/legend_widget.dart' as LegendWidget;

class Riwayat extends StatefulWidget {
  const Riwayat({super.key});

  @override
  State<Riwayat> createState() => _RiwayatState();
}

class _RiwayatState extends State<Riwayat> {
  List<dynamic> makananList = [];
  List listBarGroup = [];
  List<dynamic> dataKonsumsi = [];
  Map<String, double> totalCaloriesByDate = {};
  String Id = '';

  DateTime startDate =
      DateTime.now().subtract(const Duration(days: 7)); // 7 hari terakhir
  DateTime endDate = DateTime.now();

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

  final karboColor = KarboColor;
  final laukColor = LaukColor;
  final sayurColor = SayurColor;
  final buahColor = BuahColor;
  final betweenSpace = 0.1;

  BarChartGroupData generateGroupData(
    int x,
    double karbo_val,
    double lauk_val,
    double sayur_val,
    double buah_val,
  ) {
    return BarChartGroupData(
      x: x,
      groupVertically: true,
      barRods: [
        BarChartRodData(
          fromY: 0,
          toY: karbo_val,
          color: karboColor,
          width: 5,
        ),
        BarChartRodData(
          fromY: karbo_val + betweenSpace,
          toY: karbo_val + betweenSpace + lauk_val,
          color: laukColor,
          width: 5,
        ),
        BarChartRodData(
          fromY: karbo_val + betweenSpace + lauk_val + betweenSpace,
          toY: karbo_val + betweenSpace + lauk_val + betweenSpace + sayur_val,
          color: sayurColor,
          width: 5,
        ),
        BarChartRodData(
          fromY: karbo_val +
              betweenSpace +
              lauk_val +
              betweenSpace +
              sayur_val +
              betweenSpace,
          toY: karbo_val +
              betweenSpace +
              lauk_val +
              betweenSpace +
              sayur_val +
              betweenSpace +
              buah_val,
          color: buahColor,
          width: 5,
        ),
      ],
    );
  }

  Widget bottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(fontSize: 10);
    String text;
    text = DateFormat('dd/MM')
        .format(startDate.add(Duration(days: value.toInt())));
    // text = "kj";
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(text, style: style),
    );
  }

  Future<void> fetchData() async {
    String start = DateFormat('yyyy-MM-dd').format(startDate);
    String end = DateFormat('yyyy-MM-dd').format(endDate);
    String url =
        base_url + 'API/Makanan/allKonsumsi?id_user=$Id&start=$start&end=$end';
    final Uri uri = Uri.parse(
        base_url + 'API/Makanan/allKonsumsi?id_user=$Id&start=$start&end=$end');
    final response = await http.get(uri);

    print("response Riwayat");
    print(url);
    print(response.body);

    listBarGroup.clear();

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final responseList = jsonData['resGraf'];
      dataKonsumsi = jsonData['response'];

      int no = 0;
      setState(() {
        responseList.forEach((element) {
          listBarGroup.add(generateGroupData(
              no++,
              double.parse(element['karbo'].toString()),
              double.parse(element['lauk'].toString()),
              double.parse(element['sayur'].toString()),
              double.parse(element['buah'].toString())));
        });
        // listBarGroup.add(generateGroupData(1, 1, 1, 1, 1));
        // listBarGroup.add(generateGroupData(2, 4, 4, 4, 2.4));
        // listBarGroup.add(generateGroupData(3, 3, 5, 3, 1));
      });
    } else {
      print(response.body);
    }
  }

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');

    if (userDataString != null) {
      final userData = UserData.fromJson(json.decode(userDataString));
      print(userData.nama);

      setState(() {
        Id = userData.idUser.toString();
        fetchData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const BottomNavBar(selected: 2),
      body: SingleChildScrollView(
        child: Stack(children: [
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
                                  'Riwayat',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(
                                      "Start Date: ${DateFormat('yyyy-MM-dd').format(startDate)}"),
                                  ElevatedButton(
                                    onPressed: () => _selectStartDate(context),
                                    child: Text("Select Start Date",
                                        style: TextStyle(color: PrimaryColor)),
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
                                    onPressed: () => _selectEndDate(context),
                                    child: const Text("Select End Date",
                                        style: TextStyle(color: PrimaryColor)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 24,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                child: Text(
                                  'Grafik Konsumsi Kalori per Tanggal',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              )
                            ],
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          LegendWidget.LegendsListWidget(
                            legends: [
                              LegendWidget.Legend('Karbo', karboColor),
                              LegendWidget.Legend('Lauk', laukColor),
                              LegendWidget.Legend('Sayur', sayurColor),
                              LegendWidget.Legend('Buah', buahColor),
                            ],
                          ),
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
                                barGroups:
                                    listBarGroup.cast<BarChartGroupData>(),
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
                          ),
                          const SizedBox(
                            height: 24,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                child: Text(
                                  'Riwayat Konsumsi Kalori ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: MediaQuery.of(context).size.height * 0.25,
                            child: ListView(
                              children: dataKonsumsi.map((item) {
                                return Container(
                                  padding: EdgeInsets.all(12),
                                  margin: EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      boxShadow,
                                    ],
                                  ),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['tanggal'],
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                            'Total Kalori : ${item['kalori']}'),
                                      ]),
                                );
                              }).toList(),
                            ),
                          ),
                          Container(
                            height: 5,
                            width: double.infinity,
                            child: ListView.separated(
                              itemCount: totalCaloriesByDate
                                  .length, // Jumlah item adalah jumlah tanggal unik
                              separatorBuilder:
                                  (BuildContext context, int index) =>
                                      const Divider(),
                              itemBuilder: (BuildContext context, int index) {
                                String dateKey =
                                    totalCaloriesByDate.keys.elementAt(index);
                                double? totalCaloriesForDate =
                                    totalCaloriesByDate[dateKey];

                                return ListTile(
                                  title: Text("Tanggal: $dateKey"),
                                  subtitle: Text(
                                    "Total Kalori: $totalCaloriesForDate",
                                  ),
                                );
                              },
                            ),
                          ),
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

  List<Map<String, dynamic>> _getChartData() {
    List<Map<String, dynamic>> chartData = [];

    // Iterate melalui data makanan yang sudah difilter
    for (String dateKey in totalCaloriesByDate.keys) {
      double? totalCalories = totalCaloriesByDate[dateKey];

      chartData.add({
        'date': dateKey,
        'totalCalories': totalCalories,
      });
    }

    return chartData;
  }
}
