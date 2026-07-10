import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundmarine_client/screens/Settings/audio_quality_settings_screen.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../widgets/common/page_slide_transition.dart';
import '../widgets/common/settings_tile.dart';
import 'Settings/storage_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with AutomaticKeepAliveClientMixin {

  String _username = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadUsername().then((value) {
      if (mounted) setState(() => _username = value ?? 'Unknown User');
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      color: Colors.black,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _SectionLabel(label: 'General'),
                    const SizedBox(height: 8),
                    SettingsTile(
                      icon: Icons.storage_rounded,
                      label: 'Storage',
                      onTap: () => Navigator.push(
                        context,
                        PageSlideTransition(
                          child: const StorageSettingsScreen(),
                        ),
                      ),
                    ),
                    SettingsTile(
                      icon: Icons.bar_chart,
                      label: 'Audio Quality',
                      onTap: () => Navigator.push(
                        context,
                        PageSlideTransition(
                          child: const AudioQualitySettingsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _LogoutButton(onTap: () => _logout(context)),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: Colors.grey[800],
          child: const Icon(Icons.person, color: Colors.white, size: 32),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Logged in as',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              _username.isEmpty ? 'Unknown User' : _username,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    ApiService.token = null;
    runApp(SoundMarineApp(isLoggedIn: false));
  }

  Future<String?> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: Colors.grey[500],
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Center(
          child: Text(
            'Log Out',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ),
    );
  }
}