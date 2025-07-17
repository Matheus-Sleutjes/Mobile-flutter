import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../colors.dart';

class UsuariosScreen extends StatelessWidget {
  const UsuariosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        final TextEditingController searchController = TextEditingController();
        List<UserModel> usuarios = auth.users;
        final currentUser = auth.currentUser;
        final isAdmin = auth.currentUser?.role == UserRole.admin;
        final especialidades = auth.especialidades;
        return StatefulBuilder(
          builder: (context, setState) {
            String search = searchController.text.toLowerCase();
            final filtered = search.isEmpty
                ? usuarios
                : usuarios.where((u) => u.nomeCompleto.toLowerCase().contains(search) || u.username.toLowerCase().contains(search) || (u.especialidade ?? '').toLowerCase().contains(search)).toList();
            return Scaffold(
              appBar: AppBar(
                title: const Text('Usuários'),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(56),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Pesquisar usuário...',
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
                  final user = filtered[i];
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        user.role == UserRole.admin
                            ? Icons.admin_panel_settings
                            : user.role == UserRole.doutor
                                ? Icons.medical_services
                                : Icons.person,
                      ),
                      title: Text(user.nomeCompleto),
                      subtitle: user.role == UserRole.doutor && user.especialidade != null && user.especialidade!.isNotEmpty
                          ? Text('${user.username} • ${user.role.name[0].toUpperCase() + user.role.name.substring(1)} • ${user.especialidade}')
                          : Text('${user.username} • ' + user.role.name[0].toUpperCase() + user.role.name.substring(1)),
                      trailing: user.username == currentUser?.username
                          ? null
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isAdmin)
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () async {
                                      final nomeController = TextEditingController(text: user.nomeCompleto);
                                      final userController = TextEditingController(text: user.username);
                                      String especialidade = user.especialidade ?? '';
                                      final result = await showDialog<Map<String, String>>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Editar Usuário'),
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
                                                if (user.role == UserRole.doutor) ...[
                                                  const SizedBox(height: 16),
                                                  DropdownButtonFormField<String>(
                                                    value: especialidade.isNotEmpty ? especialidade : null,
                                                    decoration: const InputDecoration(labelText: 'Especialidade'),
                                                    items: especialidades
                                                        .map((e) => DropdownMenuItem(
                                                              value: e.nome,
                                                              child: Text(e.nome),
                                                            ))
                                                        .toList(),
                                                    onChanged: (v) => especialidade = v ?? '',
                                                  ),
                                                ],
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
                                                'especialidade': especialidade,
                                              }),
                                              child: const Text('Salvar'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (result != null && result['nomeCompleto']!.isNotEmpty && result['username']!.isNotEmpty) {
                                        // Atualizar usuário
                                        final updated = UserModel(
                                          username: result['username']!,
                                          password: user.password,
                                          role: user.role,
                                          nomeCompleto: result['nomeCompleto']!,
                                          especialidade: user.role == UserRole.doutor ? result['especialidade'] : null,
                                        );
                                        await Provider.of<AuthService>(context, listen: false).updateUser(user, updated);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Usuário atualizado!')),
                                        );
                                      }
                                    },
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Remover',
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Remover usuário'),
                                        content: Text('Deseja remover o usuário "${user.username}"?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(ctx).pop(false),
                                            child: const Text('Cancelar'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.of(ctx).pop(true),
                                            child: const Text('Remover'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await auth.removeUser(user.username);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Usuário removido!')),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                    ),
                  );
                },
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () async {
                  final _formKey = GlobalKey<FormState>();
                  String username = '';
                  String password = '';
                  String nomeCompleto = '';
                  UserRole role = UserRole.paciente;
                  bool loading = false;
                  String especialidade = '';
                  await showDialog(
                    context: context,
                    builder: (ctx) {
                      return StatefulBuilder(
                        builder: (ctx, setState) => AlertDialog(
                          title: const Text('Adicionar Usuário'),
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
                                const SizedBox(height: 16),
                                DropdownButtonFormField<UserRole>(
                                  value: role,
                                  decoration: const InputDecoration(labelText: 'Tipo de usuário'),
                                  items: UserRole.values
                                      .map((r) => DropdownMenuItem(
                                            value: r,
                                            child: Text(r.name[0].toUpperCase() + r.name.substring(1)),
                                          ))
                                      .toList(),
                                  onChanged: (v) => setState(() => role = v!),
                                ),
                                if (role == UserRole.doutor) ...[
                                  DropdownButtonFormField<String>(
                                    value: especialidade.isNotEmpty ? especialidade : null,
                                    decoration: const InputDecoration(labelText: 'Especialidade'),
                                    items: Provider.of<AuthService>(context, listen: false).especialidades
                                        .map((e) => DropdownMenuItem(
                                              value: e.nome,
                                              child: Text(e.nome),
                                            ))
                                        .toList(),
                                    onChanged: (v) => setState(() => especialidade = v ?? ''),
                                    validator: (v) => v == null || v.isEmpty ? 'Selecione a especialidade' : null,
                                  ),
                                ],
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
                                      final success = await Provider.of<AuthService>(context, listen: false)
                                          .register(username, password, role, nomeCompleto, especialidade: role == UserRole.doutor ? especialidade : null);
                                      setState(() => loading = false);
                                      if (!success) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Usuário já existe!')),
                                        );
                                      } else {
                                        await Future.delayed(const Duration(milliseconds: 100));
                                        if (ctx.mounted) Navigator.of(ctx).pop();
                                        (context as Element).markNeedsBuild();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Usuário cadastrado!')),
                                        );
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
                },
                child: const Icon(Icons.add),
                tooltip: 'Adicionar Usuário',
              ),
            );
          },
        );
      },
    );
  }
} 