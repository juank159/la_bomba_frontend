import 'package:flutter/material.dart';
import '../../config/app_config.dart';

/// Custom loading widget for the application
class LoadingWidget extends StatelessWidget {
  final String? message;
  final Color? color;
  final double? size;

  const LoadingWidget({
    super.key, 
    this.message,
    this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size ?? 32,
            height: size ?? 32,
            child: CircularProgressIndicator(
              color: color ?? AppConfig.primaryColor,
              strokeWidth: 3,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppConfig.paddingMedium),
            Text(
              message!,
              style: TextStyle(
                color: color ?? Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: AppConfig.bodyFontSize,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Custom loading widget that matches the app theme
class CustomLoadingWidget extends StatelessWidget {
  final Color? color;
  final double? size;

  const CustomLoadingWidget({
    super.key,
    this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size ?? 24,
      height: size ?? 24,
      child: CircularProgressIndicator(
        color: color ?? AppConfig.primaryColor,
        strokeWidth: 2,
      ),
    );
  }
}

/// Loading overlay that can be shown over other widgets
class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: LoadingWidget(message: message),
          ),
      ],
    );
  }
}