/// Where the VitalCare API lives.
///
/// Set at build time with `--dart-define=API_URL=https://host/api`. The
/// default reaches a backend on the developer's machine from the Android
/// emulator, where `10.0.2.2` is the host's loopback.
const String apiBaseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://10.0.2.2:8085/api',
);

/// How long one request may take before it is reported as a network error.
const Duration apiTimeout = Duration(seconds: 20);
