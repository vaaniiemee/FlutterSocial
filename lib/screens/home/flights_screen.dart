import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_flight_screen.dart';
import 'flight_detail_screen.dart';
import '../../theme/app_theme.dart';

class FlightsScreen extends StatelessWidget {
  const FlightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Flights', style: Theme.of(context).textTheme.headlineSmall),
        ),
        const Expanded(
          child: Center(child: Text('Flights Content')),
        ),
      ],
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.day}.${date.month}.${date.year}';
}

class _FlightCard extends StatelessWidget {
  final Map<String, dynamic> flight;
  final VoidCallback onTap;
  const _FlightCard({required this.flight, required this.onTap});

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
                    Icon(Icons.flight_takeoff, color: AppTheme.accent, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${flight['fromCountry'] ?? ''} → ${flight['toCountry'] ?? ''}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (flight['date'] != null && flight['date'] is Timestamp)
                      Text(_formatDate((flight['date'] as Timestamp).toDate()), style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  flight['description'] ?? '',
                  style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.person, size: 20, color: AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Text(flight['nickname'] ?? 'Unknown', style: const TextStyle(fontSize: 15)),
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