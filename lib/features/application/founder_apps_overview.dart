import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'received_applications_screen.dart';

class FounderAppsOverview extends StatelessWidget {
  const FounderAppsOverview({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Received Applications"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // FIXED: Query by exact Founder ID instead of startup name
        // REMOVED .orderBy() to fix the disappearing screen bug
        stream: FirebaseFirestore.instance
            .collection('opportunities')
            .where('founderId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No applications received yet.",
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                  SizedBox(height: 8),
                  Text("Post an opportunity to start receiving applications!",
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            );
          }

          final opportunities = snapshot.data!.docs;

          // ADDED: Sort locally in Dart to avoid Firebase Composite Index errors
          opportunities.sort((a, b) {
            final aTime = (a['createdAt'] as Timestamp?) ?? Timestamp.now();
            final bTime = (b['createdAt'] as Timestamp?) ?? Timestamp.now();
            return bTime.compareTo(aTime); // Newest first
          });

          // Optional: Hide opportunities with 0 applicants to clean up the list
          final activeOpps = opportunities.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['applicantCount'] ?? 0) > 0;
          }).toList();

          if (activeOpps.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("Your opportunities have no applicants yet.",
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activeOpps.length,
            itemBuilder: (context, index) {
              final data = activeOpps[index].data() as Map<String, dynamic>;
              final timestamp = data['createdAt'] as Timestamp?;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(data['title'] ?? 'Untitled',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(timestamp != null
                      ? "Posted ${DateFormat('MMM dd').format(timestamp.toDate())}"
                      : ""),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B5E20).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${data['applicantCount']} Applicants",
                      style: const TextStyle(
                          color: Color(0xFF1B5E20),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReceivedApplicationsScreen(
                          opportunityId: activeOpps[index].id,
                          opportunityTitle: data['title'] ?? 'Untitled',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
