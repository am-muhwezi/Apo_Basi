import 'config/flavor_config.dart';
import 'main.dart' as app;

void main() {
  FlavorConfig.initialize(
    flavor: Flavor.staging,
    apiBaseUrl: 'https://staging.api.apobasi.com',
  );
  app.main();
}
