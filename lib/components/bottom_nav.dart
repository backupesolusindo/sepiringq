// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key, required this.selected});

  final int selected;

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        // padding: EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            const Spacer(),
            IconBottomBar(
                index: 0,
                label: 'Home',
                selected: widget.selected,
                icon: 'home.png',
                navigateTo: "/dashboard"),
            const Spacer(),
            IconBottomBar(
                index: 1,
                label: 'kalori',
                selected: widget.selected,
                icon: 'user.png',
                navigateTo: "/kalori"),
            const Spacer(),
            IconBottomBar(
                index: 2,
                label: 'riwayat',
                selected: widget.selected,
                icon: 'history.png',
                navigateTo: "/riwayat"),
            const Spacer(),
            IconBottomBar(
                index: 3,
                label: 'Profile',
                selected: widget.selected,
                icon: 'user.png',
                navigateTo: "/profile"),
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
  final String icon;
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
        // if (isUserLoggedIn || index == 0 || index == 1) {
        // BlocProvider.of<NavBloc>(context).add(navigateTo);
        // } else {
        //   showNotLoggedInDialog(context);
        // }
      },
      child: Container(
        // width: MediaQuery.of(context).size.width * 0.2,
        // height: MediaQuery.of(context).size.height * 0.09,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          // mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.0325,
              child: Image.asset(
                'assets/images/$icon',
                fit: BoxFit.cover,
                color: (selected == index)
                    ? Colors.orange
                    : Colors.grey.withOpacity(0.5),
              ),
            ),
            SizedBox(height: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    fontSize: 12,
                    color: (selected == index)
                        ? Colors.orange
                        : Colors.grey.withOpacity(0.5),
                  ),
            )
          ],
        ),
      ),
    );
  }
}
