import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/utilities/auth/auth_wrapper.dart';
import '../core/utilities/auth/activity_wrapper.dart';
import '../services/service_manager.dart';
import '../services/activity_tracker.dart';
import '../modules/login_page.dart';
import '../modules/home_selection.dart';
import '../modules/inventario/main_page.dart';
import '../modules/licenses/main/main_page.dart';
import '../modules/admin/main_page.dart';
import '../firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final activityTracker = ActivityTracker();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await ServiceManager().initializeAllServices();

  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user != null) {
      activityTracker.initializeTracking();
    } else {
      activityTracker.stopTracking();
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Color primaryColor = Color(0xFF1976D2);
  static const Color secondaryColor = Color(0xFF6B7280);
  static const TextStyle loadingTextStyle = TextStyle(
    fontSize: 16,
    color: secondaryColor,
  );
  static const SizedBox sizedBox16 = SizedBox(height: 16);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GISTC',
      navigatorKey: navigatorKey,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', 'US'), // fallback
      ],
      locale: const Locale('pt', 'BR'),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: primaryColor,
        fontFamily: 'Inter',
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: primaryColor),
                    sizedBox16,
                    Text('Carregando GISTC...', style: loadingTextStyle),
                  ],
                ),
              ),
            );
          }

          if (snapshot.hasData) {
            return const ActivityWrapper(
              child: AuthWrapper(
                requirements: {
                  AuthRequirement.auth,
                  AuthRequirement.firstLogin,
                },
                child: HomeSelectionScreen(),
              ),
            );
          } else {
            return const LoginScreen();
          }
        },
      ),
      routes: {
        '/login': (context) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacementNamed(context, '/home');
            });
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: primaryColor),
                    sizedBox16,
                    Text('Redirecionando...', style: loadingTextStyle),
                  ],
                ),
              ),
            );
          }
          return const LoginScreen();
        },

        '/home': (context) => const ActivityWrapper(
          child: AuthWrapper(
            requirements: {AuthRequirement.auth, AuthRequirement.firstLogin},
            child: HomeSelectionScreen(),
          ),
        ),

        '/inventario': (context) => const ActivityWrapper(
          child: AuthWrapper(
            requirements: {
              AuthRequirement.auth,
              AuthRequirement.firstLogin,
              AuthRequirement.operator,
            },
            child: InventarioMainPage(),
          ),
        ),

        '/licenca': (context) => const ActivityWrapper(
          child: AuthWrapper(
            requirements: {
              AuthRequirement.auth,
              AuthRequirement.firstLogin,
              AuthRequirement.operator,
            },
            child: LicenseMainPage(),
          ),
        ),

        '/auditoria': (context) => const ActivityWrapper(
          child: AuthWrapper(
            requirements: {
              AuthRequirement.auth,
              AuthRequirement.firstLogin,
              AuthRequirement.admin,
            },
            child: AdminMainPage(),
          ),
        ),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              return const ActivityWrapper(
                child: AuthWrapper(
                  requirements: {
                    AuthRequirement.auth,
                    AuthRequirement.firstLogin,
                  },
                  child: HomeSelectionScreen(),
                ),
              );
            } else {
              return const LoginScreen();
            }
          },
        );
      },
    );
  }
}
