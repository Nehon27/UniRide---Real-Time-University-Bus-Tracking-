// ============================================
// CONFIGURE THIS: point to your PHP backend
//
// - Android emulator talking to a server on the SAME PC: use 10.0.2.2
// - Real phone on the same Wi-Fi as your PC: use your PC's LAN IP,
//   e.g. http://192.168.0.105/uniride-backend
// - iOS simulator on the same PC: http://127.0.0.1/uniride-backend also works
// ============================================
class AppConfig {
  static const String apiBase = "http://10.0.2.2/uniride-backend";

  static const int locationIntervalSeconds = 5;
}
