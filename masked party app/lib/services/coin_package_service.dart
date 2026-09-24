// FILE LOCATION: lib/services/coin_package_service.dart
import 'package:http/http.dart' as http;

import 'api.dart';
import 'api_endpoints.dart';

class CoinPackageService {
  /// Backend: api/wallet/packages.php — GET — auth required.
  Future<dynamic> getPackages(String token) async {
    try {
      final response = await http
          .get(
            ApiConfig.uri(ApiEndpoints.walletPackages),
            headers: ApiConfig.authHeaders(token),
          )
          .timeout(ApiConfig.timeoutDuration);

      return ApiConfig.handleResponse(response, isAuthenticatedRequest: true);
    } catch (e) {
      return ApiConfig.handleError(e);
    }
  }
}
