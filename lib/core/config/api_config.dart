enum APIEnvironment {
  development,
  localNetwork,
  production;

  String get baseURL {
    switch (this) {
      case APIEnvironment.development:
        // Change this to true to test Azure backend in development
        const useAzure = false;
        return useAzure
            ? 'https://duoz-api-ardva4h9f6g4h5an.japanwest-01.azurewebsites.net'
            : 'http://localhost:8000';
      case APIEnvironment.localNetwork:
        return 'http://192.168.2.12:8000'; // Your local network IP
      case APIEnvironment.production:
        return 'duoz-api-ardva4h9f6g4h5an.japanwest-01.azurewebsites.net'; // Azure URL
    }
  }
}

class APIConfig {
  static final APIConfig current = APIConfig._();
  APIConfig._();

  // Debug mode uses development environment, otherwise production
  final environment = const bool.fromEnvironment('dart.vm.product')
      ? APIEnvironment.production
      : APIEnvironment.development;

  String get translateAudioURL => '${environment.baseURL}/api/v1/translate-audio/';
}
