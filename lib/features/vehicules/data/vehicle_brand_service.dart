// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
//
// class VehicleBrandService {
//   static const _cacheKey = 'vehicle_brands_cache';
//   static const _url =
//       'https://www.carqueryapi.com/api/0.3/?cmd=getMakes';
//
//   Future<List<String>> fetchBrands() async {
//     final prefs = await SharedPreferences.getInstance();
//
//     // 🔹 Cache
//     final cached = prefs.getStringList(_cacheKey);
//     if (cached != null && cached.isNotEmpty) {
//       return cached;
//     }
//
//     // 🔹 API
//     final res = await http.get(Uri.parse(_url));
//     if (res.statusCode != 200) {
//       throw Exception('Erreur chargement marques');
//     }
//
//     final data = jsonDecode(res.body);
//     final List<String> brands = (data['Makes'] as List)
//         .map((e) => e['make_display'] as String)
//         .toSet() // éviter doublons
//         .toList()
//       ..sort();
//
//     // 🔹 Sauvegarde cache
//     await prefs.setStringList(_cacheKey, brands);
//     return brands;
//   }
// }
import 'dart:convert';
import 'package:http/http.dart' as http;

class VehicleBrandService {
  Future<List<String>> fetchBrands() async {
    final url = Uri.parse(
      'https://vpic.nhtsa.dot.gov/api/vehicles/getallmakes?format=json',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Erreur API marques');
    }

    final data = jsonDecode(response.body);

    return (data['Results'] as List)
        .map((e) => e['Make_Name'] as String)
        .toSet()        // évite doublons
        .toList()
      ..sort();
  }
}
