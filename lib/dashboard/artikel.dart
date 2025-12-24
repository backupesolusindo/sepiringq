import 'package:flutter/material.dart';

class ArtikelBawah extends StatefulWidget {
  const ArtikelBawah({super.key});

  @override
  State<ArtikelBawah> createState() => _ArtikelBawahState();
}

class _ArtikelBawahState extends State<ArtikelBawah> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SingleChildScrollView(),
    );
  }

  Widget buildCard(String description, int calories) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      margin: EdgeInsets.only(left: 20, right: 20),
      child: Padding(
        padding: EdgeInsets.all(15.0),
        child: Row(
          children: [
            Container(
              width: 50.0,
              height: 50.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                image: DecorationImage(
                  image: AssetImage('assets/images/shusi.webp'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: 15.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10.0),
                  Text('irisan susi mantap')
                ],
              ),
            ),
            SizedBox(width: 30),
            Column(
              children: [
                Center(child: Text(' 130 \nkalori')),
              ],
            )
          ],
        ),
      ),
    );
  }
}
