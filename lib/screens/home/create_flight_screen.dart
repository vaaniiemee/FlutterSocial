import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/auth_provider.dart';
import '../../state/user_provider.dart';

class CreateFlightScreen extends ConsumerStatefulWidget {
  const CreateFlightScreen({super.key});

  @override
  ConsumerState<CreateFlightScreen> createState() => _CreateFlightScreenState();
}

class _CreateFlightScreenState extends ConsumerState<CreateFlightScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _fromCountry;
  String? _toCountry;
  DateTime? _date;
  String? _description;
  bool _loading = false;
  String? _error;

  final List<String> _countries = [
    'USA', 'Germany', 'France', 'Italy', 'Spain', 'UK', 'Turkey', 'Russia', 'China', 'Japan', 'South Korea', 'Brazil', 'India', 'Australia', 'Canada', 'Other',
  ];

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() { _loading = true; _error = null; });
    try {
      final user = ref.read(authProvider).user;
      final userProfile = ref.read(userProvider);
      if (user == null || userProfile == null) {
        setState(() { _error = 'User not found'; _loading = false; });
        return;
      }
      await FirebaseFirestore.instance.collection('flights').add({
        'fromCountry': _fromCountry,
        'toCountry': _toCountry,
        'date': _date != null ? Timestamp.fromDate(_date!) : null,
        'description': _description,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': user.uid,
        'nickname': userProfile.nickname,
      });
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() { _error = 'Failed to create flight'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Flight Request')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'From Country'),
                items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _fromCountry = val),
                validator: (v) => v == null ? 'Select country' : null,
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'To Country'),
                items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _toCountry = val),
                validator: (v) => v == null ? 'Select country' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(_date == null ? 'Select Date' : '${_date!.day}.${_date!.month}.${_date!.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 4,
                validator: (v) => v != null && v.length >= 10 ? null : 'Min 10 chars',
                onSaved: (v) => _description = v,
              ),
              const SizedBox(height: 24),
              if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading ? const CircularProgressIndicator() : const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 