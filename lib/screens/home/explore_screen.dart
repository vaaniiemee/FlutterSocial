import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import 'post_detail_screen.dart';
import 'flight_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with SingleTickerProviderStateMixin {
  String _search = '';
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search posts or users...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          const SizedBox(height: 10),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Posts'),
              Tab(text: 'Users'),
            ],
            labelColor: AppTheme.accent,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.accent,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _PostsFeed(search: _search),
                _UserSearchList(search: _search),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _FlightsPreview(),
        ],
      ),
    );
  }
}

class _PostsFeed extends StatelessWidget {
  final String search;
  const _PostsFeed({required this.search});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('posts').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No posts yet', style: TextStyle(color: AppTheme.textSecondary)));
        }
        final posts = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final text = (data['title'] ?? '') + ' ' + (data['text'] ?? '');
          return search.isEmpty || text.toLowerCase().contains(search.toLowerCase());
        }).toList();
        if (posts.isEmpty) {
          return const Center(child: Text('No results', style: TextStyle(color: AppTheme.textSecondary)));
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: posts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 18),
          itemBuilder: (context, i) {
            final post = posts[i].data() as Map<String, dynamic>;
            return _PostCard(
              post: post,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PostDetailScreen(postId: posts[i].id),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback onTap;
  const _PostCard({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: AppTheme.card,
        child: Padding(
          padding: const EdgeInsets.all(0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (post['imageUrl'] != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(
                    post['imageUrl'],
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 180,
                      color: AppTheme.background,
                      child: const Icon(Icons.broken_image, size: 48, color: AppTheme.textSecondary),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (post['userPhoto'] != null)
                          CircleAvatar(
                            backgroundImage: NetworkImage(post['userPhoto']),
                            radius: 20,
                          )
                        else
                          const CircleAvatar(radius: 20, child: Icon(Icons.person)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            post['nickname'] ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            post['category'] ?? '',
                            style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      post['title'] ?? '',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      post['text'] ?? '',
                      style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.favorite, color: AppTheme.accent, size: 20),
                        const SizedBox(width: 4),
                        Text('${post['likes'] ?? 0}', style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        const Icon(Icons.access_time, size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          post['createdAt'] != null && post['createdAt'] is Timestamp
                            ? _formatTime((post['createdAt'] as Timestamp).toDate())
                            : '',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserSearchList extends StatelessWidget {
  final String search;
  const _UserSearchList({required this.search});
  @override
  Widget build(BuildContext context) {
    if (search.isEmpty) {
      return const Center(child: Text('Enter a search query to find users', style: TextStyle(color: AppTheme.textSecondary)));
    }
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .where('nickname', isGreaterThanOrEqualTo: search)
          .where('nickname', isLessThanOrEqualTo: '${search}\uf8ff')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No users found', style: TextStyle(color: AppTheme.textSecondary)));
        }
        final users = snapshot.data!.docs;
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, i) {
            final user = users[i].data() as Map<String, dynamic>;
            return Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: user['photoUrl'] != null
                    ? CircleAvatar(backgroundImage: NetworkImage(user['photoUrl']))
                    : const CircleAvatar(child: Icon(Icons.person)),
                title: Text(user['nickname'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(user['email'] ?? '', style: const TextStyle(color: AppTheme.textSecondary)),
              ),
            );
          },
        );
      },
    );
  }
}

class _FlightsPreview extends StatelessWidget {
  const _FlightsPreview();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                const Text('Flights', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.accent)),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const _AllFlightsScreen()),
                    );
                  },
                  child: const Text('See all', style: TextStyle(color: AppTheme.accent)),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('flights').orderBy('date', descending: false).limit(10).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No flights', style: TextStyle(color: AppTheme.textSecondary)));
                }
                final flights = snapshot.data!.docs;
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: flights.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, i) {
                    final f = flights[i].data() as Map<String, dynamic>;
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => FlightDetailScreen(flightId: flights[i].id),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: AppTheme.card,
                        child: Container(
                          width: 180,
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.flight_takeoff, color: AppTheme.accent, size: 22),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${f['fromCountry'] ?? ''} → ${f['toCountry'] ?? ''}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                f['description'] ?? '',
                                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 15, color: AppTheme.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    f['date'] != null && f['date'] is Timestamp
                                        ? _formatDate((f['date'] as Timestamp).toDate())
                                        : '',
                                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
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

class _AllFlightsScreen extends StatelessWidget {
  const _AllFlightsScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Flights')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('flights').orderBy('date', descending: false).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No flights', style: TextStyle(color: AppTheme.textSecondary)));
          }
          final flights = snapshot.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: flights.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, i) {
              final f = flights[i].data() as Map<String, dynamic>;
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: AppTheme.card,
                child: ListTile(
                  leading: const Icon(Icons.flight_takeoff, color: AppTheme.accent),
                  title: Text('${f['fromCountry'] ?? ''} → ${f['toCountry'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(f['description'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary)),
                  trailing: f['date'] != null && f['date'] is Timestamp
                      ? Text(_formatDate((f['date'] as Timestamp).toDate()), style: const TextStyle(color: AppTheme.textSecondary))
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

String _formatTime(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${date.day}.${date.month}.${date.year}';
}

String _formatDate(DateTime date) {
  return '${date.day}.${date.month}.${date.year}';
} 