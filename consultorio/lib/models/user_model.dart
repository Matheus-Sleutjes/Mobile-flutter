import '../services/auth_service.dart';

class UserModel {
  final String username;
  final String password;
  final UserRole role;
  final String nomeCompleto;
  final String? especialidade;

  UserModel({
    required this.username,
    required this.password,
    required this.role,
    required this.nomeCompleto,
    this.especialidade,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      username: json['username'],
      password: json['password'],
      role: UserRole.values.firstWhere((e) => e.toString() == json['role']),
      nomeCompleto: json['nomeCompleto'] ?? '',
      especialidade: json['especialidade'],
    );
  }

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
        'role': role.toString(),
        'nomeCompleto': nomeCompleto,
        'especialidade': especialidade,
      };

  bool get isEmpty => username.isEmpty && password.isEmpty;
  static UserModel empty() => UserModel(username: '', password: '', role: UserRole.paciente, nomeCompleto: '', especialidade: null);
} 