import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_bloc.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool isLogin = true;
  String selectedRole = 'student';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (isLogin) {
      context.read<AuthBloc>().add(AuthLoginRequested(
          _emailController.text.trim(), _passwordController.text));
    } else {
      context.read<AuthBloc>().add(AuthRegisterRequested(
            _emailController.text.trim(),
            _passwordController.text,
            _nameController.text.trim(),
            selectedRole,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.rocket_launch,
                      size: 80, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 24),
                  Text(
                    isLogin ? "Welcome Back" : "Join ALU LaunchPad",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 24),

                  // --- REGISTER ONLY: Role Toggle ---
                  if (!isLogin) ...[
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => selectedRole = 'student'),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: selectedRole == 'student'
                                      ? const Color(0xFF1B5E20)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "I'm a Student",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: selectedRole == 'student'
                                        ? Colors.white
                                        : Colors.black54,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => selectedRole = 'founder'),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: selectedRole == 'founder'
                                      ? const Color(0xFF1B5E20)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "I'm a Founder",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: selectedRole == 'founder'
                                        ? Colors.white
                                        : Colors.black54,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- REGISTER ONLY: Name Field ---
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: "Full Name"),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // --- ALWAYS VISIBLE: Email Field ---
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: "ALU Email"),
                    validator: (v) => v!.contains('@') ? null : "Invalid email",
                  ),
                  const SizedBox(height: 16),

                  // --- ALWAYS VISIBLE: Password Field ---
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: "Password"),
                    validator: (v) =>
                        v!.length >= 6 ? null : "Min 6 characters",
                  ),
                  const SizedBox(height: 32),

                  // --- ALWAYS VISIBLE: Submit Button ---
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return ElevatedButton(
                        onPressed: state is AuthLoading ? null : _submit,
                        child: state is AuthLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text(isLogin ? "Sign In" : "Sign Up"),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // --- ALWAYS VISIBLE: Toggle Login/Signup ---
                  TextButton(
                    onPressed: () => setState(() => isLogin = !isLogin),
                    child: Text(
                      isLogin
                          ? "Don't have an account? Sign Up"
                          : "Already have an account? Sign In",
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
