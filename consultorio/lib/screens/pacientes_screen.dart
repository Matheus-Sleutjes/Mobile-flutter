import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../colors.dart';

class PacientesScreen extends StatefulWidget {
  const PacientesScreen({super.key});

  @override
  State<PacientesScreen> createState() => _PacientesScreenState();
}

class _PacientesScreenState extends State<PacientesScreen> {
  Future<void> _showAddPacienteDialog(BuildContext context) async {
    final _formKey = GlobalKey<FormState>();
    String username = '';
    String password = '';
    String nomeCompleto = '';
    bool loading = false;
    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Adicionar Paciente'),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Nome completo'),
                    onSaved: (v) => nomeCompleto = v!.trim(),
                    validator: (v) => v == null || v.isEmpty ? 'Informe o nome completo' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Usuário'),
                    onSaved: (v) => username = v!.trim(),
                    validator: (v) => v == null || v.isEmpty ? 'Informe o usuário' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Senha'),
                    obscureText: true,
                    onSaved: (v) => password = v!,
                    validator: (v) => v == null || v.length < 4 ? 'Mínimo 4 caracteres' : null,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: loading ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: loading
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        _formKey.currentState!.save();
                        setState(() => loading = true);
                        final auth = Provider.of<AuthService>(context, listen: false);
                        final success = await auth.register(username, password, UserRole.paciente, nomeCompleto);
                        setState(() => loading = false);
                        if (!success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Usuário já existe!')),
                          );
                        } else {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Paciente cadastrado!')),
                          );
                          auth.notifyListeners(); // Atualiza a lista
                        }
                      },
                child: loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Salvar'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        final TextEditingController searchController = TextEditingController();
        final isAdmin = auth.currentUser?.role == UserRole.admin;
        List<UserModel> pacientes = auth.users.where((u) => u.role == UserRole.paciente).toList();
        return StatefulBuilder(
          builder: (context, setState) {
            String search = searchController.text.toLowerCase();
            final filtered = search.isEmpty
                ? pacientes
                : pacientes.where((p) => p.nomeCompleto.toLowerCase().contains(search) || p.username.toLowerCase().contains(search)).toList();
            return Scaffold(
              appBar: AppBar(
                title: const Text('Pacientes'),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(56),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Pesquisar paciente...',
                        hintStyle: TextStyle(color: AppColors.azulEscuro.withOpacity(0.6)),
                        prefixIcon: Icon(Icons.search, color: AppColors.azulEscuro),
                        filled: true,
                        fillColor: AppColors.branco,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.azulEscuro),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.azulEscuro.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.azulEscuro, width: 2),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
              ),
              body: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final paciente = filtered[i];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(paciente.nomeCompleto),
                      subtitle: Text(paciente.username),
                      trailing: isAdmin
                          ? IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                final nomeController = TextEditingController(text: paciente.nomeCompleto);
                                final userController = TextEditingController(text: paciente.username);
                                final result = await showDialog<Map<String, String>>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Editar Paciente'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextField(
                                          controller: nomeController,
                                          decoration: const InputDecoration(labelText: 'Nome completo'),
                                        ),
                                        const SizedBox(height: 16),
                                        TextField(
                                          controller: userController,
                                          decoration: const InputDecoration(labelText: 'Usuário'),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(ctx).pop(),
                                        child: const Text('Cancelar'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.of(ctx).pop({
                                          'nomeCompleto': nomeController.text.trim(),
                                          'username': userController.text.trim(),
                                        }),
                                        child: const Text('Salvar'),
                                      ),
                                    ],
                                  ),
                                );
                                if (result != null && result['nomeCompleto']!.isNotEmpty && result['username']!.isNotEmpty) {
                                  // Atualizar paciente
                                  final updated = UserModel(
                                    username: result['username']!,
                                    password: paciente.password,
                                    role: paciente.role,
                                    nomeCompleto: result['nomeCompleto']!,
                                    especialidade: paciente.especialidade,
                                  );
                                  final users = [...auth.users];
                                  final idx = users.indexWhere((u) => u.username == paciente.username);
                                  if (idx != -1) {
                                    users[idx] = updated;
                                    await Provider.of<AuthService>(context, listen: false).updateUser(paciente, updated);
                                    Provider.of<AuthService>(context, listen: false).notifyListeners();
                                  }
                                }
                              },
                            )
                          : null,
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
} 