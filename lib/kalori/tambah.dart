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
  String apiUrl = base_url + "API/Konsumsi/Konsumsi";
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

  Future<List<Map<String, dynamic>>> fetchData() async {
    try {
      final response = await http.get(
        Uri.parse(base_url + 'API/Makanan/makanan'),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['response'];
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        } else {
          throw Exception('Response "response" bukan array. Body: $body');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Gagal muat data makanan: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    loadUserData();

    fetchData().then((data) {
      setState(() {
        foodData = data;
        filteredFoodData = data;
        cardValues = List.filled(foodData.length, 0);
      });
    }).catchError((error) {
      Fluttertoast.showToast(
        msg: 'Gagal muat data makanan: $error',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      print('Error fetching food data: $error');
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
    var indexInFoodData = foodData.indexWhere((food) => food['id_makanan'] == idMakanan);
    if (indexInFoodData == -1) {
      Fluttertoast.showToast(
        msg: 'Makanan tidak ditemukan',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return;
    }

    var energi = foodData[indexInFoodData]['energi'].toString();

    setState(() {
      if (indexInFoodData < cardValues.length) {
        cardValues[indexInFoodData] += 1;
      }
    });

    var selectedFood = selectedFoods.firstWhereOrNull(
      (food) => food['id_makanan'] == idMakanan,
    );

    if (selectedFood == null) {
      selectedFoods.add({
        ...foodData[indexInFoodData],
        'jumlahDipilih': 1,
      });
    } else {
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
                              final energi = double.tryParse(energiString) ?? 0.0;
                              final jumlahDipilih = selectedFood['jumlahDipilih'] as int;
                              final totalEnergi = energi * jumlahDipilih;

                              return Container(
                                margin: EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [boxShadow],
                                ),
                                child: ExpansionTile(
                                  title: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$namaMakanan',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${selectedFood['nama_kategori']}',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Jumlah Energi: $totalEnergi',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  selectedFood['jumlahDipilih'] -= 1;
                                                  if (selectedFood['jumlahDipilih'] < 0) {
                                                    selectedFood['jumlahDipilih'] = 0;
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
                                                  selectedFood['jumlahDipilih'] += 1;
                                                });
                                              },
                                              icon: Icon(Icons.add)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Nutrisi:',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          _buildNutritionRow('Karbohidrat', selectedFood['karbohidrat']),
                                          _buildNutritionRow('Protein', selectedFood['protein']),
                                          _buildNutritionRow('Lemak', selectedFood['lemak']),
                                          _buildNutritionRow('Vitamin A', selectedFood['vitamina']),
                                          _buildNutritionRow('Vitamin C', selectedFood['vitaminc']),
                                          _buildNutritionRow('Besi', selectedFood['besi']),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
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

  Widget _buildNutritionRow(String label, dynamic value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        Text(
          value?.toString() ?? '-',
          style: TextStyle(fontSize: 12),
        ),
      ],
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
              controller: searchController,
              onChanged: (query) {
                filterFoodList(query);
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
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Padding(
                      padding: EdgeInsets.all(12),
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
                          SizedBox(height: 4),
                          Text(
                            'Kategori: ${foodItem['nama_kategori']}',
                            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                          ),
                          Divider(color: Colors.grey[300], height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Energi: ${foodItem['energi']}',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'Karbo: ${foodItem['karbohidrat'] ?? '-'}',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Protein: ${foodItem['protein'] ?? '-'}',
                                style: TextStyle(fontSize: 12),
                              ),
                              Text(
                                'Lemak: ${foodItem['lemak'] ?? '-'}',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Vit A: ${foodItem['vitamina'] ?? '-'}',
                                style: TextStyle(fontSize: 12),
                              ),
                              Text(
                                'Vit C: ${foodItem['vitaminc'] ?? '-'}',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Besi: ${foodItem['besi'] ?? '-'}',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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