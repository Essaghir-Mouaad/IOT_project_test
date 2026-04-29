import 'dart:convert';
import 'package:http/http.dart' as http;

class MlServices {
  static const String _endpoint =
      'https://fastapp-9d9438f8dae7.herokuapp.com/predict/';

  Future<int> predict({
    required int age,
    required double hr,
    required double spo2,
    required double temp,
    required String activity,
  }) async {
    final body = jsonEncode({
      'age': age,
      'hr': hr,
      'spo2': spo2,
      'temp': temp,
      'activity': activity,
    });
    const headers = {'Content-Type': 'application/json'};

    var response = await http
        .post(Uri.parse(_endpoint), headers: headers, body: body)
        .timeout(const Duration(seconds: 15));

    // Follow 307/308 redirects manually — http package drops the body on redirect
    if (response.statusCode == 307 || response.statusCode == 308) {
      final redirectUrl = response.headers['location'];
      if (redirectUrl == null) {
        throw Exception('Redirect with no Location header');
      }
      response = await http
          .post(Uri.parse(redirectUrl), headers: headers, body: body)
          .timeout(const Duration(seconds: 15));
    }

    if (response.statusCode != 200) {
      throw Exception('ML API error ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final raw = decoded['prediction'] ?? decoded['state'];
    final code = raw is int ? raw : int.tryParse(raw.toString());

    if (code == null) {
      throw Exception('Unexpected prediction response: ${response.body}');
    }

    return code;
  }
}
