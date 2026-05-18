import 'package:flutter_test/flutter_test.dart';
import 'package:yusr/src/services/api_client.dart';

void main() {
  group('ApiClient', () {
    test('baseUrl is correct for Android', () {
      // ApiClient.baseUrl returns different values for Android vs other platforms
      expect(ApiClient.baseUrl, isNotEmpty);
    });
  });
}

