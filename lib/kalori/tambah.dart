// lib/kalori/tambah.dart

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
  bool isLoading = false;
  bool isLoadingData = true;

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');

    if (userDataString != null) {
      final userData = UserData.fromJson(json.decode(userDataString));
      setState(() {
        Id = userData.idUser.toString();
      });
      print('✅ User ID loaded: $Id');
    } else {
      print('⚠️ User data not found in SharedPreferences');
      Fluttertoast.showToast(
        msg: 'Data user tidak ditemukan. Silakan login kembali.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
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
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() {
      isLoadingData = true;
    });

    await loadUserData();

    try {
      final data = await fetchData();
      setState(() {
        foodData = data;
        filteredFoodData = data;
        cardValues = List.filled(foodData.length, 0);
        isLoadingData = false;
      });
    } catch (error) {
      Fluttertoast.showToast(
        msg: 'Gagal muat data makanan: $error',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      print('Error fetching food data: $error');
      setState(() {
        isLoadingData = false;
      });
    }
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
    if (Id.isEmpty) {
      Fluttertoast.showToast(
        msg: 'User ID tidak ditemukan. Silakan login kembali.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    if (selectedFoods.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Pilih makanan terlebih dahulu',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      var jumlahDipilih = [];
      double energi = 0;
      var idMakanan = [];
      selectedFoods.forEach((selectedFood) async {
        jumlahDipilih.add(selectedFood['jumlahDipilih']);
        idMakanan.add(selectedFood['id_makanan']);
        energi += selectedFood['jumlahDipilih'] *
            double.tryParse(selectedFood['energi'].toString())!;
      });

      print('🔵 Sending data:');
      print('   id_user: $Id');
      print('   total_kalori: $energi');
      print('   keterangan: ${widget.keterangan}');
      print('   bahan_makanan_nama_makanan: $idMakanan');
      print('   kuantitas: $jumlahDipilih');

      var response = await http.post(
        Uri.parse(apiUrl),
        headers: {
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
        Navigator.pop(context, true);
      } else {
        print('❌ Gagal mengirim data: ${response.statusCode}');
        print('Response body: ${response.body}');
        Fluttertoast.showToast(
          msg: 'Gagal Kirim Data: ${response.statusCode}',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Exception mengirim data: $e');
      Fluttertoast.showToast(
        msg: 'Gagal Kirim Data: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      setState(() {
        isLoading = false;
      });
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
    if (isLoadingData) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Tambah Makanan'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Memuat data makanan...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      bottomNavigationBar: BottomNavBar(selected: 1),
      appBar: AppBar(
        title: Text('Tambah Makanan'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: isLoading
          ? FloatingActionButton(
              onPressed: null,
              backgroundColor: Colors.grey,
              child: CircularProgressIndicator(color: Colors.white),
            )
          : FloatingActionButton.extended(
              onPressed: () {
                kirimData();
              },
              icon: Icon(Icons.save),
              label: Text('Simpan'),
              backgroundColor: SecondaryColor,
            ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16),
              Text(
                'Makan Apa Hari Ini?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                onTap: () {
                  FocusScope.of(context).requestFocus(FocusNode());
                  showMaterialModalBottomSheet(
                    context: context,
                    builder: (context) => mCariMakan(),
                  );
                },
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'Cari makanan...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: SecondaryColor),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Makanan Terpilih',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '${selectedFoods.length} item',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              if (selectedFoods.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Belum ada makanan yang dipilih',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tambahkan makanan dari pencarian',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: selectedFoods.length,
                    itemBuilder: (context, index) {
                      final selectedFood = selectedFoods[index];
                      final namaMakanan = selectedFood['nama_makanan'];
                      final energiString = selectedFood['energi'];
                      final energi = double.tryParse(energiString) ?? 0.0;
                      final jumlahDipilih = selectedFood['jumlahDipilih'] as int;
                      final totalEnergi = energi * jumlahDipilih;
                      
                      // ✅ GET URT
                      final urt = selectedFood['urt'] ?? selectedFood['URT'] ?? '-';

                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 1,
                        child: ExpansionTile(
                          title: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      namaMakanan,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          selectedFood['nama_kategori'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        // ✅ DISPLAY URT
                                        Text(
                                          ' • URT: $urt',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Chip(
                                label: Text(
                                  '$jumlahDipilih',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                backgroundColor: Colors.blue[50],
                                labelStyle: TextStyle(color: Colors.blue[700]),
                              ),
                              SizedBox(width: 8),
                              Chip(
                                label: Text(
                                  '${totalEnergi.toStringAsFixed(0)} kcal',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                backgroundColor: Colors.green[50],
                                labelStyle: TextStyle(color: Colors.green[700]),
                              ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Nutrisi',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      _buildNutritionChip('Karbo', selectedFood['karbohidrat']),
                                      _buildNutritionChip('Protein', selectedFood['protein']),
                                      _buildNutritionChip('Lemak', selectedFood['lemak']),
                                      _buildNutritionChip('Vit A', selectedFood['vitamina'], isVitamin: true, color: Colors.blue[100]),
                                      _buildNutritionChip('Vit C', selectedFood['vitaminc'], isVitamin: true, color: Colors.green[100]),
                                      _buildNutritionChip('Besi', selectedFood['besi']),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            selectedFood['jumlahDipilih'] -= 1;
                                            if (selectedFood['jumlahDipilih'] < 1) {
                                              selectedFoods.removeAt(index);
                                            }
                                          });
                                        },
                                        icon: Icon(Icons.remove_circle_outline, color: Colors.red),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            selectedFood['jumlahDipilih'] += 1;
                                          });
                                        },
                                        icon: Icon(Icons.add_circle_outline, color: Colors.green),
                                      ),
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
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionChip(String label, dynamic value, {bool isVitamin = false, Color? color}) {
    return Chip(
      label: Text(
        '$label: ${value?.toString() ?? '-'}',
        style: TextStyle(fontSize: 11),
      ),
      backgroundColor: isVitamin ? color : Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[300]!),
      ),
    );
  }

  Widget mCariMakan() {
    return Container(
      padding: EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: TextFormField(
              controller: searchController,
              onChanged: (query) {
                filterFoodList(query);
              },
              decoration: InputDecoration(
                hintText: 'Cari makanan...',
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: SecondaryColor),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: filteredFoodData.length,
              itemBuilder: (context, index) {
                final foodItem = filteredFoodData[index];
                
                // ✅ GET URT
                final urt = foodItem['urt'] ?? foodItem['URT'] ?? '-';
                
                return InkWell(
                  onTap: () {
                    TambahMakanan(foodItem['id_makanan'], index);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
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
                                    foodItem['nama_makanan'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        foodItem['nama_kategori'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      // ✅ DISPLAY URT IN SEARCH
                                      Text(
                                        ' • URT: $urt',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Chip(
                              label: Text(
                                '${foodItem['energi']} kcal',
                                style: TextStyle(fontSize: 12),
                              ),
                              backgroundColor: Colors.green[50],
                              labelStyle: TextStyle(color: Colors.green[700]),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            _buildNutritionChip('Karbo', foodItem['karbohidrat']),
                            _buildNutritionChip('Protein', foodItem['protein']),
                            _buildNutritionChip('Lemak', foodItem['lemak']),
                            _buildNutritionChip('Vit A', foodItem['vitamina'], isVitamin: true, color: Colors.blue[100]),
                            _buildNutritionChip('Vit C', foodItem['vitaminc'], isVitamin: true, color: Colors.green[100]),
                            _buildNutritionChip('Besi', foodItem['besi']),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}