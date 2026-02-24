// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_piringku/util/colors.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key, required this.selected});

  final int selected;

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: EdgeInsets.only(top: 8, bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [boxShadow],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4),
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
                child: IconBottomBar(
                    index: 1,
                    label: 'Kalori',
                    selected: widget.selected,
                    icon: Icons.food_bank_rounded,
                    navigateTo: "/kalori")),
            Expanded(
              child: IconBottomBar(
                  index: 4,
                  label: 'TTD',
                  selected: widget.selected,
                  icon: Icons.bloodtype,
                  navigateTo: "/ttd"),
            ),
            Expanded(
              child: IconBottomBar(
                  index: 5,
                  label: 'BB',
                  selected: widget.selected,
                  icon: Icons.monitor_weight_rounded,
                  navigateTo: "/beratbadan"),
            ),
            Expanded(
                child: IconBottomBar(
                    index: 0,
                    label: 'Home',
                    selected: widget.selected,
                    icon: Icons.home_rounded,
                    navigateTo: "/dashboard")),
            Expanded(
                child: IconBottomBar(
                    index: 2,
                    label: 'Riwayat',
                    selected: widget.selected,
                    icon: Icons.history,
                    navigateTo: "/riwayat")),
            Expanded(
                child: IconBottomBar(
                    index: 3,
                    label: 'Profile',
                    selected: widget.selected,
                    icon: Icons.account_box,
                    navigateTo: "/profile")),
          ],
        ),
      ),
    );
  }
}

class IconBottomBar extends StatelessWidget {
  // final String label;
  final int index;
  final int selected;
  final IconData icon;
  final String label;
  final String navigateTo;
  // final NavEvent navigateTo;
  const IconBottomBar(
      {super.key,
      // required this.label,
      required this.index,
      required this.selected,
      required this.icon,
      required this.navigateTo,
      required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacementNamed(context, navigateTo.toString());
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                height: (selected == index) ? 26 : 24,
                child: Icon(
                  icon,
                  size: (selected == index) ? 26 : 24,
                  color: (selected == index) ? PrimaryColor : Colors.grey,
                )),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: (selected == index) ? 11 : 10,
                fontWeight:
                    (selected == index) ? FontWeight.w700 : FontWeight.w400,
                color: (selected == index)
                    ? PrimaryColor
                    : Colors.grey.withOpacity(0.5),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
    );
  }
}
