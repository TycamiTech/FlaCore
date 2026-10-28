import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/api_constants.dart';

/// Shows the Minimalist Server API Configuration Dialog.
/// If [isDismissible] is false, the dialog cannot be dismissed by tapping outside or via back gesture
/// until a valid server connection is established and saved.
Future<bool?> showServerConfigDialog(
  BuildContext context, {
  bool isDismissible = true,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: isDismissible,
    builder: (dialogContext) => ServerConfigDialog(
      isDismissible: isDismissible,
    ),
  );
}

class ServerConfigDialog extends StatefulWidget {
  final bool isDismissible;

  const ServerConfigDialog({
    super.key,
    this.isDismissible = true,
  });

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  late final TextEditingController _controller;
  bool _isTesting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Leave blank on initial setup so only the hint placeholder is shown.
    // Only prefill if the user has already configured a custom server previously.
    final initialText =
        ApiConstants.isCustomConfigured ? ApiConstants.baseUrl : '';
    _controller = TextEditingController(text: initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      setState(() {
        _controller.text = data.text!.trim();
        _errorMessage = null;
      });
    }
  }

  Future<void> _connectAndSave() async {
    var inputUrl = _controller.text.trim();
    if (inputUrl.isEmpty) {
      setState(() {
        _errorMessage = 'Server URL cannot be empty.';
      });
      return;
    }

    // Auto-clean trailing slashes and default protocol
    while (inputUrl.endsWith('/')) {
      inputUrl = inputUrl.substring(0, inputUrl.length - 1);
    }
    if (!inputUrl.startsWith('http://') && !inputUrl.startsWith('https://')) {
      inputUrl = 'https://$inputUrl';
    }

    setState(() {
      _isTesting = true;
      _errorMessage = null;
    });

    try {
      final testUri = Uri.parse('$inputUrl/api/songs');
      final response = await http.get(
        testUri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 7));

      if (response.statusCode == 200 || response.statusCode == 202) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('server_api_url', inputUrl);
        ApiConstants.setBaseUrl(inputUrl);

        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() {
          _errorMessage = 'Server returned status ${response.statusCode}.';
        });
      }
    } on TimeoutException {
      setState(() {
        _errorMessage = 'Connection timed out. Check IP and port.';
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Unable to reach server. Check URL and network.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isTesting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.isDismissible,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                offset: Offset(0, 12),
                blurRadius: 28,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Color(0xFFFFFFFF),
                offset: Offset(-3, -3),
                blurRadius: 12,
                spreadRadius: 0,
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.95),
              width: 1.2,
            ),
          ),
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Minimalist Header
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF2F5FA),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0C000000),
                          offset: Offset(1, 2),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.cloud_outlined,
                      color: Color(0xFF1E232E),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Server Host',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E232E),
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          'Enter your FlaCore server URL',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF717D96),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Minimal Text Field
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F8FC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _errorMessage != null
                        ? Colors.redAccent.withValues(alpha: 0.6)
                        : const Color(0xFFE5EAF2),
                    width: 1.0,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: Row(
                  children: [
                    const Icon(
                      Icons.link_rounded,
                      color: Color(0xFF9AA5B8),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        enableSuggestions: false,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E232E),
                        ),
                        decoration: const InputDecoration(
                          hintText: 'http://192.168.1.x:8000',
                          hintStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFFA0AEC0),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        onSubmitted: (_) => _connectAndSave(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.content_paste_rounded,
                        color: Color(0xFF717D96),
                        size: 16,
                      ),
                      tooltip: 'Paste',
                      onPressed: _pasteFromClipboard,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                  ],
                ),
              ),

              // Error Message
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.redAccent,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.redAccent,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 18),

              // Action Buttons
              Row(
                children: [
                  if (widget.isDismissible) ...[
                    Expanded(
                      flex: 1,
                      child: TextButton(
                        onPressed: _isTesting
                            ? null
                            : () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF717D96),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: _isTesting ? null : _connectAndSave,
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E232E),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A1E232E),
                              offset: Offset(0, 4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isTesting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Connect',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                        ),
                      ),
                    ),
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
