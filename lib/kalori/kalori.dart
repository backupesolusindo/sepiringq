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
  double totalEnergi = 0.0;
  String Id = '';
  String KebutuhanKalori = '0';
  String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String clientId = "PKL2023";
  String clientSecret = "PKLSERU";



  @override
  void initState() {
    super.initState();
    loadUserDataAndFetchData();
    fetchData2();
  }

  Future<void> fetchData2() async {
    setState(() {
      isLoading = true;
    });
    final Uri apiUrl2 = Uri.parse(base_url + 'API/JadwalMakan/jadwal');
    final response = await http.get(apiUrl2);
    print("Response Jadwal Makanan");
    print(response.body);
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> responseList = data['response'];
      setState(() {
        isLoading = false;
        articles2 = responseList;
      });
    } else {
      throw Exception('Failed to load data from API');
    }
  }

 

  Future<void> loadUserDataAndFetchData() async {
    await loadUserData(); // Menunggu hingga loadUserData selesai
    fetchData(); // Panggil fetchData setelah Id diisi
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
      // Pastikan Id tidak kosong sebelum membuat permintaan http
      return;
    }

    print(Id);
    String fetkal =
        base_url + "API/Makanan/konsumsi?id_user=$Id&waktu=$formattedDate";
    final response = await http.get(
      Uri.parse(fetkal),
    );

    print("Response Konsumsi");
    print(response.body);
    print(Id);

    if (response.statusCode == 200) {
      print(Uri.parse);
      final jsonResponse = json.decode(response.body);
      print(jsonResponse);

      setState(() {
        data = jsonResponse['response'];
        KebutuhanKalori = jsonResponse['dataUser']['kalori'];
        // Hitung total energi
        totalEnergi = data
            .map((item) => double.parse(item['kalori']))
            .fold(0.0, (prev, curr) => prev + curr); // Change 0 to 0.0
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  List<dynamic> dataKonsumsi = [];

  Future<void> fetchDataKonsumsi(String keterangan) async {
    if (Id.isEmpty) {
      // Pastikan Id tidak kosong sebelum membuat permintaan http
      return;
    }

    print(Id);
    String fetkal = base_url +
        "api/Makanan/konsumsi?id_user=$Id&waktu=$formattedDate&keterangan=$keterangan";
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
        showMaterialModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (context) => mDetailKalori());
      });
    } else {
      throw Exception('Failed to load data');
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
      // Pastikan Id tidak kosong sebelum membuat permintaan http
      return;
    }

    print(Id);
    String fetkal = base_url +
        "api/Makanan/kalorikonsumsi?id_user=$Id&waktu=$formattedDate&keterangan=$keterangan";
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
        //pembulatan 2 angka dibelakang koma
        totalKarbohidrat = double.parse(totalKarbohidrat.toStringAsFixed(2));
        totalLemak = double.parse(totalLemak.toStringAsFixed(2));
        totalProtein = double.parse(totalProtein.toStringAsFixed(2));
        totalZatBesi = double.parse(totalZatBesi.toStringAsFixed(2));
        totalVitaminA = double.parse(totalVitaminA.toStringAsFixed(2));
        totalVitaminC = double.parse(totalVitaminC.toStringAsFixed(2));
        totalKebutuhanKonsumsi =
            int.parse(jsonResponse['datauser']['konsumsi_kalori'].toString());
        persentaseKecukupanKalori =
            int.parse(jsonResponse['datauser']['persentase_kalori'].toString());
        keteranganKalori = jsonResponse['datauser']['keterangan'];

        dataMap = {
          "Total Karbohidrat : $totalKarbohidrat": totalKarbohidrat,
          "Total Lemak : $totalLemak": totalLemak,
          "Total Protein : $totalProtein": totalProtein,
          "Total Zat Besi : $totalZatBesi": totalZatBesi,
          "Total Vitamin A : $totalVitaminA": totalVitaminA,
          "Total Vitamin C : $totalVitaminC": totalVitaminC,
        };

        showMaterialModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (context) => mGrafikKalori());
      });
    } else {
      throw Exception('Failed to load data');
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
                              const Icon(
                                Icons.calendar_month,
                                color: Colors.redAccent,
                                size: 30,
                              ),
                              const SizedBox(
                                width: 20,
                              ),
                              Container(
                                alignment: Alignment.center,
                                width: 100,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  formattedDate,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              )
                            ]),
                          ),
                          const SizedBox(
                            height: 30,
                          ),
                          Container(
                            padding: const EdgeInsets.only(left: 15, right: 15),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  child: Text(
                                    'Budget Kalori Harian\n' +
                                        KebutuhanKalori +
                                        ' Kkal',
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
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
                                      ? CircularProgressIndicator()
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
                          const SizedBox(
                            height: 20,
                          ),
                          Container(
                            height: 350,
                            child: ListView(
                              children: articles2.map((article2) {
                                final String imageUrl2 = article2['gambar'];
                                String keterangan = article2['nama'];
                                String judul2 = article2['nama'];
                                double jmlKalori = 0;
                                // string lowercase
                                data.forEach((item) {
                                  if (item['keterangan'].toLowerCase() ==
                                      judul2.toLowerCase()) {
                                    jmlKalori += double.parse(item['kalori']);
                                  }
                                });
                                if (jmlKalori > 0) {
                                  judul2 += "\n(" +
                                      jmlKalori.toStringAsFixed(2) +
                                      ")";
                                }

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(15.0),
                                      boxShadow: [boxShadow]),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                            child: Image.network(
                                          imageUrl2,
                                          width:
                                              100, // Sesuaikan dengan ukuran gambar yang Anda inginkan
                                          height:
                                              50, // Sesuaikan dengan ukuran gambar yang Anda inginkan
                                        )),
                                        Expanded(
                                            child: Text(
                                          judul2,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )),
                                        jmlKalori > 0
                                            ? Expanded(
                                                child: Row(children: [
                                                IconButton(
                                                  icon: Icon(Icons.info,
                                                      color: SecondaryColor),
                                                  onPressed: () {
                                                    fetchDataKonsumsi(
                                                        keterangan);
                                                  },
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                      Icons.analytics_outlined,
                                                      color: PrimaryColor),
                                                  onPressed: () {
                                                    fetchGrafikKonsumsi(
                                                        keterangan);
                                                  },
                                                )
                                              ]))
                                            : Expanded(
                                                child: IconButton(
                                                icon: Icon(Icons.add,
                                                    color: PrimaryColor),
                                                onPressed: () {
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            TambahKalori(
                                                                keterangan:
                                                                    judul2),
                                                      ));
                                                },
                                              )),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          Container(
                            // Tinggi container
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 50,
                                ),
                                // Center(
                                //     child: ElevatedButton(
                                //         onPressed: () {
                                //           data.forEach((item) {
                                //             final namaMakanan =
                                //                 item['nama_makanan'];
                                //             if (!groupedData
                                //                 .containsKey(namaMakanan)) {
                                //               groupedData[namaMakanan] = [item];
                                //             } else {
                                //               groupedData[namaMakanan]
                                //                   ?.add(item);
                                //             }
                                //           });
                                //           showDialog(
                                //             context: context,
                                //             builder: (BuildContext context) {
                                //               return AlertDialog(
                                //                 title: Text(
                                //                   'Riwayat Hari Ini',
                                //                   textAlign: TextAlign.center,
                                //                 ),
                                //                 content: SingleChildScrollView(
                                //                   child: Column(
                                //                     children: groupedData
                                //                         .entries
                                //                         .map((entry) {
                                //                       final namaMakanan =
                                //                           entry.key;
                                //                       final makananList =
                                //                           entry.value;
                                //                       final jumlahMakanan =
                                //                           makananList.length;
                                //                       final totalEnergi = makananList
                                //                           .map((item) =>
                                //                               double.parse(item[
                                //                                   'energi']))
                                //                           .fold(
                                //                               0.0,
                                //                               (prev, curr) =>
                                //                                   prev + curr);

                                //                       return ListTile(
                                //                         title: Text(
                                //                             '$namaMakanan (x$jumlahMakanan)'),
                                //                         subtitle: Text(
                                //                             'Total Energi: ${totalEnergi.toInt()}'),
                                //                       );
                                //                     }).toList(),
                                //                   ),
                                //                 ),
                                //                 actions: <Widget>[
                                //                   Text(
                                //                       'Total Energi: ${totalEnergi.toInt()}'),
                                //                   ElevatedButton(
                                //                     onPressed: () {
                                //                       Navigator.of(context)
                                //                           .pop();
                                //                     },
                                //                     child: Text('Tutup'),
                                //                   ),
                                //                 ],
                                //               );
                                //             },
                                //           );
                                //         },
                                //         child: Text('Riwayat Hari Ini')))
                              ],
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

  Widget mDetailKalori() {
    var size = MediaQuery.of(context).size;
    return Container(
      height: size.height * 0.6,
      width: size.width,
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20), topRight: Radius.circular(20))),
      child: Column(
        children: [
          const SizedBox(
            height: 20,
          ),
          const Text(
            'Detail Kalori',
            style: TextStyle(
                color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: ListView(
              children: dataKonsumsi.map((item) {
                return Container(
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      boxShadow,
                    ],
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['nama_makanan'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text('Energi: ${item['kalori']}'),
                      ]),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget mGrafikKalori() {
    var size = MediaQuery.of(context).size;
    return Container(
      height: size.height * 0.6,
      width: size.width,
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20), topRight: Radius.circular(20))),
      child: Column(
        children: [
          SizedBox(
            height: 16,
          ),
          Text(
            'Analisis Kalori',
            style: TextStyle(
                color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Container(
            margin: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
                ),
              ),
              chartValuesOptions: ChartValuesOptions(
                showChartValueBackground: false,
                showChartValues: true,
                showChartValuesInPercentage: false,
                showChartValuesOutside: false,
                decimalPlaces: 2,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Kalori',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Kebutuhan Kalori',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Persentase Kecukupan Kalori',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ': ${totalKaloriKonsumsi.toInt()} Kkal',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                  ),
                  Text(
                    ': ${totalKebutuhanKonsumsi.toInt()} Kkal',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                  ),
                  Text(
                    ': ${persentaseKecukupanKalori.toInt()}%',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(
            height: 24,
          ),
          Text(
            'Keterangan Kalori',
            style: TextStyle(
                color: Colors.black, fontSize: 20, fontWeight: FontWeight.w600),
          ),
          Text(
            '$keteranganKalori',
            style: TextStyle(
                color: Colors.black, fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
