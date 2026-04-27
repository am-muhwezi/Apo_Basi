import 'config/flavor_config.dart';
import 'main.dart' as app;

void main() {
  FlavorConfig.initialize(
    flavor: Flavor.dev,
    apiBaseUrl: 'http://192.168.100.65:8000',
  );
  app.main();
}
