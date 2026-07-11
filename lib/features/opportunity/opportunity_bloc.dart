import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- EVENTS ---
abstract class OpportunityEvent {}

class AddOpportunity extends OpportunityEvent {
  final Map<String, dynamic> data;
  AddOpportunity(this.data);
}

class SearchOpportunities extends OpportunityEvent {
  final String query;
  SearchOpportunities(this.query);
}

class FilterByCategory extends OpportunityEvent {
  final String category;
  FilterByCategory(this.category);
}

class ClearFilters extends OpportunityEvent {}

class UpdateOpportunities extends OpportunityEvent {
  final List<QueryDocumentSnapshot> opportunities;
  UpdateOpportunities(this.opportunities);
}

// --- STATES ---
abstract class OpportunityState {}

class OpportunityInitial extends OpportunityState {}

class OpportunityLoaded extends OpportunityState {
  final List<QueryDocumentSnapshot> allOpportunities;
  final List<QueryDocumentSnapshot> displayedOpportunities;
  final String activeSearch;
  final String activeCategory;

  OpportunityLoaded({
    required this.allOpportunities,
    required this.displayedOpportunities,
    this.activeSearch = '',
    this.activeCategory = 'All',
  });
}

// --- BLOC ---
class OpportunityBloc extends Bloc<OpportunityEvent, OpportunityState> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  OpportunityBloc() : super(OpportunityInitial()) {
    on<AddOpportunity>(_onAdd);
    on<SearchOpportunities>(_onSearch);
    on<FilterByCategory>(_onFilter);
    on<ClearFilters>(_onClear);
    on<UpdateOpportunities>(_onUpdate);
  }

  Stream<List<QueryDocumentSnapshot>> get opportunitiesStream {
    return _db
        .collection('opportunities')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs);
  }

  Future<void> _onUpdate(
      UpdateOpportunities e, Emitter<OpportunityState> emit) async {
    if (state is OpportunityLoaded) {
      final currentState = state as OpportunityLoaded;
      final filtered = _applyFilters(e.opportunities, currentState.activeSearch,
          currentState.activeCategory);
      emit(OpportunityLoaded(
        allOpportunities: e.opportunities,
        displayedOpportunities: filtered,
        activeSearch: currentState.activeSearch,
        activeCategory: currentState.activeCategory,
      ));
    } else {
      emit(OpportunityLoaded(
          allOpportunities: e.opportunities,
          displayedOpportunities: e.opportunities));
    }
  }

  Future<void> _onAdd(AddOpportunity e, Emitter<OpportunityState> emit) async {
    try {
      await _db.collection('opportunities').add({
        ...e.data,
        'applicantCount': 0,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  void _onSearch(SearchOpportunities e, Emitter<OpportunityState> emit) {
    if (state is! OpportunityLoaded) return;
    final currentState = state as OpportunityLoaded;
    final filtered = _applyFilters(
        currentState.allOpportunities, e.query, currentState.activeCategory);

    emit(OpportunityLoaded(
      allOpportunities: currentState.allOpportunities,
      displayedOpportunities: filtered,
      activeSearch: e.query,
      activeCategory: currentState.activeCategory,
    ));
  }

  void _onFilter(FilterByCategory e, Emitter<OpportunityState> emit) {
    if (state is! OpportunityLoaded) return;
    final currentState = state as OpportunityLoaded;
    final filtered = _applyFilters(
        currentState.allOpportunities, currentState.activeSearch, e.category);

    emit(OpportunityLoaded(
      allOpportunities: currentState.allOpportunities,
      displayedOpportunities: filtered,
      activeSearch: currentState.activeSearch,
      activeCategory: e.category,
    ));
  }

  void _onClear(ClearFilters e, Emitter<OpportunityState> emit) {
    if (state is! OpportunityLoaded) return;
    final currentState = state as OpportunityLoaded;
    emit(OpportunityLoaded(
      allOpportunities: currentState.allOpportunities,
      displayedOpportunities: currentState.allOpportunities,
      activeSearch: '',
      activeCategory: 'All',
    ));
  }

  List<QueryDocumentSnapshot> _applyFilters(
      List<QueryDocumentSnapshot> list, String search, String category) {
    var filtered = list;

    if (category != 'All') {
      filtered = filtered.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['category'] == category;
      }).toList();
    }

    if (search.isNotEmpty) {
      final lowerSearch = search.toLowerCase();
      filtered = filtered.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final title = (data['title'] ?? '').toLowerCase();
        final desc = (data['description'] ?? '').toLowerCase();
        return title.contains(lowerSearch) || desc.contains(lowerSearch);
      }).toList();
    }

    return filtered;
  }
}
