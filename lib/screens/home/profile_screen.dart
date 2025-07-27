import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/auth_provider.dart';
import '../../state/user_provider.dart';
import 'post_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int followers = 0;
  int following = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final myUid = ref.read(authProvider).user?.uid;
    if (myUid == null) return;
    followers = await ref.read(userProvider.notifier).getFollowersCount(myUid);
    following = await ref.read(userProvider.notifier).getFollowingCount(myUid);
    setState(() { loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final myUid = ref.watch(authProvider).user?.uid;
    final profile = ref.watch(userProvider);
    if (profile == null || loading || myUid == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Header with avatar, settings, edit
          Stack(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 32, bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accent.withOpacity(0.07),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: AppTheme.background,
                      child: CircleAvatar(
                        radius: 48,
                        backgroundImage: profile.photoUrl != null ? NetworkImage(profile.photoUrl!) : null,
                        backgroundColor: AppTheme.card,
                        child: profile.photoUrl == null ? Icon(Icons.person, size: 48, color: AppTheme.textSecondary) : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(profile.nickname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 26, color: AppTheme.textPrimary)),
                    const SizedBox(height: 6),
                    Text(profile.email, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => _EditProfileDialog(profile: profile, userId: myUid, ref: ref),
                      ),
                      icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                      label: const Text('Edit Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accent.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.settings, size: 28, color: AppTheme.accent),
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
                  ),
                ),
              ),
            ],
          ),
          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatColumn(label: 'Posts', valueWidget: _PostsCount(userId: myUid)),
                _StatColumn(label: 'Followers', value: followers),
                _StatColumn(label: 'Following', value: following),
              ],
            ),
          ),
          // Info section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (profile.fromCountry != null)
                  Row(children: [Icon(Icons.flag, size: 18, color: AppTheme.accent), const SizedBox(width: 6), Text('From: ${profile.fromCountry}', style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary))]),
                if (profile.toCountry != null)
                  Row(children: [Icon(Icons.flight, size: 18, color: AppTheme.accent2), const SizedBox(width: 6), Text('To: ${profile.toCountry}', style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary))]),
                if (profile.purpose != null)
                  Row(children: [Icon(Icons.info_outline, size: 18, color: AppTheme.textSecondary), const SizedBox(width: 6), Text('Purpose: ${profile.purpose}', style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary))]),
              ],
            ),
          ),
          // Tabs
          const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.grid_on), text: 'Posts'),
              Tab(icon: Icon(Icons.info_outline), text: 'About'),
            ],
            labelColor: AppTheme.accent,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.accent,
          ),
          Expanded(
            child: TabBarView(
              children: [
                _UserPostsGrid(userId: myUid),
                _AboutTab(profile: profile),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final int? value;
  final Widget? valueWidget;
  const _StatColumn({required this.label, this.value, this.valueWidget});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        valueWidget ?? Text(value?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.accent)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
      ],
    );
  }
}

class _PostsCount extends StatelessWidget {
  final String userId;
  const _PostsCount({required this.userId});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('posts').where('userId', isEqualTo: userId).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Text('-', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.accent));
        return Text('${snap.data!.docs.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.accent));
      },
    );
  }
}

class _UserPostsGrid extends StatelessWidget {
  final String userId;
  const _UserPostsGrid({required this.userId});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .where('createdAt', isGreaterThan: Timestamp(0,0))
        .orderBy('createdAt', descending: true)
        .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.grid_off, size: 64, color: AppTheme.textSecondary),
                SizedBox(height: 16),
                Text('No posts yet', style: TextStyle(fontSize: 18, color: AppTheme.textSecondary)),
              ],
            ),
          );
        }
        final posts = snap.data!.docs;
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: posts.length,
          itemBuilder: (context, i) {
            final data = posts[i].data() as Map<String, dynamic>;
            return GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => PostDetailScreen(postId: posts[i].id)),
              ),
              child: data['imageUrl'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(data['imageUrl'], fit: BoxFit.cover),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        data['title'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
            );
          },
        );
      },
    );
  }
}

class _AboutTab extends StatelessWidget {
  final dynamic profile;
  const _AboutTab({required this.profile});
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      children: [
        ListTile(
          leading: const Icon(Icons.email, color: AppTheme.accent),
          title: const Text('Email', style: TextStyle(color: AppTheme.textPrimary)),
          subtitle: Text(profile.email, style: const TextStyle(color: AppTheme.textSecondary)),
        ),
        if (profile.fromCountry != null)
          ListTile(
            leading: const Icon(Icons.flag, color: AppTheme.accent),
            title: const Text('From', style: TextStyle(color: AppTheme.textPrimary)),
            subtitle: Text(profile.fromCountry, style: const TextStyle(color: AppTheme.textSecondary)),
          ),
        if (profile.toCountry != null)
          ListTile(
            leading: const Icon(Icons.flight, color: AppTheme.accent2),
            title: const Text('To', style: TextStyle(color: AppTheme.textPrimary)),
            subtitle: Text(profile.toCountry, style: const TextStyle(color: AppTheme.textSecondary)),
          ),
        if (profile.purpose != null)
          ListTile(
            leading: const Icon(Icons.info_outline, color: AppTheme.textSecondary),
            title: const Text('Purpose', style: TextStyle(color: AppTheme.textPrimary)),
            subtitle: Text(profile.purpose, style: const TextStyle(color: AppTheme.textSecondary)),
          ),
      ],
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final profile = ref.watch(userProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Profile'),
            onTap: () async {
              if (user == null || profile == null) return;
              await showDialog(
                context: context,
                builder: (_) => _EditProfileDialog(profile: profile, userId: user.uid, ref: ref),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete Account'),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete Account'),
                  content: const Text('Are you sure? This cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (confirmed == true && user != null) {
                await user.delete();
                Navigator.of(context).pushNamedAndRemoveUntil('/onboarding', (r) => false);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  final dynamic profile;
  final String userId;
  final WidgetRef ref;
  const _EditProfileDialog({required this.profile, required this.userId, required this.ref});
  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _nickname;
  String? _photoUrl;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nickname = widget.profile.nickname;
    _photoUrl = widget.profile.photoUrl;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() { _loading = true; _error = null; });
    try {
      await widget.ref.read(userProvider.notifier).updateProfile(widget.userId, nickname: _nickname, photoUrl: _photoUrl);
      Navigator.pop(context);
    } catch (e) {
      setState(() { _error = 'Failed to update profile'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Profile'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: _nickname,
              decoration: const InputDecoration(labelText: 'Nickname'),
              validator: (v) => v != null && v.length >= 3 ? null : 'Min 3 chars',
              onSaved: (v) => _nickname = v,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _loading ? null : _save,
          child: _loading ? const CircularProgressIndicator() : const Text('Save'),
        ),
      ],
    );
  }
} 