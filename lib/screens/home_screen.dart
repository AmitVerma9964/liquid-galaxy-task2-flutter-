import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/ssh_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/lg_controller.dart';
import '../theme/app_theme.dart';
import 'settings_screen.dart';

/// Main mission control panel — connects SSH, sends KML, manages overlays
class HomeScreen extends ConsumerStatefulWidget {
  final SSHController sshController;
  final SettingsController settingsController;
  final LGController lgController;

  const HomeScreen({
    super.key,
    required this.sshController,
    required this.settingsController,
    required this.lgController,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _activeAction;
  String _output = 'Idle — ready for mission 🚀';

  void _setOutput(String msg) {
    if (mounted) setState(() => _output = msg);
  }

  Future<void> _connectSSH() async {
    setState(() {
      _isConnecting = true;
      _output = '⏳ Connecting to ${widget.settingsController.lgHost}...';
    });
    try {
      final success = await widget.sshController.connect(
        host: widget.settingsController.lgHost,
        port: widget.settingsController.lgPort,
        username: widget.settingsController.lgUsername,
        password: widget.settingsController.lgPassword,
      );
      setState(() {
        _isConnected = success;
        _output = success
            ? '✅ Connected to ${widget.settingsController.lgHost}'
            : '❌ ${widget.sshController.lastError ?? 'Connection failed'}';
      });
    } catch (e) {
      setState(() {
        _isConnected = false;
        _output = '❌ Error: $e';
      });
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  void _disconnectSSH() {
    widget.sshController.disconnect();
    setState(() {
      _isConnected = false;
      _output = '🔌 Disconnected from LG';
    });
  }

  Future<void> _runAction(String label, Future<void> Function() action) async {
    if (!_isConnected) {
      _setOutput('❌ Not connected — please connect first!');
      return;
    }
    setState(() {
      _activeAction = label;
      _output = '⏳ $label...';
    });
    try {
      await action();
      _setOutput('✅ Done: $label');
    } catch (e) {
      _setOutput('❌ Failed: $label\n$e');
    } finally {
      if (mounted) setState(() => _activeAction = null);
    }
  }

  Future<void> _navigateToSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          sshController: widget.sshController,
          settingsController: widget.settingsController,
        ),
      ),
    );
    if (result == true) await _connectSSH();
  }

