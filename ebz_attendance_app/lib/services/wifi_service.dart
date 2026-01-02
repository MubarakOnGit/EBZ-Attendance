import 'package:network_info_plus/network_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class WifiService {
  final NetworkInfo _networkInfo = NetworkInfo();

  Future<String?> getWifiSsid() async {
    if (kIsWeb) return null;
    try {
      return await _networkInfo.getWifiName();
    } catch (e) {
      print('Error getting SSID: $e');
      return null;
    }
  }

  Future<String?> getWifiBssid() async {
    if (kIsWeb) return null;
    try {
      return await _networkInfo.getWifiBSSID();
    } catch (e) {
      print('Error getting BSSID: $e');
      return null;
    }
  }

  Future<bool> isConnectedToWifi() async {
    if (kIsWeb) return false;
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult.contains(ConnectivityResult.wifi);
  }

  Future<bool> validateWifi(List<String> allowedSsids) async {
    if (allowedSsids.isEmpty) return true; // No restriction
    if (kIsWeb) return true; // Web (Admin) doesn't use WiFi restriction for check-in
    
    if (!await isConnectedToWifi()) return false;
    
    String? currentSsid = await getWifiSsid();
    // Remove quotes if present (iOS/Android sometimes returns SSID with quotes)
    if (currentSsid != null) {
      currentSsid = currentSsid.replaceAll('"', '');
    }
    
    return allowedSsids.contains(currentSsid);
  }
}
