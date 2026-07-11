import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'opportunity_bloc.dart';
import 'create_opportunity_screen.dart';
import '../application/apply_screen.dart';
import '../auth/auth_bloc.dart';
import '../application/received_applications_screen.dart';
import '../bookmark/bookmark_cubit.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  final List<String> _categories = [
    'All',
    'Software Dev',
    'Design',
    'Marketing',
    'Business Analysis',
    'Research'
  ];
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<OpportunityBloc>().add(SearchOpportunities(query));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Discover Opportunities"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: () =>
                context.read<AuthBloc>().add(AuthLogoutRequested()),
          )
        ],
      ),
      floatingActionButton: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final isVerifiedFounder = authState is AuthAuthenticated &&
              authState.role == 'founder' &&
              authState.isVerified;

          if (!isVerifiedFounder) return const SizedBox.shrink();

          return FloatingActionButton(
            backgroundColor: Theme.of(context).colorScheme.primary,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CreateOpportunityScreen()),
            ),
            child: const Icon(Icons.add, color: Colors.white),
          );
        },
      ),
      body: Column(
        children: [
          // 1. SEARCH BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: "Search by title or description...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<OpportunityBloc>().add(ClearFilters());
                  },
                ),
              ),
            ),
          ),

          // 2. CATEGORY FILTER CHIPS
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = cat == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedCategory = cat);
                      context
                          .read<OpportunityBloc>()
                          .add(FilterByCategory(cat));
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // 3. OPPORTUNITY LIST (Wrapped in Auth check to hide Apply button for founders)
          Expanded(
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                // Determine if the current user is a student
                final isStudent = authState is AuthAuthenticated &&
                    authState.role == 'student';

                return StreamBuilder(
                  stream: context.read<OpportunityBloc>().opportunitiesStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasData) {
                      context
                          .read<OpportunityBloc>()
                          .add(UpdateOpportunities(snapshot.data!));
                    }

                    return BlocBuilder<OpportunityBloc, OpportunityState>(
                      builder: (context, state) {
                        if (state is OpportunityInitial) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (state is! OpportunityLoaded ||
                            state.displayedOpportunities.isEmpty) {
                          return const Center(
                              child: Text("No opportunities found."));
                        }

                        final docs = state.displayedOpportunities;

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data =
                                docs[index].data() as Map<String, dynamic>;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade50,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            data['category'] ?? 'General',
                                            style: const TextStyle(
                                              color: Color(0xFF1B5E20),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),

                                        // --- BOOKMARK ICON ---
                                        BlocBuilder<BookmarkCubit, Set<String>>(
                                          builder: (context, bookmarks) {
                                            final isSaved = bookmarks
                                                .contains(docs[index].id);
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
                                                  .toggleBookmark(
                                                      docs[index].id),
                                            );
                                          },
                                        ),

                                        if (data['isPaid'] == true)
                                          Chip(
                                            label: const Text("Paid",
                                                style: TextStyle(fontSize: 12)),
                                            backgroundColor:
                                                Colors.amber.shade100,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      data['title'] ?? 'Untitled',
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      data['description'] ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 12),

                                    // --- APPLY BUTTON: ONLY VISIBLE TO STUDENTS ---
                                    if (isStudent)
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: ElevatedButton.icon(
                                          icon:
                                              const Icon(Icons.send, size: 16),
                                          label: const Text("Apply Now"),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => ApplyScreen(
                                                  opportunityId: docs[index].id,
                                                  opportunityTitle:
                                                      data['title'] ??
                                                          'Untitled',
                                                  startupName:
                                                      data['startupName'] ??
                                                          'Startup',
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),

                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time,
                                            size: 16, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          "${data['hoursPerWeek']}h/week",
                                          style: const TextStyle(
                                              color: Colors.grey, fontSize: 12),
                                        ),
                                        const Spacer(),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    ReceivedApplicationsScreen(
                                                  opportunityId: docs[index].id,
                                                  opportunityTitle:
                                                      data['title'] ??
                                                          'Untitled',
                                                ),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                  color:
                                                      const Color(0xFF1B5E20)),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.people_outline,
                                                    size: 16,
                                                    color: Color(0xFF1B5E20)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  "${data['applicantCount'] ?? 0} applicants",
                                                  style: const TextStyle(
                                                    color: Color(0xFF1B5E20),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
