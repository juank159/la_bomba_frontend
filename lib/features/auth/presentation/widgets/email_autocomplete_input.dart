import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/app_config.dart';
import '../../../../app/core/services/preferences_service.dart';
import '../../../../app/core/di/service_locator.dart';

/// Email input with autocomplete dropdown for previously used emails
class EmailAutocompleteInput extends StatefulWidget {
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const EmailAutocompleteInput({
    super.key,
    required this.controller,
    this.errorText,
    this.onChanged,
  });

  @override
  State<EmailAutocompleteInput> createState() => _EmailAutocompleteInputState();
}

class _EmailAutocompleteInputState extends State<EmailAutocompleteInput> {
  final _focusNode = FocusNode();
  final _overlayPortalController = OverlayPortalController();
  final _layerLink = LayerLink();
  final _preferencesService = getIt<PreferencesService>();

  List<String> _savedEmails = [];
  List<String> _filteredEmails = [];
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    _loadSavedEmails();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _loadSavedEmails() {
    setState(() {
      _savedEmails = _preferencesService.getSavedEmails();
      _filteredEmails = _savedEmails;
    });
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _updateFilteredEmails();
      if (_filteredEmails.isNotEmpty) {
        setState(() => _showDropdown = true);
        _overlayPortalController.show();
      }
    } else {
      // Delay hiding to allow tap on dropdown items
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() => _showDropdown = false);
          _overlayPortalController.hide();
        }
      });
    }
  }

  void _onTextChanged() {
    _updateFilteredEmails();
    if (widget.onChanged != null) {
      widget.onChanged!(widget.controller.text);
    }
  }

  void _updateFilteredEmails() {
    final query = widget.controller.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredEmails = _savedEmails;
      } else {
        _filteredEmails = _savedEmails
            .where((email) => email.toLowerCase().contains(query))
            .toList();
      }

      if (_filteredEmails.isNotEmpty && _focusNode.hasFocus) {
        if (!_showDropdown) {
          _showDropdown = true;
          _overlayPortalController.show();
        }
      } else {
        if (_showDropdown) {
          _showDropdown = false;
          _overlayPortalController.hide();
        }
      }
    });
  }

  void _selectEmail(String email) {
    widget.controller.text = email;
    _focusNode.unfocus();
    setState(() {
      _showDropdown = false;
      _overlayPortalController.hide();
    });
    if (widget.onChanged != null) {
      widget.onChanged!(email);
    }
  }

  void _removeEmail(String email) async {
    await _preferencesService.removeEmail(email);
    _loadSavedEmails();
    _updateFilteredEmails();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CompositedTransformTarget(
      link: _layerLink,
      child: OverlayPortal(
        controller: _overlayPortalController,
        overlayChildBuilder: (context) {
          return CompositedTransformFollower(
            link: _layerLink,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(0, 8),
            child: Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                child: Container(
                  constraints: const BoxConstraints(
                    maxHeight: 240,
                    minWidth: 300,
                    maxWidth: 500,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shrinkWrap: true,
                    itemCount: _filteredEmails.length,
                    itemBuilder: (context, index) {
                      final email = _filteredEmails[index];
                      return _buildEmailItem(email, theme);
                    },
                  ),
                ),
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Correo electrónico',
              style: TextStyle(
                fontSize: AppConfig.bodyFontSize,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(
                hintText: 'Ingresa tu correo electrónico',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: theme.colorScheme.primary,
                ),
                suffixIcon: widget.controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {
                          widget.controller.clear();
                          if (widget.onChanged != null) {
                            widget.onChanged!('');
                          }
                        },
                      )
                    : _savedEmails.isNotEmpty
                        ? Icon(
                            Icons.arrow_drop_down,
                            color: theme.colorScheme.onSurfaceVariant,
                          )
                        : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                  borderSide: BorderSide(
                    color: theme.colorScheme.error,
                    width: 2,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                  borderSide: BorderSide(
                    color: theme.colorScheme.error,
                    width: 2,
                  ),
                ),
                errorText: widget.errorText,
                errorStyle: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: AppConfig.captionFontSize,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailItem(String email, ThemeData theme) {
    return InkWell(
      onTap: () => _selectEmail(email),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_outline,
                size: 20,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                email,
                style: TextStyle(
                  fontSize: AppConfig.bodyFontSize,
                  color: theme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.close,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              onPressed: () => _removeEmail(email),
              tooltip: 'Eliminar de la lista',
            ),
          ],
        ),
      ),
    );
  }
}
