import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/auth_provider.dart';
import '../../state/user_provider.dart';
import '../../theme/app_theme.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'Post';
  String? _title;
  String? _text;
  String? _category;
  File? _image;
  bool _loading = false;
  String? _error;

  final List<String> _types = ['Post', 'Question'];
  final List<String> _categories = [
    'General', 'Travel', 'Study', 'Work', 'Help', 'Other',
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
      });
    }
  }

  Future<String?> _uploadImage(File image, String userId) async {
    final ref = FirebaseStorage.instance.ref().child('posts/${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg');
    final uploadTask = await ref.putFile(image);
    return await uploadTask.ref.getDownloadURL();
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
      String? imageUrl;
      if (_image != null) {
        imageUrl = await _uploadImage(_image!, user.uid);
      }
      await FirebaseFirestore.instance.collection('posts').add({
        'type': _type,
        'title': _title,
        'text': _text,
        'category': _category,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': user.uid,
        'nickname': userProfile.nickname,
        'userPhoto': userProfile.photoUrl,
      });
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() { _error = 'Failed to create post'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Post/Question')),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: _types.map((t) => Expanded(
                          child: RadioListTile<String>(
                            title: Text(t),
                            value: t,
                            groupValue: _type,
                            onChanged: (val) => setState(() => _type = val!),
                          ),
                        )).toList(),
                      ),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Title'),
                        validator: (v) => v != null && v.length >= 3 ? null : 'Min 3 chars',
                        onSaved: (v) => _title = v,
                      ),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Text'),
                        maxLines: 5,
                        validator: (v) => v != null && v.length >= 10 ? null : 'Min 10 chars',
                        onSaved: (v) => _text = v,
                      ),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) => setState(() => _category = val),
                        validator: (v) => v == null ? 'Select category' : null,
                      ),
                      const SizedBox(height: 16),
                      if (_image != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_image!, height: 120),
                        ),
                      TextButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image),
                        label: const Text('Add Image'),
                      ),
                      const SizedBox(height: 24),
                      if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                      ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent,
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
            ),
          ),
        ),
      ),
    );
  }
} 