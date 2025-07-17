import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../colors.dart';

class EspecialidadesScreen extends StatelessWidget {
  const EspecialidadesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        final TextEditingController searchController = TextEditingController();
        List especialidades = auth.especialidades;
        return StatefulBuilder(
          builder: (context, setState) {
            String search = searchController.text.toLowerCase();
            final filtered = search.isEmpty
                ? especialidades
                : especialidades.where((e) => e.nome.toLowerCase().contains(search)).toList();
            return Scaffold(
              appBar: AppBar(
                title: const Text('Especialidades'),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(56),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Pesquisar especialidade...',
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
              body: filtered.isEmpty
                  ? const Center(child: Text('Nenhuma especialidade cadastrada.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final e = filtered[i];
                        return Card(
                          child: ListTile(
                            title: Text(e.nome),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () async {
                                    final controller = TextEditingController(text: e.nome);
                                    final newNome = await showDialog<String>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Editar Especialidade'),
                                        content: TextField(
                                          controller: controller,
                                          decoration: const InputDecoration(labelText: 'Nome'),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(ctx).pop(),
                                            child: const Text('Cancelar'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
                                            child: const Text('Salvar'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (newNome != null && newNome.isNotEmpty && newNome != e.nome) {
                                      await auth.editEspecialidade(e.nome, newNome);
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Remover Especialidade'),
                                        content: Text('Deseja remover a especialidade "${e.nome}"?'),
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
                                      await auth.removeEspecialidade(e.nome);
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
                  final controller = TextEditingController();
                  final nome = await showDialog<String>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Nova Especialidade'),
                      content: TextField(
                        controller: controller,
                        decoration: const InputDecoration(labelText: 'Nome'),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
                          child: const Text('Salvar'),
                        ),
                      ],
                    ),
                  );
                  if (nome != null && nome.isNotEmpty) {
                    await auth.addEspecialidade(nome);
                  }
                },
                child: const Icon(Icons.add),
                tooltip: 'Nova Especialidade',
              ),
            );
          },
        );
      },
    );
  }
} 