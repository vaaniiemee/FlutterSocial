import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  bool _liking = false;

  Future<void> _addLike(DocumentSnapshot post) async {
    if (_liking) return;
    setState(() => _liking = true);
    final ref = post.reference;
    await ref.update({'likes': (post['likes'] ?? 0) + 1});
    setState(() => _liking = false);
  }

  Future<void> _addComment(DocumentSnapshot post) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    await post.reference.collection('comments').add({
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      // TODO: добавить userId, nickname
    });
    _commentController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('posts').doc(widget.postId).get(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final post = snap.data!;
                  final data = post.data() as Map<String, dynamic>;
                  return Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (data['userPhoto'] != null)
                                CircleAvatar(backgroundImage: NetworkImage(data['userPhoto']), radius: 28)
                              else
                                const CircleAvatar(child: Icon(Icons.person), radius: 28),
                              const SizedBox(width: 16),
                              Expanded(child: Text(data['nickname'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20), overflow: TextOverflow.ellipsis)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.accent.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(data['category'] ?? '', style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(data['title'] ?? '', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 10),
                          if (data['imageUrl'] != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(data['imageUrl'], height: 220, width: double.infinity, fit: BoxFit.cover),
                            ),
                          if (data['imageUrl'] != null) const SizedBox(height: 10),
                          Text(data['text'] ?? '', style: const TextStyle(fontSize: 17, color: AppTheme.textSecondary), maxLines: 6, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 18, color: AppTheme.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                data['createdAt'] != null && data['createdAt'] is Timestamp
                                  ? _formatTime((data['createdAt'] as Timestamp).toDate())
                                  : '',
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.thumb_up, color: AppTheme.accent, size: 28),
                                onPressed: _liking ? null : () => _addLike(post),
                              ),
                              Text('${data['likes'] ?? 0}', style: const TextStyle(fontSize: 16, color: AppTheme.accent)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Comments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.accent)),
                      const SizedBox(height: 8),
                      _buildComments(FirebaseFirestore.instance.collection('posts').doc(widget.postId)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              decoration: const InputDecoration(hintText: 'Add a comment...'),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send, color: AppTheme.accent),
                            onPressed: () async {
                              final post = await FirebaseFirestore.instance.collection('posts').doc(widget.postId).get();
                              _addComment(post);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComments(DocumentReference postRef) {
    return StreamBuilder<QuerySnapshot>(
      stream: postRef.collection('comments').orderBy('createdAt', descending: false).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Text('No comments yet');
        }
        return Column(
          children: snap.data!.docs.map((doc) {
            final c = doc.data() as Map<String, dynamic>;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.comment, color: Colors.indigo),
              title: Text(c['text'] ?? ''),
              subtitle: c['createdAt'] != null && c['createdAt'] is Timestamp
                  ? Text(_formatTime((c['createdAt'] as Timestamp).toDate()), style: const TextStyle(fontSize: 12))
                  : null,
            );
          }).toList(),
        );
      },
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