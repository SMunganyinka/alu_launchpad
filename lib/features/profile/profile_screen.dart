import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth/auth_bloc.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                context.read<AuthBloc>().add(AuthLogoutRequested()),
          )
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("User data not found."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final skills = List<String>.from(data['skills'] ?? []);

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Profile Header
              const CircleAvatar(
                radius: 50,
                child: Icon(Icons.person, size: 50),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  data['displayName'] ?? 'Student',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              Center(
                child: Text(
                  data['email'] ?? '',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              const Divider(height: 40),

              // Skills Section
              const Text("My Skills",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (skills.isEmpty)
                const Text("No skills added yet.")
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: skills
                      .map((skill) => Chip(
                            label: Text(skill),
                            backgroundColor:
                                const Color(0xFF1B5E20).withOpacity(0.1),
                            side: const BorderSide(color: Color(0xFF1B5E20)),
                            labelStyle: const TextStyle(
                                color: Color(0xFF1B5E20),
                                fontWeight: FontWeight.w600),
                          ))
                      .toList(),
                ),
            ],
          );
        },
      ),
    );
  }
}
