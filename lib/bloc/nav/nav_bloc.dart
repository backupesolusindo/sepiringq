import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'nav_event.dart';
part 'nav_state.dart';

class NavBloc extends Bloc<NavEvent, NavState> {
  NavBloc() : super(NavSplash()) {
    on<ToSplashEvent>((event, emit) {
      emit(NavSplash());
    });
    on<ToHelloEvent>((event, emit) {
      emit(NavHello());
    });
    on<ToLoginEvent>((event, emit) {
      emit(NavLogin());
    });
    on<ToDashboardEvent>((event, emit) {
      emit(NavDashboard());
    });
    on<ToChatEvent>((event, emit) {
      emit(NavChat());
    });
    on<ToVerifikasiEmailEvent>((event, emit) {
      emit(NavVerifikasiEmail());
    });
    on<ToConfirmPasswordEvent>((event, emit) {
      emit(NavConfirmPassword());
    });
    on<ToForgetPasswordEvent>((event, emit) {
      emit(NavForgetPassword());
    });
    on<ToResetPassSuccessEvent>((event, emit) {
      emit(NavResetPassSuccess());
    });
    on<ToProfileEvent>((event, emit) {
      emit(NavProfile());
    });
    on<ToEditProfileEvent>((event, emit) {
      emit(NavEditProfile());
    });
    on<ToEditProfileSuccessEvent>((event, emit) {
      emit(NavEditProfileSuccess());
    });
  }
}
