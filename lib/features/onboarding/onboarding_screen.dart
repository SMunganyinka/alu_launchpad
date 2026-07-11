import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final Set<String> _selectedSkills = {};
  bool _isSaving = false;

  final List<String> _availableSkills = [
    'Flutter',
    'React',
    'Python',
    'UI/UX Design',
    'Figma',
    'Digital Marketing',
    'Content Writing',
    'Data Analysis',
    'Business Strategy',
    'Project Management',
    'Sales',
    'Research',
  ];

  Future<void> _completeOnboarding() async {
    if (_selectedSkills.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least 3 skills")),
      );
      return;
    }

    setState(() => _isSaving = true);

    final userId = FirebaseAuth.instance.currentUser!.uid;

    // 1. Save skills to Firestore
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'skills': _selectedSkills.toList(),
      'onboardingComplete': true,
    });

    // 2. Tell the BLoC that onboarding is done so it routes to MainShell
    if (mounted) {
      context.read<AuthBloc>().add(AuthCheckRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text("What are your skills?",
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text("Select at least 3 to help startups find you.",
                  style: TextStyle(color: Colors.grey)),

              // Progress indicator
              const SizedBox(height: 24),
              LinearProgressIndicator(
                value: (_selectedSkills.length / 3).clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade200,
                color: const Color(0xFF1B5E20),
              ),
              const SizedBox(height: 24),

              // Skills Grid
              Expanded(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _availableSkills.map((skill) {
                    final isSelected = _selectedSkills.contains(skill);
                    return FilterChip(
                      label: Text(skill),
                      selected: isSelected,
                      selectedColor: const Color(0xFF1B5E20).withOpacity(0.2),
                      checkmarkColor: const Color(0xFF1B5E20),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? const Color(0xFF1B5E20)
                            : Colors.black87,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) {
                        setState(() {
                          if (isSelected) {
                            _selectedSkills.remove(skill);
                          } else {
                            _selectedSkills.add(skill);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),

              // Complete Button
              ElevatedButton(
                onPressed: _isSaving ? null : _completeOnboarding,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "Complete Setup (${_selectedSkills.length} selected)"),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
