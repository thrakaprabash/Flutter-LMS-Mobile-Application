import 'package:flutter/material.dart';

export '../utils/ui_message.dart';

class AppInputField extends StatelessWidget {
  const AppInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.validator,
    this.hint,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final FormFieldValidator<String> validator;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    validator: validator,
    obscureText: obscureText,
    autocorrect: false,
    enableSuggestions: false,
    keyboardType: keyboardType,
    textInputAction: textInputAction,
    onFieldSubmitted: onSubmitted,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
    ),
  );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });
  final String label;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) =>
      FilledButton(onPressed: onPressed, child: Text(label));
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 6),
      Text(subtitle),
    ],
  );
}
