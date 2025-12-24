part of 'nav_bloc.dart';

@immutable
abstract class NavState {}

class NavInitial extends NavState {}

class NavSplash extends NavState {}

class NavLogin extends NavState {}

class NavVerifikasiEmail extends NavState {}

class NavConfirmPassword extends NavState {}

class NavResetPassSuccess extends NavState{}

class NavForgetPassword extends NavState{}

class NavHello extends NavState {}

class NavDashboard extends NavState {}

class NavChat extends NavState {}

class NavProfile extends NavState {}

class NavEditProfile extends NavState {}

class NavEditProfileSuccess extends NavState {}