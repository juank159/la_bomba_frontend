import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/config/app_config.dart';

/// Widget for 6-digit code input with auto-focus and validation
class CodeInputField extends StatefulWidget {
  final List<TextEditingController> controllers;
  final String? errorText;
  final VoidCallback? onComplete;
  final VoidCallback? onChanged;

  const CodeInputField({
    super.key,
    required this.controllers,
    this.errorText,
    this.onComplete,
    this.onChanged,
  });

  @override
  State<CodeInputField> createState() => _CodeInputFieldState();
}

class _CodeInputFieldState extends State<CodeInputField> {
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            6,
            (index) => _buildCodeBox(
              context,
              index,
              colorScheme,
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: AppConfig.paddingSmall),
          Text(
            widget.errorText!,
            style: TextStyle(
              color: AppConfig.errorColor,
              fontSize: AppConfig.captionFontSize,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCodeBox(BuildContext context, int index, ColorScheme colorScheme) {
    final controller = widget.controllers[index];
    final focusNode = _focusNodes[index];

    return SizedBox(
      width: 50,
      height: 60,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          counterText: '',
          contentPadding: const EdgeInsets.all(AppConfig.paddingSmall),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConfig.borderRadius),
            borderSide: BorderSide(color: colorScheme.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConfig.borderRadius),
            borderSide: BorderSide(color: colorScheme.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConfig.borderRadius),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConfig.borderRadius),
            borderSide: const BorderSide(color: AppConfig.errorColor, width: 2),
          ),
          filled: true,
          fillColor: colorScheme.surface,
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            // Move to next field
            if (index < 5) {
              _focusNodes[index + 1].requestFocus();
            } else {
              // Last digit entered, unfocus and trigger complete
              focusNode.unfocus();
              _checkComplete();
            }
          }
          widget.onChanged?.call();
        },
        onTap: () {
          // Clear the field when tapped
          if (controller.text.isNotEmpty) {
            controller.clear();
            widget.onChanged?.call();
          }
        },
      ),
    );
  }

  void _checkComplete() {
    final code = widget.controllers.map((c) => c.text).join();
    if (code.length == 6) {
      widget.onComplete?.call();
    }
  }
}
