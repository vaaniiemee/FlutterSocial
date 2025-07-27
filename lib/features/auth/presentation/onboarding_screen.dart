import 'package:flutter/material.dart';
import '../../auth/domain/onboarding_questions.dart';
import 'widgets/onboarding_card.dart';

class OnboardingScreen extends StatefulWidget {
  final void Function(Map<String, String> answers) onFinish;
  const OnboardingScreen({super.key, required this.onFinish});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int step = 0;
  final Map<String, String> answers = {};

  void nextStep() {
    if (step < 2) {
      setState(() => step++);
    } else {
      widget.onFinish(answers);
    }
  }

  void select(String key, String value) {
    setState(() {
      answers[key] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      _StepData(
        title: 'Your country',
        key: 'country',
        options: OnboardingQuestions.countries,
        icon: Icons.flag,
      ),
      _StepData(
        title: 'Destination country',
        key: 'destination',
        options: OnboardingQuestions.destinations,
        icon: Icons.flight_takeoff,
      ),
      _StepData(
        title: 'Purpose',
        key: 'purpose',
        options: OnboardingQuestions.purposes,
        icon: Icons.star,
      ),
    ];
    final current = steps[step];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Onboarding'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: LinearProgressIndicator(
              value: (step + 1) / steps.length,
              color: Colors.deepPurple,
              backgroundColor: Colors.deepPurple.shade100,
            ),
          ),
          Text(
            current.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: current.options.map((option) {
                final selected = answers[current.key] == option;
                return OnboardingCard(
                  text: option,
                  selected: selected,
                  icon: current.icon,
                  onTap: () => select(current.key, option),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: answers[current.key] != null ? nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(step < 2 ? 'Next' : 'Finish'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepData {
  final String title;
  final String key;
  final List<String> options;
  final IconData icon;
  _StepData({required this.title, required this.key, required this.options, required this.icon});
} 