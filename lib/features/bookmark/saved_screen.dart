import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bookmark_cubit.dart';
import '../application/apply_screen.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Saved Opportunities")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("No saved opportunities."));
          }

          final bookmarkIds = List<String>.from(
              snapshot.data!['bookmarkedOpportunities'] ?? []);

          if (bookmarkIds.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No saved opportunities yet.",
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                  SizedBox(height: 8),
                  Text(
                      "Tap the bookmark icon on opportunities to save them here!",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                      textAlign: TextAlign.center),
                ],
              ),
            );
          }

          return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('opportunities')
                .where(FieldPath.documentId, whereIn: bookmarkIds)
                .get(),
            builder: (context, oppSnapshot) {
              if (oppSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!oppSnapshot.hasData || oppSnapshot.data!.docs.isEmpty) {
                return const Center(
                    child: Text("Saved opportunities not found."));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: oppSnapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final data = oppSnapshot.data!.docs[index].data()
                      as Map<String, dynamic>;
                  final oppId = oppSnapshot.data!.docs[index].id;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Row: Title and Bookmark Icon (Separated so taps don't conflict)
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  // FIXED: Only the text navigates, not the whole row
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ApplyScreen(
                                          opportunityId: oppId,
                                          opportunityTitle:
                                              data['title'] ?? 'Untitled',
                                          startupName:
                                              data['startupName'] ?? 'Startup',
                                        ),
                                      ),
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(data['title'] ?? 'Untitled',
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text(
                                          "${data['startupName'] ?? 'Startup'} • ${data['category'] ?? ''}",
                                          style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ),
                              BlocBuilder<BookmarkCubit, Set<String>>(
                                builder: (context, bookmarks) {
                                  final isSaved = bookmarks.contains(oppId);
                                  return IconButton(
                                    icon: Icon(
                                      isSaved
                                          ? Icons.bookmark
                                          : Icons.bookmark_border,
                                      color: isSaved
                                          ? const Color(0xFF1B5E20)
                                          : Colors.grey,
                                    ),
                                    onPressed: () => context
                                        .read<BookmarkCubit>()
                                        .toggleBookmark(oppId),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Description Preview
                          Text(data['description'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.black54)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
