import 'package:flutter/material.dart';
import 'package:isi_piringku/model/user.dart';

import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  UserData? _user;

  UserData? get user => _user;

  void updateUser(UserData newUser) {
    _user = newUser;
    notifyListeners();
  }
}
