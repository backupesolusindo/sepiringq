import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:isi_piringku/bloc/nav/bottom_nav.dart';
import 'package:isi_piringku/kalori/kalori.dart';
import 'package:isi_piringku/model/user.dart';
import 'package:isi_piringku/util/colors.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../util/core.dart';

class TambahKalori extends StatefulWidget {
  TambahKalori({Key? key, required this.keterangan});

  String keterangan;

  @override
  State<TambahKalori> createState() => _TambahKaloriState();
}

class _TambahKaloriState extends State<TambahKalori> {
  List<int> cardValues = [];
  List<Map<String, dynamic>> selectedFoods = [];

  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> filteredFoodData = [];
  String clientId = "PKL2023";
  String clientSecret = "PKLSERU";
  String tokenUrl = base_url + "api/Token/token";
  String apiUrl = base_url + "api/Konsumsi/Konsumsi";
  String accessToken = "";
  List<Map<String, dynamic>> foodData = [];
  bool isSearching = false;
  int cardValue = 0;
  String Id = '';

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

  Future<void> getToken() async {
    try {
      // Buat permintaan untuk mendapatkan token menggunakan client_credentials
      var response = await http.post(
        Uri.parse(tokenUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'client_credentials',
          'client_id': clientId,
          'client_secret': clientSecret,
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> tokenData = jsonDecode(response.body);
        accessToken = tokenData['access_token'];
        print('Token Akses: $accessToken');
      } else {
        // Handle error, misalnya, menampilkan pesan kesalahan
        print('Gagal mendapatkan token: ${response.statusCode}');
      }
    } catch (e) {
      // Handle exception, misalnya, menampilkan pesan kesalahan
      print('Gagal mendapatkan token: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchData() async {
    final response = await http.get(
      Uri.parse(base_url + 'api/Makanan/makanan'),
      headers: {
        'Authorization':
            'Bearer $accessToken', // Use the access token obtained from getToken()
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body)['response'];
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  void initState() {
    super.initState();
    loadUserData();
    getToken().then((_) {
      fetchData().then((data) {
        setState(() {
          foodData = data;
          filteredFoodData = data; // Menginisialisasi dengan data asli

          // Inisialisasi cardValues dengan panjang yang sesuai
          cardValues = List.filled(foodData.length, 0);
        });
      });
    });
  }

  void filterFoodList(String query) {
    setState(() {
      if (query.isNotEmpty) {
        isSearching = true;
        filteredFoodData = foodData.where((foodItem) {
          final namaMakanan = foodItem['nama_makanan'].toString().toLowerCase();
          return namaMakanan.contains(query.toLowerCase());
        }).toList();
      } else {
        isSearching = false;
        filteredFoodData = foodData;
      }
    });
  }

  Future<void> kirimData() async {
    try {
      var jumlahDipilih = [];
      double energi = 0;
      var idMakanan = [];
      selectedFoods.forEach((selectedFood) async {
        jumlahDipilih.add(selectedFood['jumlahDipilih']);
        idMakanan.add(selectedFood['id_makanan']);
        energi += selectedFood['jumlahDipilih'] *
            double.tryParse(selectedFood['energi'].toString());
      });

      var response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id_user': Id,
          'total_kalori': energi,
          'keterangan': widget.keterangan,
          'bahan_makanan_nama_makanan': idMakanan,
          'kuantitas': jumlahDipilih
        }),
      );

      print('Response Simpan Data');
      print(response.body);
      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: 'Berhasil Kirim Data',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        Navigator.pop(context);
      } else {
        print('Gagal mengirim data: ${response.statusCode}');
      }
    } catch (e) {
      print('Gagal mengirim data: $e');
    }
  }

  Future<void> TambahMakanan(String idMakanan, int index) async {
    debugPrint("ID Makanan: $idMakanan");
    // get index from array foodData by idMakanan
    var index = foodData.indexWhere((food) => food['id_makanan'] == idMakanan);
    var energi = foodData[index]['energi'].toString();

    setState(() {
      cardValues[index] += 1;
    });

    var selectedFood = selectedFoods.firstWhereOrNull(
      (food) => food['id_makanan'] == idMakanan,
    );

    if (selectedFood == null) {
      // Jika makanan belum ada di dalam selectedFoods, tambahkan makanan tersebut
      selectedFoods.add({
        ...foodData[index],
        'jumlahDipilih': 1,
      });
    } else {
      // Jika makanan sudah ada di dalam selectedFoods, tambahkan 1 ke properti jumlahDipilih
      selectedFood['jumlahDipilih'] += 1;
    }

    Fluttertoast.showToast(
      msg: 'Berhasil Menambahkan Data',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavBar(selected: 1),
      appBar: AppBar(
        title: Text('Tambah Kalori Harian'),
        backgroundColor: SecondaryColor,
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: "Tambah Kalori",
        onPressed: () {
          kirimData();
        },
        child: Icon(Icons.save),
        backgroundColor: SecondaryColor,
      ),
      body: SingleChildScrollView(
        child: Stack(children: [
          SafeArea(
            child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.0),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'Makan Apa Hari Ini?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(left: 20, right: 20),
                            child: TextFormField(
                              onTap: () {
                                FocusScope.of(context)
                                    .requestFocus(FocusNode());
                                showMaterialModalBottomSheet(
                                    context: context,
                                    builder: (context) => mCariMakan());
                              },
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                prefixIcon: Icon(Icons.search),
                                hintText: "Cari makanan",
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Container(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'Makanan yang Dipilih',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: selectedFoods.length,
                            itemBuilder: (context, index) {
                              final selectedFood = selectedFoods[index];
                              final namaMakanan = selectedFood['nama_makanan'];

                              // Mengambil energi dari selectedFood sebagai String
                              final energiString = selectedFood['energi'];

                              // Mengonversi energiString ke tipe data int jika angka yang valid
                              final energi =
                                  double.tryParse(energiString) ?? 0.0;

                              final jumlahDipilih =
                                  selectedFood['jumlahDipilih'] as int;

                              // Melakukan perhitungan energi * jumlahDipilih
                              final totalEnergi = energi * jumlahDipilih;
                              print('energiString: $energiString');
                              print('jumlahDipilih: $jumlahDipilih');
                              print('totalEnergi: $totalEnergi');

                              return Container(
                                  padding: EdgeInsets.all(20),
                                  margin: EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      boxShadow,
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          '$namaMakanan', // Menampilkan nama makanan dan jumlah dipilih
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          )),
                                      Text('${selectedFood['nama_kategori']}',
                                          style: TextStyle(
                                            fontSize: 12,
                                          )),
                                      // Menampilkan total energi
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Jumlah Energi : \n $totalEnergi',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  selectedFood[
                                                      'jumlahDipilih'] -= 1;
                                                  if (selectedFood[
                                                          'jumlahDipilih'] <
                                                      0) {
                                                    selectedFood[
                                                        'jumlahDipilih'] = 0;
                                                  }
                                                });
                                              },
                                              icon: Icon(Icons.remove)),
                                          Text('$jumlahDipilih',
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold)),
                                          IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  selectedFood[
                                                      'jumlahDipilih'] += 1;
                                                });
                                              },
                                              icon: Icon(Icons.add)),
                                        ],
                                      )
                                    ],
                                  ));
                            },
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

  Widget mCariMakan() {
    return Container(
      margin: EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      height: 400,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(left: 20, right: 20),
            margin: EdgeInsets.symmetric(vertical: 8),
            child: TextFormField(
              controller: searchController, // Menggunakan TextEditingController
              onChanged: (query) {
                filterFoodList(
                    query); // Panggil fungsi filterFoodList saat teks berubah
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: Icon(Icons.search),
                hintText: "Cari makanan",
              ),
            ),
          ),
          Expanded(
              child: Container(
            height: double.infinity,
            child: ListView.builder(
              itemCount: filteredFoodData.length,
              itemBuilder: (context, index) {
                final foodItem = filteredFoodData[index];
                return GestureDetector(
                  onTap: () {
                    TambahMakanan(foodItem['id_makanan'], index);
                    Navigator.pop(context);
                  },
                  child: Container(
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
                            foodItem['nama_makanan'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('Kategori: ${foodItem['nama_kategori']}'),
                          Text('Energi: ${foodItem['energi']}'),
                        ]),
                  ),
                );
              },
            ),
          ))
        ],
      ),
    );
  }
}
