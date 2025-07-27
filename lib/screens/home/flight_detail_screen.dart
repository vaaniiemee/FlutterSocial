import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class FlightDetailScreen extends StatelessWidget {
  final String flightId;
  const FlightDetailScreen({super.key, required this.flightId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('flights').doc(flightId).get(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!.data() as Map<String, dynamic>;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  Text('${data['fromCountry'] ?? ''} → ${data['toCountry'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                  const Spacer(),
                  if (data['date'] != null && data['date'] is Timestamp)
                    Text(_formatDate((data['date'] as Timestamp).toDate()), style: const TextStyle(color: Colors.indigo, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 18),
              Text(data['description'] ?? '', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 18),
              Row(
                children: [
                  Icon(Icons.person, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(data['nickname'] ?? 'Unknown', style: const TextStyle(fontSize: 16)),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.email),
                label: const Text('Contact by Email'),
                onPressed: data['email'] != null && data['email'].toString().isNotEmpty
                    ? () => launchUrl(Uri.parse('mailto:${data['email']}'))
                    : null,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.chat),
                label: const Text('Write in Chat'),
                onPressed: () {
                  // TODO: реализовать переход в чат с этим пользователем
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat feature coming soon')));
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              ),
            ],
          );
        },
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.day}.${date.month}.${date.year}';
} 