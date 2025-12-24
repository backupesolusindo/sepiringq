part of 'nav_bloc.dart';

@immutable
abstract class NavEvent {}

class ToLoginEvent extends NavEvent {}

class ToHelloEvent extends NavEvent {}

class ToResetPassEvent extends NavEvent {}

class ToSplashEvent extends NavEvent {}

class ToDashboardEvent extends NavEvent {}

class ToVerifikasiEmailEvent extends NavEvent{}

class ToConfirmPasswordEvent extends NavEvent{}

class ToResetPassSuccessEvent extends NavEvent{}

class ToForgetPasswordEvent extends NavEvent{}

class ToChatEvent extends NavEvent{}

class ToProfileEvent extends NavEvent{}

class ToEditProfileEvent extends NavEvent {}

class ToEditProfileSuccessEvent extends NavEvent {}
