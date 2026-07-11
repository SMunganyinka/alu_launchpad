import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth/auth_bloc.dart';

class FounderPendingScreen extends StatelessWidget {
  const FounderPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Startup Verification"),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                context.read<AuthBloc>().add(AuthLogoutRequested()),
          )
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.hourglass_top,
                    size: 64, color: Colors.amber.shade700),
              ),
              const SizedBox(height: 24),
              const Text("Under Review",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text(
                "Your startup profile is currently being reviewed by the ALU LaunchPad team to ensure it meets our ecosystem guidelines.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () =>
                    context.read<AuthBloc>().add(AuthCheckRequested()),
                icon: const Icon(Icons.refresh),
                label: const Text("Check Status"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
