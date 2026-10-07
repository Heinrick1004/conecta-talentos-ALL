class CandidatoAuth {
  const CandidatoAuth({
    required this.id,
    required this.nomeCompleto,
    required this.email,
  });

  final int id;
  final String nomeCompleto;
  final String email;

  factory CandidatoAuth.fromJson(Map<String, dynamic> json) {
    return CandidatoAuth(
      id: json['id'] as int,
      nomeCompleto: json['nomeCompleto'] as String,
      email: json['email'] as String,
    );
  }
}

class AuthResponse {
  const AuthResponse({required this.token, required this.candidato});

  final String token;
  final CandidatoAuth candidato;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      candidato: CandidatoAuth.fromJson(
        json['candidato'] as Map<String, dynamic>,
      ),
    );
  }
}
