import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../models/consulta_model.dart';
import '../colors.dart';

class ConsultasScreen extends StatelessWidget {
  const ConsultasScreen({super.key});

  Future<void> _showAddConsultaDialog(BuildContext context) async {
    final _formKey = GlobalKey<FormState>();
    UserModel? paciente;
    UserModel? doutor;
    DateTime? data;
    TimeOfDay? hora;
    bool loading = false;
    final auth = Provider.of<AuthService>(context, listen: false);
    final pacientes = auth.users.where((u) => u.role == UserRole.paciente).toList();
    final doutores = auth.users.where((u) => u.role == UserRole.doutor).toList();
    final currentUser = auth.currentUser;
    final isAdmin = currentUser?.role == UserRole.admin;
    final isDoutor = currentUser?.role == UserRole.doutor;
    final isPaciente = currentUser?.role == UserRole.paciente;
    if (isDoutor) {
      doutor = currentUser;
    }
    if (isPaciente) {
      paciente = currentUser;
    }
    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Agendar Consulta'),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isAdmin)
                    DropdownButtonFormField<UserModel>(
                      value: paciente,
                      decoration: const InputDecoration(labelText: 'Paciente'),
                      items: pacientes
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p.nomeCompleto),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => paciente = v),
                      validator: (v) => v == null ? 'Selecione o paciente' : null,
                    )
                  else
                    TextFormField(
                      enabled: false,
                      initialValue: currentUser?.nomeCompleto ?? '',
                      decoration: const InputDecoration(labelText: 'Paciente'),
                    ),
                  const SizedBox(height: 16),
                  if (isAdmin || isPaciente)
                    DropdownButtonFormField<UserModel>(
                      value: doutor,
                      decoration: const InputDecoration(labelText: 'Doutor'),
                      items: doutores
                          .map((d) => DropdownMenuItem(
                                value: d,
                                child: Text(d.especialidade != null && d.especialidade!.isNotEmpty
                                    ? '${d.nomeCompleto} • ${d.especialidade}'
                                    : d.nomeCompleto),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => doutor = v),
                      validator: (v) => v == null ? 'Selecione o doutor' : null,
                    )
                  else
                    TextFormField(
                      enabled: false,
                      initialValue: isDoutor ? currentUser?.nomeCompleto ?? '' : doutor?.nomeCompleto ?? '',
                      decoration: const InputDecoration(labelText: 'Doutor'),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(data == null
                            ? 'Selecione a data'
                            : '${data!.day}/${data!.month}/${data!.year}'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) setState(() => data = picked);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(hora == null
                            ? 'Selecione o horário'
                            : hora!.format(ctx)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.access_time),
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.now(),
                          );
                          if (picked != null) setState(() => hora = picked);
                        },
                      ),
                    ],
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
                        if (data == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Selecione a data!')),
                          );
                          return;
                        }
                        if (hora == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Selecione o horário!')),
                          );
                          return;
                        }
                        await auth.addConsulta(
                          ConsultaModel(
                            paciente: (isAdmin ? paciente : isPaciente ? currentUser : paciente)!.username,
                            doutor: (isAdmin || isPaciente ? doutor : isDoutor ? currentUser : doutor)!.username,
                            data: data!,
                            hora: hora!.format(context),
                          ),
                        );
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Consulta agendada!')),
                        );
                      },
                child: loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Agendar'),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> showAddConsultaDialogWithDoutor(BuildContext context, UserModel doutorSelecionado) async {
    final _formKey = GlobalKey<FormState>();
    UserModel? paciente;
    UserModel? doutor = doutorSelecionado;
    DateTime? data;
    TimeOfDay? hora;
    bool loading = false;
    final auth = Provider.of<AuthService>(context, listen: false);
    final pacientes = auth.users.where((u) => u.role == UserRole.paciente).toList();
    final currentUser = auth.currentUser;
    final isAdmin = currentUser?.role == UserRole.admin;
    final isPaciente = currentUser?.role == UserRole.paciente;
    if (isPaciente) {
      paciente = currentUser;
    }
    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Agendar Consulta'),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isAdmin)
                    DropdownButtonFormField<UserModel>(
                      value: paciente,
                      decoration: const InputDecoration(labelText: 'Paciente'),
                      items: pacientes
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p.nomeCompleto),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => paciente = v),
                      validator: (v) => v == null ? 'Selecione o paciente' : null,
                    )
                  else
                    TextFormField(
                      enabled: false,
                      initialValue: currentUser?.nomeCompleto ?? '',
                      decoration: const InputDecoration(labelText: 'Paciente'),
                    ),
                  const SizedBox(height: 16),
                  TextFormField(
                    enabled: false,
                    initialValue: doutorSelecionado.nomeCompleto + (doutorSelecionado.especialidade != null && doutorSelecionado.especialidade!.isNotEmpty ? ' • ${doutorSelecionado.especialidade}' : ''),
                    decoration: const InputDecoration(labelText: 'Doutor'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(data == null
                            ? 'Selecione a data'
                            : '${data!.day}/${data!.month}/${data!.year}'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) setState(() => data = picked);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(hora == null
                            ? 'Selecione o horário'
                            : hora!.format(ctx)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.access_time),
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.now(),
                          );
                          if (picked != null) setState(() => hora = picked);
                        },
                      ),
                    ],
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
                        if (data == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Selecione a data!')),
                          );
                          return;
                        }
                        if (hora == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Selecione o horário!')),
                          );
                          return;
                        }
                        await auth.addConsulta(
                          ConsultaModel(
                            paciente: (isAdmin ? paciente : isPaciente ? currentUser : paciente)!.username,
                            doutor: doutorSelecionado.username,
                            data: data!,
                            hora: hora!.format(context),
                          ),
                        );
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Consulta agendada!')),
                        );
                      },
                child: loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Agendar'),
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
        final consultas = auth.consultas;
        final TextEditingController searchController = TextEditingController();
        final isAdmin = auth.currentUser?.role == UserRole.admin;
        final isDoutor = auth.currentUser?.role == UserRole.doutor;
        final isPaciente = auth.currentUser?.role == UserRole.paciente;
        return StatefulBuilder(
          builder: (context, setState) {
            String search = searchController.text.toLowerCase();
            final filtered = search.isEmpty
                ? consultas
                : consultas.where((c) =>
                    c.paciente.toLowerCase().contains(search) ||
                    c.doutor.toLowerCase().contains(search) ||
                    c.hora.toLowerCase().contains(search) ||
                    '${c.data.day}/${c.data.month}/${c.data.year}'.contains(search)
                  ).toList();
            return Scaffold(
              appBar: AppBar(
                title: const Text('Consultas'),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(56),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Pesquisar consulta...',
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
                  ? Center(
                      child: Text(
                        'Nenhuma consulta agendada.',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final c = filtered[i];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.event),
                            title: Text('Paciente: ${auth.getNomeCompleto(c.paciente)}'),
                            subtitle: Text('Doutor: ${auth.getInfoCompleta(c.doutor)}\nData: ${c.data.day}/${c.data.month}/${c.data.year} - ${c.hora}'),
                            trailing: isAdmin
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () async {
                                          final pacientes = Provider.of<AuthService>(context, listen: false).users.where((u) => u.role == UserRole.paciente).toList();
                                          final doutores = Provider.of<AuthService>(context, listen: false).users.where((u) => u.role == UserRole.doutor).toList();
                                          
                                          // Encontrar o paciente atual
                                          UserModel? paciente;
                                          try {
                                            paciente = pacientes.firstWhere((u) => u.username == c.paciente);
                                          } catch (e) {
                                            paciente = pacientes.isNotEmpty ? pacientes.first : null;
                                          }
                                          
                                          // Encontrar o doutor atual
                                          UserModel? doutor;
                                          try {
                                            doutor = doutores.firstWhere((u) => u.username == c.doutor);
                                          } catch (e) {
                                            doutor = doutores.isNotEmpty ? doutores.first : null;
                                          }
                                          
                                          // Verificar se encontrou os usuários
                                          if (paciente == null || doutor == null) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Erro: Paciente ou doutor não encontrado')),
                                            );
                                            return;
                                          }
                                          DateTime data = c.data;
                                          TimeOfDay hora;
                                          try {
                                            final horaParts = c.hora.split(':');
                                            hora = TimeOfDay(
                                              hour: int.parse(horaParts[0]),
                                              minute: int.parse(horaParts[1]),
                                            );
                                          } catch (e) {
                                            hora = TimeOfDay.now();
                                          }
                                          final _formKey = GlobalKey<FormState>();
                                          final result = await showDialog<Map<String, dynamic>>(
                                            context: context,
                                            builder: (ctx) => StatefulBuilder(
                                              builder: (ctx, setState) => AlertDialog(
                                                title: const Text('Editar Consulta'),
                                                content: Form(
                                                  key: _formKey,
                                                  child: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      DropdownButtonFormField<UserModel>(
                                                        value: paciente,
                                                        decoration: const InputDecoration(labelText: 'Paciente'),
                                                        items: pacientes
                                                            .map((p) => DropdownMenuItem(
                                                                  value: p,
                                                                  child: Text(p.nomeCompleto),
                                                                ))
                                                            .toList(),
                                                        onChanged: (v) => setState(() => paciente = v),
                                                        validator: (v) => v == null ? 'Selecione o paciente' : null,
                                                        isExpanded: true,
                                                      ),
                                                      const SizedBox(height: 16),
                                                      DropdownButtonFormField<UserModel>(
                                                        value: doutor,
                                                        decoration: const InputDecoration(labelText: 'Doutor'),
                                                        items: doutores
                                                            .map((d) => DropdownMenuItem(
                                                                  value: d,
                                                                  child: Text(d.especialidade != null && d.especialidade!.isNotEmpty ? '${d.nomeCompleto} • ${d.especialidade}' : d.nomeCompleto),
                                                                ))
                                                            .toList(),
                                                        onChanged: (v) => setState(() => doutor = v),
                                                        validator: (v) => v == null ? 'Selecione o doutor' : null,
                                                        isExpanded: true,
                                                      ),
                                                      const SizedBox(height: 16),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(data == null
                                                                ? 'Selecione a data'
                                                                : '${data.day}/${data.month}/${data.year}'),
                                                          ),
                                                          IconButton(
                                                            icon: const Icon(Icons.calendar_today),
                                                            onPressed: () async {
                                                              final picked = await showDatePicker(
                                                                context: ctx,
                                                                initialDate: data,
                                                                firstDate: DateTime(2020),
                                                                lastDate: DateTime(2100),
                                                              );
                                                              if (picked != null) setState(() => data = picked);
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(hora == null
                                                                ? 'Selecione o horário'
                                                                : hora.format(ctx)),
                                                          ),
                                                          IconButton(
                                                            icon: const Icon(Icons.access_time),
                                                            onPressed: () async {
                                                              final picked = await showTimePicker(
                                                                context: ctx,
                                                                initialTime: hora,
                                                              );
                                                              if (picked != null) setState(() => hora = picked);
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.of(ctx).pop(),
                                                    child: const Text('Cancelar'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      if (!_formKey.currentState!.validate()) return;
                                                      if (paciente == null || doutor == null) {
                                                        ScaffoldMessenger.of(ctx).showSnackBar(
                                                          const SnackBar(content: Text('Por favor, selecione paciente e doutor')),
                                                        );
                                                        return;
                                                      }
                                                      if (data == null) {
                                                        ScaffoldMessenger.of(ctx).showSnackBar(
                                                          const SnackBar(content: Text('Por favor, selecione a data')),
                                                        );
                                                        return;
                                                      }
                                                      if (hora == null) {
                                                        ScaffoldMessenger.of(ctx).showSnackBar(
                                                          const SnackBar(content: Text('Por favor, selecione o horário')),
                                                        );
                                                        return;
                                                      }
                                                      _formKey.currentState!.save();
                                                      Navigator.of(ctx).pop({
                                                        'paciente': paciente,
                                                        'doutor': doutor,
                                                        'data': data,
                                                        'hora': hora.format(ctx),
                                                      });
                                                    },
                                                    child: const Text('Salvar'),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                          if (result != null && result['paciente'] != null && result['doutor'] != null) {
                                            try {
                                              await Provider.of<AuthService>(context, listen: false).updateConsulta(
                                                c,
                                                ConsultaModel(
                                                  paciente: result['paciente'].username,
                                                  doutor: result['doutor'].username,
                                                  data: result['data'],
                                                  hora: result['hora'],
                                                ),
                                              );
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Consulta atualizada com sucesso!')),
                                              );
                                            } catch (e) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Erro ao atualizar consulta: $e')),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Confirmar Exclusão'),
                                              content: Text('Tem certeza que deseja remover a consulta do paciente ${auth.getNomeCompleto(c.paciente)} com o doutor ${auth.getNomeCompleto(c.doutor)}?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(ctx).pop(false),
                                                  child: const Text('Cancelar'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () => Navigator.of(ctx).pop(true),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                    foregroundColor: Colors.white,
                                                  ),
                                                  child: const Text('Remover'),
                                                ),
                                              ],
                                            ),
                                          );
                                          
                                          if (confirm == true) {
                                            try {
                                              await Provider.of<AuthService>(context, listen: false).removeConsulta(c);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Consulta removida com sucesso!')),
                                              );
                                            } catch (e) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Erro ao remover consulta: $e')),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    ],
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
              floatingActionButton: (isAdmin || auth.currentUser?.role == UserRole.paciente)
                  ? FloatingActionButton(
                      onPressed: () => _showAddConsultaDialog(context),
                      child: const Icon(Icons.add),
                      tooltip: 'Agendar Consulta',
                    )
                  : null,
            );
          },
        );
      },
    );
  }
} 