import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/auth_provider.dart';
import '../../state/user_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  final List<String> _countries = [
    'USA', 'Germany', 'France', 'Italy', 'Spain', 'UK', 'Turkey', 'Russia', 'China', 'Japan', 'South Korea', 'Brazil', 'India', 'Australia', 'Canada', 'Other',
  ];
  final List<String> _purposes = [
    'Travel', 'Study', 'Work', 'Move', 'Visit family', 'Other',
  ];
  String? _fromCountry;
  String? _toCountry;
  String? _purpose;

  void _nextStep() {
    setState(() {
      if (_step < 2) {
        _step++;
      } else {
        _saveOnboarding();
      }
    });
  }

  void _saveOnboarding() async {
    final user = ref.read(authProvider).user;
    if (user != null) {
      await ref.read(userProvider.notifier).saveOnboarding(
        user.uid,
        _fromCountry!,
        _toCountry!,
        _purpose!,
      );
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildCardList('Your country', _countries, _fromCountry, (val) => setState(() => _fromCountry = val));
      case 1:
        return _buildCardList('Destination country', _countries, _toCountry, (val) => setState(() => _toCountry = val));
      case 2:
        return _buildCardList('Purpose', _purposes, _purpose, (val) => setState(() => _purpose = val));
      default:
        return Container();
    }
  }

  Widget _buildCardList(String title, List<String> options, String? selected, Function(String) onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 2.8,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: options.map((option) {
              final isSelected = selected == option;
              return GestureDetector(
                onTap: () => onSelect(option),
                child: Card(
                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white,
                  child: Center(
                    child: Text(option, style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    )),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Onboarding')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            LinearProgressIndicator(value: (_step + 1) / 3),
            const SizedBox(height: 24),
            Expanded(child: _buildStep()),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: (_step == 0 && _fromCountry == null) ||
                        (_step == 1 && _toCountry == null) ||
                        (_step == 2 && _purpose == null)
                  ? null
                  : _nextStep,
              child: Text(_step < 2 ? 'Next' : 'Finish'),
            ),
          ],
        ),
      ),
    );
  }
} 