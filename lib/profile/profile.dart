import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:isi_piringku/util/colors.dart';
import 'package:page_transition/page_transition.dart';
import 'package:isi_piringku/Login/login_screen.dart';
import 'package:isi_piringku/bloc/nav/bottom_nav.dart';
import 'package:isi_piringku/model/provider.dart';
import 'package:provider/provider.dart';
import 'package:isi_piringku/model/user.dart';
import 'package:isi_piringku/profile/editprofile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String nama = '';
  String email = '';
  String tglLahir = '';
  String beratBadan = '';
  String tinggiBadan = '';
  String noTelp = '';
  String username = '';
  String alamat = '';
  String kecamatan = '';
  String kabupaten = '';
  String provinsi = '';
  String jenisKelamin = '';
  String umur = '';

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');

    if (userDataString != null) {
      final userData = UserData.fromJson(json.decode(userDataString));

      setState(() {
        nama = userData.nama.isNotEmpty ? userData.nama : userData.username;
        email = userData.email;
        tglLahir = userData.tglLahir;
        beratBadan = userData.beratBadan;
        tinggiBadan = userData.tinggiBadan;
        noTelp = userData.noTelp;
        username = userData.username;
        alamat = userData.alamat;
        kecamatan = userData.kecamatan;
        kabupaten = userData.kabupaten;
        provinsi = userData.provinsi;
        jenisKelamin = userData.jekel;
        umur = userData.umur;
      });
    }
  }

  Future<void> logoutUser() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('access_token');
    prefs.remove('user_data');

    if (mounted) {
      Provider.of<UserProvider>(context, listen: false).clearUser();

      Navigator.of(context).pushAndRemoveUntil(
        PageTransition(
          child: const LoginScreen(),
          type: PageTransitionType.fade,
          duration: const Duration(milliseconds: 500),
        ),
        (route) => false,
      );
    }
  }

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    bottomNavigationBar: const BottomNavBar(selected: 3),
    key: scaffoldKey,
    backgroundColor: const Color.fromARGB(255, 255, 172, 63),
    body: ListView( // ⬅️ GANTI DARI SingleChildScrollView + Column
      children: [
        // Header Section - Tanpa height fix
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromARGB(255, 255, 172, 63),
                Color.fromARGB(255, 255, 193, 102),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: Color.fromARGB(255, 255, 172, 63),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        username.isNotEmpty ? username : 'User',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Readex Pro',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      nama.isNotEmpty ? nama : 'Nama Lengkap',
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontFamily: 'Readex Pro',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Profile Content
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                _buildSectionTitle('Informasi Personal'),
                const SizedBox(height: 15),
                _buildInfoCard([
                  _buildInfoRow(Icons.email, 'Email', email),
                  _buildInfoRow(Icons.phone, 'No. Telepon', noTelp),
                  _buildInfoRow(Icons.cake, 'Tanggal Lahir', tglLahir),
                  _buildInfoRow(Icons.wc, 'Jenis Kelamin', jenisKelamin),
                  _buildInfoRow(Icons.calendar_today, 'Umur', '$umur tahun'),
                ]),
                const SizedBox(height: 25),
                _buildSectionTitle('Informasi Fisik'),
                const SizedBox(height: 15),
                _buildInfoCard([
                  _buildInfoRow(Icons.height, 'Tinggi Badan', '$tinggiBadan cm'),
                  _buildInfoRow(Icons.monitor_weight, 'Berat Badan', '$beratBadan kg'),
                ]),
                const SizedBox(height: 25),
                _buildSectionTitle('Informasi Alamat'),
                const SizedBox(height: 15),
                _buildInfoCard([
                  _buildInfoRow(Icons.home, 'Alamat', alamat),
                  _buildInfoRow(Icons.location_city, 'Kecamatan', kecamatan),
                  _buildInfoRow(Icons.location_on, 'Kabupaten', kabupaten),
                  _buildInfoRow(Icons.map, 'Provinsi', provinsi),
                ]),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditProfile(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit, color: Colors.white),
                        label: const Text(
                          'Edit Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SecondaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showLogoutDialog();
                        },
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: const Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AccentColor,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
        fontFamily: 'Readex Pro',
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color.fromARGB(255, 255, 172, 63),
          ),
          const SizedBox(width: 15),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                fontFamily: 'Readex Pro',
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(
              value.isNotEmpty ? value : '-',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                fontFamily: 'Readex Pro',
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Konfirmasi Logout',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Readex Pro',
            ),
          ),
          content: const Text(
            'Apakah Anda yakin ingin keluar dari aplikasi?',
            style: TextStyle(fontFamily: 'Readex Pro'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Batal',
                style: TextStyle(
                  color: Colors.grey,
                  fontFamily: 'Readex Pro',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                logoutUser();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AccentColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Readex Pro',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
