import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/consulta_model.dart';
import '../models/especialidade_model.dart';

enum UserRole { paciente, doutor, admin }

class AuthService extends ChangeNotifier {
  UserModel? _currentUser;
  List<UserModel> _users = [];
  bool get isAuthenticated => _currentUser != null;
  UserModel? get currentUser => _currentUser;
  List<UserModel> get users => List.unmodifiable(_users);
  List<ConsultaModel> _consultas = [];
  List<ConsultaModel> get consultas {
    if (_currentUser == null) return [];
    if (_currentUser!.role == UserRole.admin) {
      return List.unmodifiable(_consultas);
    } else if (_currentUser!.role == UserRole.doutor) {
      return _consultas.where((c) => c.doutor == _currentUser!.username).toList();
    } else if (_currentUser!.role == UserRole.paciente) {
      return _consultas.where((c) => c.paciente == _currentUser!.username).toList();
    }
    return [];
  }
  List<EspecialidadeModel> _especialidades = [];
  List<EspecialidadeModel> get especialidades => List.unmodifiable(_especialidades);

  AuthService() {
    _loadUsers();
    _loadConsultas();
    _loadEspecialidades();
  }

  Future<void> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final content = prefs.getString('users');
    if (content != null) {
      final List<dynamic> jsonData = jsonDecode(content);
      _users = jsonData.map((e) => UserModel.fromJson(e)).toList();
    } else {
      // Cria admin padrão se não existir
      _users = [UserModel(username: 'admin', password: 'admin', role: UserRole.admin, nomeCompleto: 'Administrador')];
      await _saveUsers();
    }
    notifyListeners();
  }

  Future<void> _saveUsers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('users', jsonEncode(_users.map((e) => e.toJson()).toList()));
  }

  Future<void> _loadConsultas() async {
    final prefs = await SharedPreferences.getInstance();
    final content = prefs.getString('consultas');
    if (content != null) {
      final List<dynamic> jsonData = jsonDecode(content);
      _consultas = jsonData.map((e) => ConsultaModel.fromJson(e)).toList();
    } else {
      _consultas = [];
    }
    notifyListeners();
  }

  Future<void> _saveConsultas() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('consultas', jsonEncode(_consultas.map((e) => e.toJson()).toList()));
  }

  Future<void> addConsulta(ConsultaModel consulta) async {
    _consultas.add(consulta);
    await _saveConsultas();
    notifyListeners();
  }

  Future<void> _loadEspecialidades() async {
    final prefs = await SharedPreferences.getInstance();
    final content = prefs.getString('especialidades');
    if (content != null) {
      final List<dynamic> jsonData = jsonDecode(content);
      _especialidades = jsonData.map((e) => EspecialidadeModel.fromJson(e)).toList();
    } else {
      _especialidades = [];
    }
    notifyListeners();
  }

  Future<void> _saveEspecialidades() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('especialidades', jsonEncode(_especialidades.map((e) => e.toJson()).toList()));
  }

  Future<void> addEspecialidade(String nome) async {
    _especialidades.add(EspecialidadeModel(nome: nome));
    await _saveEspecialidades();
    notifyListeners();
  }

  Future<void> removeEspecialidade(String nome) async {
    _especialidades.removeWhere((e) => e.nome == nome);
    await _saveEspecialidades();
    notifyListeners();
  }

  Future<void> editEspecialidade(String oldNome, String newNome) async {
    final idx = _especialidades.indexWhere((e) => e.nome == oldNome);
    if (idx != -1) {
      _especialidades[idx] = EspecialidadeModel(nome: newNome);
      await _saveEspecialidades();
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    await _loadUsers();
    final user = _users.firstWhere(
      (u) => u.username == username && u.password == password,
      orElse: () => UserModel.empty(),
    );
    if (user.isEmpty) return false;
    _currentUser = user;
    notifyListeners();
    return true;
  }

  Future<bool> register(String username, String password, UserRole role, String nomeCompleto, {String? especialidade}) async {
    if (_users.any((u) => u.username == username)) return false;
    final user = UserModel(username: username, password: password, role: role, nomeCompleto: nomeCompleto, especialidade: especialidade);
    _users.add(user);
    await _saveUsers();
    notifyListeners();
    return true;
  }

  Future<void> removeUser(String username) async {
    _users.removeWhere((u) => u.username == username);
    await _saveUsers();
    notifyListeners();
  }

  Future<void> updateUser(UserModel oldUser, UserModel newUser) async {
    final idx = _users.indexWhere((u) => u.username == oldUser.username);
    if (idx != -1) {
      _users[idx] = newUser;
      await _saveUsers();
      notifyListeners();
    }
  }

  Future<void> updateConsulta(ConsultaModel old, ConsultaModel updated) async {
    final idx = _consultas.indexOf(old);
    if (idx != -1) {
      _consultas[idx] = updated;
      await _saveConsultas();
      notifyListeners();
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  UserRole? get userRole => _currentUser?.role;

  String getNomeCompleto(String username) {
    final user = _users.firstWhere(
      (u) => u.username == username,
      orElse: () => UserModel.empty(),
    );
    return user.isEmpty ? username : user.nomeCompleto;
  }
} 