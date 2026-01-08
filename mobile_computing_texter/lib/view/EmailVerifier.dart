import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailVerifier {
  Future<bool> isEmailDomainValid(String email) async {
    final String domain = email.split('@').last;
    final String url = 'https://dns.google/resolve?name=$domain&type=MX';

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(Duration(seconds: 5)); 
      final data = jsonDecode(response.body);

      return data.containsKey("Answer");
    } catch (e) {
      print("Errore durante la verifica del dominio: $e");
      return false;
    }
  }
}
