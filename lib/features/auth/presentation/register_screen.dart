import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../state/auth_provider.dart';
import 'onboarding_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();
  String? _photoUrl;
  bool _loading = false;
  String? _nicknameError;

  Future<bool> checkNicknameUnique(String nickname) async {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('nickname', isEqualTo: nickname)
        .get();
    return query.docs.isEmpty;
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final nicknameUnique = await checkNicknameUnique(_nicknameController.text.trim());
    if (!nicknameUnique) {
      setState(() {
        _nicknameError = 'Nickname already taken';
        _loading = false;
      });
      return;
    }
    setState(() => _nicknameError = null);
    // После регистрации — онбординг
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => OnboardingScreen(
        onFinish: (answers) async {
          await ref.read(authProvider.notifier).register(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            nickname: _nicknameController.text.trim(),
            photoUrl: _photoUrl,
          );
          if (mounted) Navigator.of(context).pop();
        },
      ),
    ));
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () async {
                  // TODO: реализовать выбор фото (gallery/camera)
                },
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: Colors.deepPurple.shade100,
                  backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                  child: _photoUrl == null
                      ? const Icon(Icons.camera_alt, size: 40, color: Colors.deepPurple)
                      : null,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v != null && v.contains('@') ? null : 'Enter a valid email',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (v) => v != null && v.length >= 6 ? null : 'Min 6 characters',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nicknameController,
                decoration: InputDecoration(
                  labelText: 'Nickname',
                  prefixIcon: const Icon(Icons.person),
                  border: const OutlineInputBorder(),
                  errorText: _nicknameError,
                ),
                validator: (v) => v != null && v.length >= 3 ? null : 'Min 3 characters',
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _loading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Sign Up', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 