import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _email, _password, _nickname;
  String? _photoUrl;
  bool _loading = false;
  String? _error;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() { _loading = true; _error = null; });
    final isUnique = await ref.read(authProvider.notifier).checkNicknameUnique(_nickname!);
    if (!isUnique) {
      setState(() { _error = 'Nickname already taken'; _loading = false; });
      return;
    }
    final result = await ref.read(authProvider.notifier).register(
      email: _email!,
      password: _password!,
      nickname: _nickname!,
      photoUrl: _photoUrl,
    );
    if (result != null) {
      Navigator.of(context).pushReplacementNamed('/onboarding');
    } else {
      setState(() { _error = 'Registration failed'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v != null && v.contains('@') ? null : 'Enter valid email',
                onSaved: (v) => _email = v,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) => v != null && v.length >= 6 ? null : 'Min 6 chars',
                onSaved: (v) => _password = v,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nickname'),
                validator: (v) => v != null && v.length >= 3 ? null : 'Min 3 chars',
                onSaved: (v) => _nickname = v,
              ),
              // TODO: Add photo picker widget here
              const SizedBox(height: 24),
              if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loading ? null : _register,
                child: _loading ? const CircularProgressIndicator() : const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 