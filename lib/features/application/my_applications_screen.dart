import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MyApplicationsScreen extends StatelessWidget {
  const MyApplicationsScreen({super.key});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'shortlisted':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      case 'reviewed':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Applications"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // REMOVED .orderBy() HERE to fix the crashing bug
        stream: FirebaseFirestore.instance
            .collection('applications')
            .where('applicantId', isEqualTo: currentUserId)
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
                  Icon(Icons.work_off_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("You haven't applied to anything yet.",
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                  SizedBox(height: 8),
                  Text("Go to Discover to find opportunities!",
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            );
          }

          final applications = snapshot.data!.docs;

          // ADDED: Sort locally in Dart instead of Firebase
          applications.sort((a, b) {
            final aTime = (a['createdAt'] as Timestamp?) ?? Timestamp.now();
            final bTime = (b['createdAt'] as Timestamp?) ?? Timestamp.now();
            return bTime.compareTo(aTime); // Newest first
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final app = applications[index];
              final data = app.data() as Map<String, dynamic>;
              final status = data['status'] ?? 'pending';
              final timestamp = data['createdAt'] as Timestamp?;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Title and Status Badge
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['opportunityTitle'] ?? 'Untitled Role',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "at ${data['startupName'] ?? 'Startup'}",
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          // The Status Badge (Updates in real-time!)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: _getStatusColor(status), width: 1.5),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(status),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 24),

                      // Timeline Visual
                      Row(
                        children: [
                          _buildTimelinePoint(
                              isActive: true, color: Colors.green),
                          _buildTimelineLine(isActive: status != 'pending'),
                          _buildTimelinePoint(
                              isActive: status != 'pending',
                              color: status != 'pending'
                                  ? Colors.orange
                                  : Colors.grey),
                          _buildTimelineLine(
                              isActive: status == 'shortlisted' ||
                                  status == 'accepted'),
                          _buildTimelinePoint(
                              isActive: status == 'shortlisted' ||
                                  status == 'accepted',
                              color: (status == 'shortlisted' ||
                                      status == 'accepted')
                                  ? Colors.blue
                                  : Colors.grey),
                          _buildTimelineLine(isActive: status == 'accepted'),
                          _buildTimelinePoint(
                              isActive: status == 'accepted',
                              color: status == 'accepted'
                                  ? Colors.green
                                  : Colors.grey),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Applied",
                              style:
                                  TextStyle(fontSize: 10, color: Colors.grey)),
                          Text("Reviewed",
                              style:
                                  TextStyle(fontSize: 10, color: Colors.grey)),
                          Text("Shortlisted",
                              style:
                                  TextStyle(fontSize: 10, color: Colors.grey)),
                          Text("Accepted",
                              style:
                                  TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Footer Info
                      if (timestamp != null)
                        Text(
                          "Applied on ${DateFormat('MMM dd, yyyy').format(timestamp.toDate())}",
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Helper widgets for the timeline
  Widget _buildTimelinePoint({required bool isActive, required Color color}) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: isActive ? color : Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildTimelineLine({required bool isActive}) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? Colors.grey.shade400 : Colors.grey.shade200,
      ),
    );
  }
}
