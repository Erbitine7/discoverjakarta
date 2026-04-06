/// Default API port — keep in sync with `server/.env.example` (`PORT=`) and `server/index.js` fallback.
const int kApiDefaultPort = 3001;

/// Resolved at compile time. Must match a running `server` process (see `server/` folder).
///
/// **Do not** use the old `backend/` folder; run **`cd server && npm start`** only.
///
/// Override when needed:
/// - Android emulator: `--dart-define=API_BASE_URL=http://10.0.2.2:3001`
/// - Web: `--dart-define=API_BASE_URL=http://localhost:3001`
/// - Physical device: `--dart-define=API_BASE_URL=http://YOUR_PC_LAN_IP:3001`
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:$kApiDefaultPort',
);
