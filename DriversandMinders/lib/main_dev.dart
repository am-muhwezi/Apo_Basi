import 'config/flavor_config.dart';
import 'main.dart' as app;

void main() {
  FlavorConfig.initialize(
    flavor: Flavor.dev,
    apiBaseUrl: '', // empty → falls back to .env (API_BASE_URL)
  );
  app.main();
}
