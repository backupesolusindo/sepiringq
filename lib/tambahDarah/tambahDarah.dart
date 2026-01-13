import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import 'package:isi_piringku/bloc/nav/bottom_nav.dart';
import 'package:http/http.dart' as http;
import 'package:isi_piringku/util/colors.dart';
import 'package:isi_piringku/util/core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

import '../model/user.dart';

class InputDarah extends StatefulWidget {
  const InputDarah({Key? key}) : super(key: key);

  @override
  _InputDarahState createState() => _InputDarahState();
}

class _InputDarahState extends State<InputDarah> {
  String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String clientId = "PKL2023";
  String clientSecret = "PKLSERU";
  String txtNama = "";
  List<dynamic> arTambahDarah = [];

  String id = '';
  bool _isBelumMinum = true;
  bool _isLoading = false;

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');

    if (userDataString != null) {
      final userData = UserData.fromJson(json.decode(userDataString));

      setState(() {
        id = userData.idUser.toString();
        // Use simple date format to avoid locale issues
        txtNama = DateFormat('dd MMMM yyyy').format(DateTime.now());
        fetchDataDarah();
      });
    }
  }

  Future<void> _showConfirmationDialog(String status) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(
                status == 'sudah' ? Icons.check_circle : Icons.cancel,
                color: status == 'sudah' ? Colors.green : Colors.red,
                size: 28,
              ),
              const SizedBox(width: 10),
              const Text(
                'Konfirmasi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            status == 'sudah'
                ? 'Apakah Anda yakin sudah minum tablet tambah darah hari ini?'
                : 'Apakah Anda yakin belum minum tablet tambah darah hari ini?',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Batal',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: status == 'sudah' ? Colors.green : Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Ya, Yakin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _saveDataToDatabase(status);
    }
  }

  Future<void> _saveDataToDatabase(String status) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');

      if (userDataString != null) {
        final userData = UserData.fromJson(json.decode(userDataString));
        setState(() {
          id = userData.idUser.toString();
        });
      }

      final url = Uri.parse('${base_url}API/Darah/darah');

      final data = {
        "tanggal": currentDate,
        "id_user": id,
        "status": status,
      };

      final response = await http.post(
        url,
        body: data,
      );

      if (response.statusCode == 200) {
        await fetchDataDarah();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                status == 'sudah'
                    ? 'Berhasil mencatat sudah minum tablet tambah darah!'
                    : 'Berhasil mencatat belum minum tablet tambah darah!',
              ),
              backgroundColor: status == 'sudah' ? Colors.green : Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menyimpan data. Silakan coba lagi.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan. Periksa koneksi internet Anda.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> fetchDataDarah() async {
    final Uri uri =
        Uri.parse('${base_url}API/Darah/tambahdarahall?id_user=$id');

    try {
      final response = await http.get(uri);
      arTambahDarah.clear();

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final responseList = jsonData['response'] as List;

        setState(() {
          var datenow = DateTime.now();
          var angkatgl = datenow.day.toString();
          var angkabln = datenow.month.toString();
          if (datenow.day < 10) {
            angkatgl = "0$angkatgl";
          }
          if (datenow.month < 10) {
            angkabln = "0$angkabln";
          }
          var tanggalHariIni = "${datenow.year}-$angkabln-$angkatgl";

          for (var element in responseList) {
            arTambahDarah.add(element['tanggal']);
          }

          if (arTambahDarah.contains(tanggalHariIni)) {
            _isBelumMinum = false;
          }
        });
      }
    } catch (e) {
      // Handle error silently or show error message
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
      bottomNavigationBar: const BottomNavBar(selected: 4),
      appBar: AppBar(
        title: const Text('Tablet Tambah Darah'),
        backgroundColor: SecondaryColor,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          SecondaryColor.withValues(alpha: 0.1),
                          Colors.white
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15.0),
                      border: Border.all(
                          color: SecondaryColor.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: SecondaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Image.asset(
                            'assets/images/calendar.png',
                            width: 24.0,
                            height: 24.0,
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        const Expanded(
                          child: Text(
                            'Tablet Tambah Darah Hari Ini',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Main Content Card
                  if (_isBelumMinum)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.1),
                            spreadRadius: 0,
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: SecondaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Tanggal:',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            txtNama.isNotEmpty
                                ? txtNama
                                : DateFormat('dd MMMM yyyy')
                                    .format(DateTime.now()),
                            style: TextStyle(
                              fontSize: 16,
                              color: SecondaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Apakah Anda sudah minum tablet tambah darah hari ini?',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          _showConfirmationDialog('sudah');
                                        },
                                  icon: _isLoading
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : const Icon(Icons.check_circle,
                                          size: 20),
                                  label: Text(
                                    _isLoading ? 'Menyimpan...' : 'Sudah',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          _showConfirmationDialog('belum');
                                        },
                                  icon: _isLoading
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : const Icon(Icons.cancel, size: 20),
                                  label: Text(
                                    _isLoading ? 'Menyimpan...' : 'Belum',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(15.0),
                        border: Border.all(
                            color: Colors.green.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Sudah Tercatat',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.green,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                txtNama.isNotEmpty
                                    ? txtNama
                                    : DateFormat('dd MMMM yyyy')
                                        .format(DateTime.now()),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Anda sudah mencatat konsumsi tablet tambah darah untuk hari ini. Silakan cek riwayat di kalender di bawah.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Calendar Section
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          spreadRadius: 0,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border:
                          Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.event_note,
                              color: SecondaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Riwayat Konsumsi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TableCalendar(
                          locale: 'en_US',
                          firstDay: DateTime.utc(2010, 10, 16),
                          lastDay: DateTime.utc(2030, 3, 14),
                          focusedDay: DateTime.now(),
                          calendarFormat: CalendarFormat.month,
                          headerStyle: const HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            titleTextStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          calendarStyle: CalendarStyle(
                            todayDecoration: BoxDecoration(
                              color: SecondaryColor,
                              shape: BoxShape.circle,
                            ),
                            selectedDecoration: BoxDecoration(
                              color: SecondaryColor.withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                            ),
                            markerDecoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            markersMaxCount: 1,
                            canMarkersOverflow: false,
                          ),
                          eventLoader: (day) {
                            var angkatgl = day.day.toString();
                            var angkabln = day.month.toString();
                            if (day.day < 10) {
                              angkatgl = "0$angkatgl";
                            }
                            if (day.month < 10) {
                              angkabln = "0$angkabln";
                            }
                            var tanggal = "${day.year}-$angkabln-$angkatgl";
                            if (arTambahDarah.contains(tanggal)) {
                              return [const Event('Sudah Minum')];
                            }
                            return [];
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
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
                          'Menyimpan data...',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class Event {
  final String title;

  const Event(this.title);

  @override
  String toString() => title;
}
