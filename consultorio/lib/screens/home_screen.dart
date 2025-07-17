import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'pacientes_screen.dart';
import 'doutores_screen.dart';
import 'consultas_screen.dart';
import 'usuarios_screen.dart';
import 'especialidades_screen.dart';
import '../colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final role = auth.userRole;
    final tabs = <Widget>[];
    final items = <BottomNavigationBarItem>[];

    if (role == UserRole.admin) {
      tabs.add(const EspecialidadesScreen());
      items.add(const BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Especialidades'));
      tabs.add(const PacientesScreen());
      items.add(const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Pacientes'));
      tabs.add(const DoutoresScreen());
      items.add(const BottomNavigationBarItem(icon: Icon(Icons.medical_services), label: 'Doutores'));
      tabs.add(const ConsultasScreen());
      items.add(const BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Consultas'));
      tabs.add(const UsuariosScreen());
      items.add(const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Usuários'));
    } else if (role == UserRole.doutor) {
      tabs.add(const PacientesScreen());
      items.add(const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Pacientes'));
      tabs.add(const ConsultasScreen());
      items.add(const BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Consultas'));
    } else if (role == UserRole.paciente) {
      tabs.add(const DoutoresScreen());
      items.add(const BottomNavigationBarItem(icon: Icon(Icons.medical_services), label: 'Doutores'));
      tabs.add(const ConsultasScreen());
      items.add(const BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Consultas'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultório'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthService>(context, listen: false).logout();
            },
            tooltip: 'Sair',
          ),
        ],
      ),
      body: tabs[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.branco,
          boxShadow: [
            BoxShadow(
              color: AppColors.azulEscuro.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Overlay para destacar o item selecionado (fundo)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(
                  left: (_currentIndex * (MediaQuery.of(context).size.width / items.length)),
                  right: ((items.length - 1 - _currentIndex) * (MediaQuery.of(context).size.width / items.length)),
                ),
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.azulClaro,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
              ),
            ),
            // BottomNavigationBar (conteúdo)
            BottomNavigationBar(
              currentIndex: _currentIndex,
              items: items,
              onTap: (i) => setState(() => _currentIndex = i),
              showUnselectedLabels: true,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              backgroundColor: Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
} 