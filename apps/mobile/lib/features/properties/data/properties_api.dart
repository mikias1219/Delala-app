import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/property_model.dart';
import '../../../core/network/http_client.dart';

final propertiesApiProvider = Provider<PropertiesApi>(
  (ref) => PropertiesApi(ref.watch(httpClientProvider)),
);

class PropertiesApi {
  PropertiesApi(this._http);

  final HttpClient _http;

  Future<List<PropertyModel>> search({
    int? bedrooms,
    double? minPrice,
    double? maxPrice,
  }) async {
    final data = await _http.getJson(
      '/properties',
      query: {
        if (bedrooms != null) 'bedrooms': bedrooms,
        if (minPrice != null) 'minPrice': minPrice,
        if (maxPrice != null) 'maxPrice': maxPrice,
      },
      parse: (json) => json,
    );
    final items = data['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => PropertyModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PropertyModel> getById(String id) => _http.getJson(
        '/properties/$id',
        parse: PropertyModel.fromJson,
      );

  Future<Map<String, dynamic>> requestViewing({
    required String propertyId,
    String? notes,
  }) =>
      _http.postJson(
        '/viewings',
        data: {'propertyId': propertyId, if (notes != null) 'notes': notes},
        parse: (json) => json,
      );
}
