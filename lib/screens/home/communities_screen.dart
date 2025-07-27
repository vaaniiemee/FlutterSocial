import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'post_detail_screen.dart';
import 'chat_screen.dart';
import '../../theme/app_theme.dart';
import '../../services/chat_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/auth_provider.dart';

class CommunitiesScreen extends StatelessWidget {
  const CommunitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Communities', style: Theme.of(context).textTheme.headlineSmall),
        ),
        const Expanded(
          child: Center(child: Text('Communities Content')),
        ),
      ],
    );
  }
}

class _ForumTab extends StatefulWidget {
  final String category;
  final ValueChanged<String> onCategoryChanged;
  final String search;
  final ValueChanged<String> onSearchChanged;
  final List<String> categories;
  final TextEditingController searchController;
  const _ForumTab({
    required this.category,
    required this.onCategoryChanged,
    required this.search,
    required this.onSearchChanged,
    required this.categories,
    required this.searchController,
  });
  @override
  State<_ForumTab> createState() => _ForumTabState();
}

class _ForumTabState extends State<_ForumTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: widget.onSearchChanged,
                ),
              ),
              const SizedBox(width: 12),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: widget.category,
                  items: widget.categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => widget.onCategoryChanged(val ?? 'All'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Posts/Questions'),
            Tab(text: 'People'),
          ],
          labelColor: AppTheme.accent,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.accent,
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _ForumPostsList(
                category: widget.category,
                search: widget.search,
              ),
              _UserSearchList(
                search: widget.search,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ForumPostsList extends StatelessWidget {
  final String category;
  final String search;
  const _ForumPostsList({required this.category, required this.search});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getForumStream(category),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _EmptyState(text: 'No questions yet');
        }
        final questions = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final text = (data['title'] ?? '') + ' ' + (data['text'] ?? '');
          return search.isEmpty || text.toLowerCase().contains(search.toLowerCase());
        }).toList();
        if (questions.isEmpty) {
          return _EmptyState(text: 'No results');
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: questions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 18),
          itemBuilder: (context, i) {
            final q = questions[i].data() as Map<String, dynamic>;
            return _ForumCard(
              question: q,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PostDetailScreen(postId: questions[i].id),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getForumStream(String category) {
    final col = FirebaseFirestore.instance.collection('posts');
    Query query = col.where('type', isEqualTo: 'Question').orderBy('createdAt', descending: true);
    if (category != 'All') {
      query = query.where('category', isEqualTo: category);
    }
    return query.snapshots();
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
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final users = snap.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final nickname = (data['nickname'] ?? '').toLowerCase();
          final email = (data['email'] ?? '').toLowerCase();
          return nickname.contains(search.toLowerCase()) || email.contains(search.toLowerCase());
        }).toList();
        if (users.isEmpty) {
          return _EmptyState(text: 'No users found');
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 18),
          itemBuilder: (context, i) {
            final data = users[i].data() as Map<String, dynamic>;
            return ListTile(
              leading: data['photoUrl'] != null
                  ? CircleAvatar(backgroundImage: NetworkImage(data['photoUrl']))
                  : const CircleAvatar(child: Icon(Icons.person)),
              title: Text(data['nickname'] ?? ''),
              subtitle: Text(data['email'] ?? ''),
            );
          },
        );
      },
    );
  }
}

class _ForumCard extends StatelessWidget {
  final Map<String, dynamic> question;
  final VoidCallback onTap;
  const _ForumCard({required this.question, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (question['userPhoto'] != null)
                      CircleAvatar(
                        backgroundImage: NetworkImage(question['userPhoto']),
                        radius: 24,
                      )
                    else
                      const CircleAvatar(radius: 24, child: Icon(Icons.person)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        question['nickname'] ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        question['category'] ?? '',
                        style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  question['title'] ?? '',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  question['text'] ?? '',
                  style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 18, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      question['createdAt'] != null && question['createdAt'] is Timestamp
                        ? _formatTime((question['createdAt'] as Timestamp).toDate())
                        : '',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatsTab extends ConsumerWidget {
  const _ChatsTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authProvider).user?.uid;
    if (userId == null) return const Center(child: CircularProgressIndicator());
    final chatService = ChatService();
    return StreamBuilder<QuerySnapshot>(
      stream: chatService.getUserChats(userId),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return _EmptyState(text: 'No chats yet');
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: snap.data!.docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 18),
          itemBuilder: (context, i) {
            final data = snap.data!.docs[i].data() as Map<String, dynamic>;
            final members = List<String>.from(data['members']);
            final otherId = members.firstWhere((id) => id != userId, orElse: () => '');
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(otherId).get(),
              builder: (context, userSnap) {
                final userData = (userSnap.data != null && userSnap.data!.data() != null)
                  ? userSnap.data!.data() as Map<String, dynamic>
                  : null;
                final nickname = userData?['nickname'] ?? 'User';
                final photoUrl = userData?['photoUrl'];
                return ListTile(
                  leading: photoUrl != null ? CircleAvatar(backgroundImage: NetworkImage(photoUrl)) : const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(nickname),
                  subtitle: Text(data['lastMessage'] ?? ''),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: () {
                    if (userSnap.data != null && userSnap.data!.data() != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(chatId: snap.data!.docs[i].id, otherUserNickname: nickname),
                        ),
                      );
                    }
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState({required this.text});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: AppTheme.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 18),
          Text(text, style: const TextStyle(fontSize: 22, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

String _formatTime(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  return '${date.day}.${date.month}.${date.year}';
} 