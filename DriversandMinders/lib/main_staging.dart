import 'config/flavor_config.dart';
import 'main.dart' as app;

void main() {
  FlavorConfig.initialize(
    flavor: Flavor.staging,
    apiBaseUrl: 'https://staging.apobasi.com',
  );
  app.main();
}