  void _showSSHDialog() {
    final hostCtrl =
        TextEditingController(text: widget.settingsController.lgHost);
    final portCtrl =
        TextEditingController(text: widget.settingsController.lgPort.toString());
    final userCtrl =
        TextEditingController(text: widget.settingsController.lgUsername);
    final passCtrl =
        TextEditingController(text: widget.settingsController.lgPassword);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.settings_ethernet, color: AppTheme.cyan, size: 20),
            SizedBox(width: 8),
            Text('SSH Details',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _dialogField(hostCtrl, 'IP Address', Icons.computer),
            const SizedBox(height: 12),
            _dialogField(portCtrl, 'Port', Icons.numbers,
                inputType: TextInputType.number),
            const SizedBox(height: 12),
            _dialogField(userCtrl, 'Username', Icons.person),
            const SizedBox(height: 12),
            _dialogField(passCtrl, 'Password', Icons.lock, obscure: true),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.purple,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              await widget.settingsController.saveSettings(
                host: hostCtrl.text,
                port: int.tryParse(portCtrl.text) ?? 22,
                username: userCtrl.text,
                password: passCtrl.text,
                rigsNum: widget.settingsController.lgRigsNum,
              );
              if (mounted) Navigator.pop(context);
              await _connectSSH();
            },
            child: const Text('Save & Connect',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType inputType = TextInputType.text,
    bool obscure = false,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: inputType,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        prefixIcon: Icon(icon, color: AppTheme.cyan, size: 18),
        filled: true,
        fillColor: AppTheme.bgDark,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: AppTheme.purple.withOpacity(0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.cyan),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: _buildAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.bgDark, Color(0xFF0D0A1E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                children: [
                  // ── Visualization ──────────────────────────────────────
                  _sectionHeader('🌍  Visualization', AppTheme.cyan),
                  const SizedBox(height: 12),
                  _actionTile(
                    icon: Icons.flight_takeoff,
                    label: 'Fly to Home City',
                    subtitle: 'Navigate to Agra, India',
                    color: Colors.green,
                    actionKey: 'Fly to Home City',
                    onTap: () => _runAction(
                        'Fly to Home City', widget.lgController.sendKml1),
                  ),
                  const SizedBox(height: 10),
                  _actionTile(
                    icon: Icons.change_history,
                    label: 'Show 3D Pyramid',
                    subtitle: 'Coloured KML pyramid with FlyTo',
                    color: AppTheme.purple,
                    actionKey: 'Show 3D Pyramid',
                    onTap: () => _runAction(
                        'Show 3D Pyramid', widget.lgController.sendKml2),
                  ),
                  const SizedBox(height: 24),

                  // ── Overlay ─────────────────────────────────────────────
                  _sectionHeader('🖼️  Screen Overlay', AppTheme.pink),
                  const SizedBox(height: 12),
                  _actionTile(
                    icon: Icons.image,
                    label: 'Show LG Logo',
                    subtitle: 'Display logo on side screen',
                    color: Colors.blue,
                    actionKey: 'Show LG Logo',
                    onTap: () => _runAction(
                      'Show LG Logo',
                      () => widget.lgController.sendLogoToLeftScreen(
                        assetPath: 'assets/logo.png',
                        logoScreenNumber: widget.lgController.getLogoScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _actionTile(
                    icon: Icons.hide_image,
                    label: 'Clear Logo',
                    subtitle: 'Remove overlay from screen',
                    color: Colors.orange,
                    actionKey: 'Clear Logo',
                    onTap: () => _runAction(
                      'Clear Logo',
                      () => widget.lgController.clearLogoFromLeftScreen(
                        logoScreenNumber: widget.lgController.getLogoScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Cleanup ──────────────────────────────────────────────
                  _sectionHeader('🧹  Cleanup', Colors.redAccent),
                  const SizedBox(height: 12),
                  _actionTile(
                    icon: Icons.delete_sweep,
                    label: 'Clean All KMLs',
                    subtitle: 'Clear all KML files from LG',
                    color: Colors.redAccent,
                    actionKey: 'Clean All KMLs',
                    onTap: () => _runAction(
                        'Clean All KMLs', widget.lgController.clearKmls),
                  ),
                  const SizedBox(height: 10),
                  _actionTile(
                    icon: Icons.settings,
                    label: 'Full Settings',
                    subtitle: 'Configure SSH, rigs, and more',
                    color: Colors.grey,
                    actionKey: 'Settings',
                    onTap: _navigateToSettings,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // ── Terminal output panel ────────────────────────────────────
            _buildOutputPanel(),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.purple.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.rocket_launch,
                color: AppTheme.purple, size: 18),
          ),
          const SizedBox(width: 10),
          const Text(
            'LG Controller',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17),
          ),
          const Spacer(),
          // Connection status chip
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (_isConnected ? Colors.green : Colors.red)
                  .withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isConnected ? Colors.green : Colors.red,
                width: 1,
              ),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (_isConnecting)
                const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: AppTheme.cyan),
                )
              else
                Icon(
                  _isConnected ? Icons.wifi : Icons.wifi_off,
                  color: _isConnected
                      ? Colors.greenAccent
                      : Colors.redAccent,
                  size: 13,
                ),
              const SizedBox(width: 5),
              Text(
                _isConnecting
                    ? 'CONNECTING'
                    : (_isConnected ? 'ONLINE' : 'OFFLINE'),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _isConnecting
                      ? AppTheme.cyan
                      : (_isConnected
                          ? Colors.greenAccent
                          : Colors.redAccent),
                  letterSpacing: 0.5,
                ),
              ),
            ]),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white70),
          color: AppTheme.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          onSelected: (v) {
            if (v == 'edit') _showSSHDialog();
            if (v == 'connect') _connectSSH();
            if (v == 'disconnect') _disconnectSSH();
            if (v == 'settings') _navigateToSettings();
          },
          itemBuilder: (_) => [
            _menuItem('edit', Icons.edit, AppTheme.cyan, 'Edit SSH Details'),
            _menuItem('connect', Icons.link, Colors.greenAccent,
                'Connect SSH'),
            _menuItem('disconnect', Icons.link_off, Colors.redAccent,
                'Disconnect SSH'),
            const PopupMenuDivider(),
            _menuItem('settings', Icons.settings, AppTheme.textSecondary,
                'Full Settings'),
          ],
        ),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(
      String value, IconData icon, Color color, String label) {
    return PopupMenuItem(
      value: value,
      child: Row(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ]),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Row(children: [
      Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 1.4,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(child: Divider(color: color.withOpacity(0.2), thickness: 1)),
    ]);
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required String actionKey,
    required VoidCallback onTap,
  }) {
    final isBusy = _activeAction != null;
    final isThisActive = _activeAction == actionKey;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isBusy && !isThisActive ? 0.45 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isBusy ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.12),
                  AppTheme.surface.withOpacity(0.85),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              border: Border.all(
                color: isThisActive
                    ? color.withOpacity(0.7)
                    : Colors.white.withOpacity(0.06),
                width: isThisActive ? 1.5 : 1,
              ),
              boxShadow: isThisActive
                  ? [
                      BoxShadow(
                          color: color.withOpacity(0.15),
                          blurRadius: 12,
                          spreadRadius: 1),
                    ]
                  : [],
            ),
            child: Row(children: [
              // Icon container
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(isThisActive ? 0.25 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isThisActive
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: color),
                      )
                    : Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              // Labels
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ]),
              ),
              Icon(Icons.chevron_right,
                  color: color.withOpacity(0.4), size: 18),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildOutputPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cyan.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          const Icon(Icons.terminal, color: AppTheme.cyan, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _output,
              style: const TextStyle(
                  color: AppTheme.cyan, fontSize: 12, fontFamily: 'monospace'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_isConnecting)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: AppTheme.cyan),
              ),
            ),
        ],
      ),
    );
  }
}
