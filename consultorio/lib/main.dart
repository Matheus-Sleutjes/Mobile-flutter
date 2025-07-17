// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
// Importações dos providers e telas (a serem criados)
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        // Outros providers podem ser adicionados aqui
      ],
      child: MaterialApp(
        title: 'Consultório',
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.cinza,
          colorScheme: ColorScheme(
            brightness: Brightness.light,
            primary: AppColors.azulEscuro,
            onPrimary: AppColors.branco,
            secondary: AppColors.azulClaro,
            onSecondary: AppColors.branco,
            error: Colors.red,
            onError: AppColors.branco,
            background: AppColors.cinza,
            onBackground: AppColors.preto,
            surface: AppColors.branco,
            onSurface: AppColors.preto,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.azulEscuro,
            foregroundColor: AppColors.branco,
            iconTheme: IconThemeData(color: AppColors.branco),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: AppColors.branco,
            selectedItemColor: AppColors.branco,
            unselectedItemColor: AppColors.azulEscuro,
            selectedIconTheme: IconThemeData(color: AppColors.branco),
            unselectedIconTheme: IconThemeData(color: AppColors.azulEscuro),
            selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, color: AppColors.branco),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, color: AppColors.azulEscuro),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
          ),
          cardTheme: const CardThemeData(
            color: AppColors.branco,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            labelStyle: TextStyle(color: AppColors.azulEscuro),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.azulEscuro.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.azulEscuro.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.azulEscuro, width: 2),
            ),
            filled: true,
            fillColor: AppColors.branco,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.azulEscuro,
              foregroundColor: AppColors.branco,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.azulEscuro,
            ),
          ),
          textTheme: GoogleFonts.poppinsTextTheme(),
        ),
        debugShowCheckedModeBanner: false,
        home: const AuthOrHome(),
      ),
    );
  }
}

class AuthOrHome extends StatelessWidget {
  const AuthOrHome({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    if (auth.isAuthenticated) {
      return const HomeScreen();
    } else {
      return const LoginScreen();
    }
  }
}
