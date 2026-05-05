import 'package:brew_crew/screens/home/components/settings/help_center.dart';
import 'package:brew_crew/screens/home/components/settings/profile_settings.dart';
import 'package:flutter/material.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Section
            _buildSettingCard(
              icon: Icons.person_rounded,
              iconColor: const Color(0xFF378ADD),
              iconBg: const Color(0xFF378ADD).withValues(alpha: .1),
              title: 'Profile',
              subtitle: 'View and edit your profile information',
              onTap: () {
                // Navigate to profile settings
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileSettings()),
                );
              },
            ),
            const SizedBox(height: 12),

            // App Mode Section
            _buildSettingCard(
              icon: Icons.palette_rounded,
              iconColor: const Color(0xFFEF9F27),
              iconBg: const Color(0xFFEF9F27).withValues(alpha: .1),
              title: 'App Mode',
              subtitle: 'View and change your app mode (e.g., light/dark)',
              onTap: () {
                // Navigate to app mode settings
              },
            ),
            const SizedBox(height: 12),

            // Help & Support Section
            _buildSettingCard(
              icon: Icons.help_outline_rounded,
              iconColor: const Color(0xFFE24B4A),
              iconBg: const Color(0xFFE24B4A).withValues(alpha: .1),
              title: 'Help & Support',
              subtitle: 'View help resources and contact support',
              onTap: () {
                // Navigate to help & support settings
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpCenter()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withValues(alpha: .15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  // Icon with background
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(icon, size: 28, color: iconColor),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Arrow icon
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
