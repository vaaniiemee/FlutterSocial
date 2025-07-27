import 'package:flutter/material.dart';

class OnboardingCard extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const OnboardingCard({
    super.key,
    required this.text,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: selected ? Colors.deepPurple : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: selected ? Colors.deepPurple : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: ListTile(
        leading: icon != null
            ? Icon(icon, color: selected ? Colors.white : Colors.deepPurple)
            : null,
        title: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.white : Colors.deepPurple,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
} 