import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookmarkCubit extends Cubit<Set<String>> {
  final FirebaseFirestore _db;
  final String _userId;

  BookmarkCubit(this._db, this._userId) : super({}) {
    _loadBookmarks();
  }

  // 1. Load initial bookmarks from Firestore
  void _loadBookmarks() async {
    try {
      final doc = await _db.collection('users').doc(_userId).get();
      final data = doc.data();
      if (data != null && data['bookmarkedOpportunities'] != null) {
        emit(Set<String>.from(data['bookmarkedOpportunities']));
      }
    } catch (_) {}
  }

  // 2. Toggle bookmark (Optimistic Update!)
  Future<void> toggleBookmark(String opportunityId) async {
    final isBookmarked = state.contains(opportunityId);

    // Update UI instantly (Optimistic)
    if (isBookmarked) {
      emit(Set.from(state)..remove(opportunityId));
    } else {
      emit(Set.from(state)..add(opportunityId));
    }

    try {
      // Update Firestore in the background
      await _db.collection('users').doc(_userId).update({
        'bookmarkedOpportunities': isBookmarked
            ? FieldValue.arrayRemove([opportunityId])
            : FieldValue.arrayUnion([opportunityId]),
      });
    } catch (_) {
      // If it fails, revert the UI (Pessimistic fallback)
      if (isBookmarked) {
        emit(Set.from(state)..add(opportunityId));
      } else {
        emit(Set.from(state)..remove(opportunityId));
      }
    }
  }

  bool isBookmarked(String opportunityId) => state.contains(opportunityId);
}
