import 'config/flavor_config.dart';
import 'main.dart' as app;

void main() {
  FlavorConfig.initialize(
    flavor: Flavor.prod,
    apiBaseUrl: 'https://api.apobasi.com',
  );
  app.main();
}
