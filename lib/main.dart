import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';

import 'injection_container.dart';
import 'core/theme.dart';
import 'core/main_shell.dart';

import 'features/auth/auth_bloc.dart';
import 'features/auth/auth_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/onboarding/founder_pending_screen.dart';
import 'features/opportunity/opportunity_bloc.dart';
import 'features/bookmark/bookmark_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await init();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyC-acKdK8eK5zwj9802jpxfVjkZ438JOXg",
        appId: "1:864839720244:web:3be51bc5d643ca63299961",
        messagingSenderId: "864839720244",
        projectId: "alu-launchpad-89ef9",
        storageBucket: "alu-launchpad-89ef9.firebasestorage.app",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => sl<AuthBloc>()..add(AuthCheckRequested()),
        ),
        BlocProvider(create: (context) => OpportunityBloc()),
        BlocProvider(create: (context) => sl<BookmarkCubit>()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ALU LaunchPad',
        theme: AppTheme.light,
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            // 1. Not logged in
            if (state is AuthUnauthenticated ||
                state is AuthInitial ||
                state is AuthError) {
              return const AuthScreen();
            }

            // 2. Logged in, so we can safely cast to AuthAuthenticated
            if (state is AuthAuthenticated) {
              final authState = state;

              // 3. Founder but NOT verified -> Show Pending Screen
              if (authState.role == 'founder' && !authState.isVerified) {
                return const FounderPendingScreen();
              }

              // 4. Verified Founder OR Student, but hasn't onboarded -> Show Onboarding
              if (!authState.onboardingComplete) {
                return const OnboardingScreen();
              }

              // 5. Fully setup -> Show Main App
              return const MainShell();
            }

            return const AuthScreen();
          },
        ),
      ),
    );
  }
}
