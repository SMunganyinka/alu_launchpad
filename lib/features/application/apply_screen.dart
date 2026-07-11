import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApplyScreen extends StatefulWidget {
  final String opportunityId;
  final String opportunityTitle;
  final String startupName;

  const ApplyScreen({
    super.key,
    required this.opportunityId,
    required this.opportunityTitle,
    required this.startupName,
  });

  @override
  State<ApplyScreen> createState() => _ApplyScreenState();
}

class _ApplyScreenState extends State<ApplyScreen> {
  final _coverLetterController = TextEditingController();
  bool _isSubmitting = false;
  bool _hasApplied = false;

  Future<void> _submitApplication() async {
    if (_coverLetterController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please write a cover letter")));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;

      // 1. Create the application document
      await FirebaseFirestore.instance.collection('applications').add({
        'opportunityId': widget.opportunityId,
        'opportunityTitle': widget.opportunityTitle,
        'startupName': widget.startupName,
        'applicantId': userId,
        'coverLetter': _coverLetterController.text.trim(),
        'status':
            'pending', // pending, reviewed, shortlisted, accepted, rejected
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Increment the applicant count on the opportunity (Real-time CRUD!)
      await FirebaseFirestore.instance
          .collection('opportunities')
          .doc(widget.opportunityId)
          .update({
        'applicantCount': FieldValue.increment(1),
      });

      setState(() {
        _isSubmitting = false;
        _hasApplied = true;
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to apply: $e")));
    }
  }

  @override
  void dispose() {
    _coverLetterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Apply")),
      body: _hasApplied
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 80, color: Color(0xFF1B5E20)),
                  SizedBox(height: 16),
                  Text("Application Submitted!",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text("You can track the status in your Applications tab."),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.opportunityTitle,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("at ${widget.startupName}",
                      style: const TextStyle(color: Colors.grey)),
                  const Divider(height: 32),
                  const Text("Why are you a good fit?",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _coverLetterController,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      hintText:
                          "Tell the founder about your skills, relevant experience, and why you want this role...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitApplication,
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Submit Application"),
                  ),
                ],
              ),
            ),
    );
  }
}
