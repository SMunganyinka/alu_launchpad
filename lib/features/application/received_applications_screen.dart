import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReceivedApplicationsScreen extends StatelessWidget {
  final String opportunityId;
  final String opportunityTitle;

  const ReceivedApplicationsScreen({
    super.key,
    required this.opportunityId,
    required this.opportunityTitle,
  });

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

  // Added BuildContext here
  Future<void> _updateStatus(
      BuildContext context, String applicationId, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('applications')
        .doc(applicationId)
        .update({
      'status': newStatus,
    });

    // Show pop-up message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Status updated to ${newStatus.toUpperCase()}"),
          backgroundColor: _getStatusColor(newStatus),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Applicants for: $opportunityTitle"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('applications')
            .where('opportunityId', isEqualTo: opportunityId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No applications yet."));
          }

          final applications = snapshot.data!.docs;
          applications.sort((a, b) {
            final aTime = (a['createdAt'] as Timestamp?) ?? Timestamp.now();
            final bTime = (b['createdAt'] as Timestamp?) ?? Timestamp.now();
            return bTime.compareTo(aTime);
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
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(child: Icon(Icons.person)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Applicant ID: ${data['applicantId'].toString().substring(0, 8)}...",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                if (timestamp != null)
                                  Text(
                                    "Applied ${DateFormat('MMM dd, hh:mm a').format(timestamp.toDate())}",
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                          // STATUS BADGE (This changes color instantly)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: _getStatusColor(status)),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                  color: _getStatusColor(status),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 24),

                      const Text("Cover Letter:",
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(data['coverLetter'] ?? 'No cover letter provided.',
                          style: const TextStyle(height: 1.5)),

                      const SizedBox(height: 16),

                      // ACTION BUTTONS (Added context, to every single one)
                      Wrap(
                        spacing: 8,
                        children: [
                          if (status == 'pending')
                            ActionChip(
                              avatar: const Icon(Icons.visibility, size: 18),
                              label: const Text("Mark Reviewed"),
                              onPressed: () =>
                                  _updateStatus(context, app.id, 'reviewed'),
                            ),
                          if (status == 'pending' || status == 'reviewed')
                            ActionChip(
                              avatar: const Icon(Icons.star_outline,
                                  size: 18, color: Colors.blue),
                              label: const Text("Shortlist",
                                  style: TextStyle(color: Colors.blue)),
                              onPressed: () =>
                                  _updateStatus(context, app.id, 'shortlisted'),
                            ),
                          if (status != 'accepted' && status != 'rejected')
                            ActionChip(
                              avatar: const Icon(Icons.check_circle_outline,
                                  size: 18, color: Colors.green),
                              label: const Text("Accept",
                                  style: TextStyle(color: Colors.green)),
                              onPressed: () =>
                                  _updateStatus(context, app.id, 'accepted'),
                            ),
                          if (status != 'rejected' && status != 'accepted')
                            ActionChip(
                              avatar: const Icon(Icons.cancel_outlined,
                                  size: 18, color: Colors.red),
                              label: const Text("Reject",
                                  style: TextStyle(color: Colors.red)),
                              onPressed: () =>
                                  _updateStatus(context, app.id, 'rejected'),
                            ),
                        ],
                      )
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
}
