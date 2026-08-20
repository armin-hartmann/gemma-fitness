import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../view_models/exercise_admin_view_model.dart';

class ApiKeyDialog extends StatefulWidget {
  const ApiKeyDialog({
    super.key,
    required this.viewModel,
  });

  final ExerciseAdminViewModel viewModel;

  static Future<void> show(
    BuildContext context, {
    required ExerciseAdminViewModel viewModel,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => ApiKeyDialog(viewModel: viewModel),
    );
  }

  @override
  State<ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends State<ApiKeyDialog> {
  late TextEditingController _controller;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.viewModel.savedApiKey ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasKey = widget.viewModel.hasApiKey;

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.key_rounded, color: AppTheme.primary, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Gemini API Key Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppTheme.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: hasKey
                      ? AppTheme.accent.withAlpha(25)
                      : Colors.amber.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: hasKey
                        ? AppTheme.accent.withAlpha(80)
                        : Colors.amber.withAlpha(80),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasKey
                          ? Icons.check_circle_outline_rounded
                          : Icons.info_outline_rounded,
                      color: hasKey ? AppTheme.accent : Colors.amber,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        hasKey
                            ? 'Gemini API Key is configured and saved locally.'
                            : 'No API key set yet. Paste your key below to enable AI Ingestion.',
                        style: TextStyle(
                          color: hasKey ? AppTheme.accent : Colors.amber,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  labelText: 'Gemini API Key',
                  hintText: 'AIzaSy...',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () {
                      setState(() => _obscureText = !_obscureText);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '🔒 Safe Storage: Your key is stored exclusively in your browser\'s local storage (or local device). It is never sent to any server except directly to the Google Generative Language API.',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (hasKey)
                    TextButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await widget.viewModel.clearApiKey();
                        _controller.clear();
                        if (mounted) {
                          setState(() {});
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('API key removed from local storage.'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Colors.redAccent, size: 16),
                      label: const Text(
                        'Clear Key',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () async {
                          final text = _controller.text.trim();
                          if (text.isNotEmpty) {
                            final navigator = Navigator.of(context);
                            final messenger = ScaffoldMessenger.of(context);
                            await widget.viewModel.saveApiKey(text);
                            if (mounted) {
                              navigator.pop();
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('API key saved! You will not need to enter it again.'),
                                  backgroundColor: AppTheme.accent,
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Save to Device'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
