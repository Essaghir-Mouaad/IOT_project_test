import 'package:brew_crew/services/database.dart';
import 'package:flutter/material.dart';

class LinkDevice extends StatefulWidget {
  final void Function(String deviceId) onDeviceLinked;
  final Future<void> Function() onLogout;
  final DatabaseService db;

  const LinkDevice({
    super.key,
    required this.onDeviceLinked,
    required this.onLogout,
    required this.db,
  });

  @override
  State<LinkDevice> createState() => _LinkDeviceState();
}

class _LinkDeviceState extends State<LinkDevice> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  bool _isLoading = false;
  String _error = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final deviceId = _controller.text.trim();
      final result = await widget.db.linkDevice(deviceId);

      if (!mounted) return;

      if (result == 'success' || result == 'Device already linked to your account') {
        widget.onDeviceLinked(deviceId);
      } else {
        setState(() {
          _error = result; // "Device not found" / "Device already linked to another user"
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Unexpected error: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Device'),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: Colors.blue[300],
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_outlined, color: Colors.white),
            onPressed: () async => await widget.onLogout(),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Icon ──────────────────────────────────
                Icon(Icons.sensors, size: 72, color: Colors.blue[300]),
                const SizedBox(height: 24),

                // ── Title ─────────────────────────────────
                Text(
                  'Enter your device ID',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You need to connect to a device every session.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),

                // ── Input ─────────────────────────────────
                TextFormField(
                  controller: _controller,
                  decoration: InputDecoration(
                    labelText: 'Device ID',
                    hintText: 'e.g. DEVICE_002',
                    prefixIcon: const Icon(Icons.devices),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.blue[200]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.blue[400]!, width: 2),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Device ID is required' : null,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _isLoading ? null : _submit(),
                  autofocus: true,
                ),
                const SizedBox(height: 20),

                // ── Connect button ────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.link),
                    label: Text(_isLoading ? 'Connecting...' : 'Connect'),
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[300],
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

                // ── Error message ─────────────────────────
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _error,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}