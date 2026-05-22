import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/http_client.dart';

final workersApiProvider = Provider<WorkersApi>(
  (ref) => WorkersApi(ref.watch(httpClientProvider)),
);

class WorkersApi {
  WorkersApi(this._http);

  final HttpClient _http;

  Future<List<dynamic>> list({List<String>? skills}) => _http.getList(
        '/workers',
        query: {
          if (skills != null && skills.isNotEmpty) 'skills': skills.join(','),
        },
      );

  Future<Map<String, dynamic>> upsertProfile({
    required List<String> skills,
    String? availability,
    double? salaryExpectation,
    String? bio,
  }) =>
      _http.putJson(
        '/workers/me',
        data: {
          'skills': skills,
          if (availability != null) 'availability': availability,
          if (salaryExpectation != null) 'salaryExpectation': salaryExpectation,
          if (bio != null) 'bio': bio,
        },
        parse: (json) => json,
      );

  Future<Map<String, dynamic>> createJob({
    required String jobType,
    required String location,
    double? salaryOffer,
    String? requirements,
  }) =>
      _http.postJson(
        '/jobs',
        data: {
          'jobType': jobType,
          'location': location,
          if (salaryOffer != null) 'salaryOffer': salaryOffer,
          if (requirements != null) 'requirements': requirements,
        },
        parse: (json) => json,
      );
}
