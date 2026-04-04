/// Base URL of the PHP API folder (where `index.php` is served). No trailing slash.
///
/// **Built-in PHP server** (from the project root):
///   `php -S 127.0.0.1:8080 -t backend/public`
///   → use default `http://127.0.0.1:8080`
///
/// **XAMPP/WAMP** (example): `http://localhost/discoverjakarta/backend/public`
///
/// **Android emulator** cannot use `127.0.0.1` for your PC; use:
///   `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080`
///
/// **Real phone** on same Wi‑Fi: use your PC’s LAN IP, e.g. `http://192.168.1.10:8080`
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8080',
);
