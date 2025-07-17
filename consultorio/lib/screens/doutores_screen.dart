import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'consultas_screen.dart'; // Added import for ConsultasScreen
import '../colors.dart';

class DoutoresScreen extends StatefulWidget {
  const DoutoresScreen({super.key});

  @override
  State<DoutoresScreen> createState() => _DoutoresScreenState();
}

class _DoutoresScreenState extends State<DoutoresScreen> {
  Future<void> _showAddDoutorDialog(BuildContext context) async {
    final _formKey = GlobalKey<FormState>();
    String username = '';
    String password = '';
    String nomeCompleto = '';
    String especialidade = '';
    bool loading = false;
    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Adicionar Doutor'),
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
                        final especialidades = auth.especialidades;
                        final success = await auth.register(username, password, UserRole.doutor, nomeCompleto, especialidade: especialidade);
                        setState(() => loading = false);
                        if (!success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Usuário já existe!')),
                          );
                        } else {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Doutor cadastrado!')),
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
        List<UserModel> doutores = auth.users.where((u) => u.role == UserRole.doutor).toList();
        final currentUser = auth.currentUser;
        final isPaciente = currentUser?.role == UserRole.paciente;
        final isAdmin = auth.currentUser?.role == UserRole.admin;
        final especialidades = auth.especialidades;
        return StatefulBuilder(
          builder: (context, setState) {
            String search = searchController.text.toLowerCase();
            final filtered = search.isEmpty
                ? doutores
                : doutores.where((d) => d.nomeCompleto.toLowerCase().contains(search) || d.username.toLowerCase().contains(search) || (d.especialidade ?? '').toLowerCase().contains(search)).toList();
            return Scaffold(
              appBar: AppBar(
                title: const Text('Doutores'),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(56),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Pesquisar doutor...',
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
                  final doutor = filtered[i];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.medical_services),
                      title: Text(doutor.nomeCompleto),
                      subtitle: Text(doutor.especialidade != null && doutor.especialidade!.isNotEmpty ? doutor.especialidade! : 'Sem especialidade'),
                      trailing: isAdmin
                          ? IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                final nomeController = TextEditingController(text: doutor.nomeCompleto);
                                final userController = TextEditingController(text: doutor.username);
                                String especialidade = doutor.especialidade ?? '';
                                final result = await showDialog<Map<String, String>>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Editar Doutor'),
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
                                  // Atualizar doutor
                                  final updated = UserModel(
                                    username: result['username']!,
                                    password: doutor.password,
                                    role: doutor.role,
                                    nomeCompleto: result['nomeCompleto']!,
                                    especialidade: result['especialidade'],
                                  );
                                  await Provider.of<AuthService>(context, listen: false).updateUser(doutor, updated);
                                  Provider.of<AuthService>(context, listen: false).notifyListeners();
                                }
                              },
                            )
                          : isPaciente
                              ? IconButton(
                                  icon: const Icon(Icons.schedule),
                                  onPressed: () {
                                    // Abrir modal de agendamento com o doutor pré-selecionado
                                    ConsultasScreen.showAddConsultaDialogWithDoutor(context, doutor);
                                  },
                                )
                              : null,
                      onTap: isPaciente
                          ? () {
                              // Abrir modal de agendamento com o doutor pré-selecionado
                              ConsultasScreen.showAddConsultaDialogWithDoutor(context, doutor);
                            }
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