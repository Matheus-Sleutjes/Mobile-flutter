import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _password = '';
  bool _isLogin = true;
  UserRole _role = UserRole.paciente;
  bool _loading = false;
  String _nomeCompleto = '';

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _loading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    bool success = false;
    if (_isLogin) {
      success = await auth.login(_username, _password);
      if (!success) _showMessage('Usuário ou senha inválidos');
    } else {
      success = await auth.register(_username, _password, UserRole.paciente, _nomeCompleto);
      if (!success) _showMessage('Usuário já existe');
      else _showMessage('Cadastro realizado! Faça login.');
      if (success) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) setState(() => _isLogin = true);
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cinza,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 8,
            color: AppColors.branco,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_isLogin ? 'Login' : 'Cadastro',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.azulEscuro,
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 24),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Usuário'),
                      onSaved: (v) => _username = v!.trim(),
                      validator: (v) => v == null || v.isEmpty ? 'Informe o usuário' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Senha'),
                      obscureText: true,
                      onSaved: (v) => _password = v!,
                      validator: (v) => v == null || v.length < 4 ? 'Mínimo 4 caracteres' : null,
                    ),
                    if (!_isLogin) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Nome completo'),
                        onSaved: (v) => _nomeCompleto = v!.trim(),
                        validator: (v) => v == null || v.isEmpty ? 'Informe o nome completo' : null,
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _loading
                            ? const CircularProgressIndicator.adaptive()
                            : Text(_isLogin ? 'Entrar' : 'Cadastrar'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () => setState(() => _isLogin = !_isLogin),
                      child: Text(_isLogin
                          ? 'Não tem conta? Cadastre-se'
                          : 'Já tem conta? Faça login'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 