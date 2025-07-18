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

  Future<bool> removeEspecialidade(String nome) async {
    // Verificar se há doutores vinculados a esta especialidade
    final doutoresVinculados = _users.where((u) => 
      u.role == UserRole.doutor && 
      u.especialidade == nome
    ).toList();
    
    if (doutoresVinculados.isNotEmpty) {
      // Retornar false para indicar que a remoção foi negada
      return false;
    }
    
    // Se não há doutores vinculados, remover a especialidade
    _especialidades.removeWhere((e) => e.nome == nome);
    await _saveEspecialidades();
    notifyListeners();
    return true;
  }

  Future<void> editEspecialidade(String oldNome, String newNome) async {
    final idx = _especialidades.indexWhere((e) => e.nome == oldNome);
    if (idx != -1) {
      _especialidades[idx] = EspecialidadeModel(nome: newNome);
      await _saveEspecialidades();
      
      // Atualizar usuários doutores que usam esta especialidade
      bool usuariosAtualizados = false;
      for (int i = 0; i < _users.length; i++) {
        if (_users[i].role == UserRole.doutor && _users[i].especialidade == oldNome) {
          _users[i] = UserModel(
            username: _users[i].username,
            password: _users[i].password,
            role: _users[i].role,
            nomeCompleto: _users[i].nomeCompleto,
            especialidade: newNome,
          );
          usuariosAtualizados = true;
        }
      }
      
      // Se houve mudanças nos usuários, salvar
      if (usuariosAtualizados) {
        await _saveUsers();
      }
      
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
    // Remover consultas relacionadas ao usuário
    _consultas.removeWhere((c) => c.paciente == username || c.doutor == username);
    
    // Remover o usuário
    _users.removeWhere((u) => u.username == username);
    
    // Se o usuário atual foi removido, fazer logout
    if (_currentUser?.username == username) {
      _currentUser = null;
    }
    
    await _saveUsers();
    await _saveConsultas();
    notifyListeners();
  }

  Future<void> updateUser(UserModel oldUser, UserModel newUser) async {
    final idx = _users.indexWhere((u) => u.username == oldUser.username);
    if (idx != -1) {
      _users[idx] = newUser;
      await _saveUsers();
      
      // Atualizar consultas que referenciam este usuário
      bool consultasAtualizadas = false;
      
      // Se o username mudou, precisamos atualizar as referências nas consultas
      if (oldUser.username != newUser.username) {
        // Atualizar consultas onde o usuário é paciente
        for (int i = 0; i < _consultas.length; i++) {
          if (_consultas[i].paciente == oldUser.username) {
            _consultas[i] = ConsultaModel(
              paciente: newUser.username,
              doutor: _consultas[i].doutor,
              data: _consultas[i].data,
              hora: _consultas[i].hora,
            );
            consultasAtualizadas = true;
          }
        }
        
        // Atualizar consultas onde o usuário é doutor
        for (int i = 0; i < _consultas.length; i++) {
          if (_consultas[i].doutor == oldUser.username) {
            _consultas[i] = ConsultaModel(
              paciente: _consultas[i].paciente,
              doutor: newUser.username,
              data: _consultas[i].data,
              hora: _consultas[i].hora,
            );
            consultasAtualizadas = true;
          }
        }
        
        // Se o usuário atual foi atualizado, atualizar a referência
        if (_currentUser?.username == oldUser.username) {
          _currentUser = newUser;
        }
      }
      
      // Se houve mudanças nas consultas, salvar
      if (consultasAtualizadas) {
        await _saveConsultas();
      }
      
      notifyListeners();
    }
  }

  Future<void> updateConsulta(ConsultaModel old, ConsultaModel updated) async {
    final idx = _consultas.indexWhere((c) => 
      c.paciente == old.paciente && 
      c.doutor == old.doutor && 
      c.data.isAtSameMomentAs(old.data) && 
      c.hora == old.hora
    );
    if (idx != -1) {
      _consultas[idx] = updated;
      await _saveConsultas();
      notifyListeners();
    }
  }

  Future<void> removeConsulta(ConsultaModel consulta) async {
    _consultas.removeWhere((c) => 
      c.paciente == consulta.paciente && 
      c.doutor == consulta.doutor && 
      c.data.isAtSameMomentAs(consulta.data) && 
      c.hora == consulta.hora
    );
    await _saveConsultas();
    notifyListeners();
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

  // Método para obter informações completas de um usuário
  String getInfoCompleta(String username) {
    final user = _users.firstWhere(
      (u) => u.username == username,
      orElse: () => UserModel.empty(),
    );
    if (user.isEmpty) return username;
    
    if (user.role == UserRole.doutor && user.especialidade != null && user.especialidade!.isNotEmpty) {
      return '${user.nomeCompleto} • ${user.especialidade}';
    }
    return user.nomeCompleto;
  }

  // Método para forçar atualização das consultas
  void refreshConsultas() {
    notifyListeners();
  }

  // Método para verificar se uma especialidade pode ser removida
  List<UserModel> getDoutoresVinculados(String nomeEspecialidade) {
    return _users.where((u) => 
      u.role == UserRole.doutor && 
      u.especialidade == nomeEspecialidade
    ).toList();
  }

  // Método para verificar se uma especialidade pode ser removida
  bool podeRemoverEspecialidade(String nomeEspecialidade) {
    return getDoutoresVinculados(nomeEspecialidade).isEmpty;
  }
} 