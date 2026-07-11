import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added this import
import 'opportunity_bloc.dart';

class CreateOpportunityScreen extends StatefulWidget {
  const CreateOpportunityScreen({super.key});

  @override
  State<CreateOpportunityScreen> createState() =>
      _CreateOpportunityScreenState();
}

class _CreateOpportunityScreenState extends State<CreateOpportunityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _hoursController = TextEditingController();

  String? selectedCategory;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<OpportunityBloc>().add(AddOpportunity({
          'title': _titleController.text.trim(),
          'description': _descController.text.trim(),
          'category': selectedCategory!,
          'hoursPerWeek': int.parse(_hoursController.text),
          'isPaid': false,
          'startupName': 'My ALU Startup',
          'founderId':
              FirebaseAuth.instance.currentUser!.uid, // Added this line!
        }));

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Post Opportunity")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            DropdownButtonFormField<String>(
              value: selectedCategory,
              hint: const Text("Choose your role"),
              items: [
                'Software Dev',
                'Design',
                'Marketing',
                'Business Analysis',
                'Research'
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => selectedCategory = v),
              decoration: const InputDecoration(labelText: "Role Category"),
              validator: (v) => v == null ? "Please select a role" : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Opportunity Title"),
              validator: (v) => v!.isEmpty ? "Required" : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: "Description"),
              maxLines: 4,
              validator: (v) => v!.isEmpty ? "Required" : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hoursController,
              decoration: const InputDecoration(labelText: "Hours per week"),
              keyboardType: TextInputType.number,
              validator: (v) => v != null && int.tryParse(v) != null
                  ? null
                  : "Enter valid number",
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _submit,
              child: const Text("Publish Opportunity"),
            ),
          ],
        ),
      ),
    );
  }
}
