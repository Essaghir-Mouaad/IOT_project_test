import 'package:flutter/material.dart';

class HelpCenter extends StatelessWidget {
  const HelpCenter({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Help Center',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF378ADD), Color(0xFF6AA9E8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.support_agent_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Need help using the app?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This app monitors health vitals, shows AI-based risk predictions, and keeps your user profile and device data organized in one place.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _HelpSectionCard(
              title: 'How to use the app',
              icon: Icons.menu_book_rounded,
              iconColor: Color(0xFF378ADD),
              items: const [
                'Open the Home screen to view the latest vitals collected from your connected device.',
                'Check the AI prediction panel to see whether the current condition is Normal, Warning, or Critical.',
                'Use the Settings page to edit your profile or open the Help Center again anytime.',
              ],
            ),
            const SizedBox(height: 12),

            _HelpSectionCard(
              title: 'Profile update guide',
              icon: Icons.person_rounded,
              iconColor: Color(0xFFEF9F27),
              items: const [
                'Go to Settings > Profile to open the profile editor.',
                'Update your name, email, and age if needed.',
                'Tap Save Changes to send the updates to your account and database.',
              ],
            ),
            const SizedBox(height: 12),

            _HelpSectionCard(
              title: 'Understanding predictions',
              icon: Icons.health_and_safety_rounded,
              iconColor: Color(0xFFE24B4A),
              items: const [
                'Normal means the current vitals are within the expected range.',
                'Warning means some values may need attention soon.',
                'Critical means the app detected a high-risk condition and immediate attention may be required.',
              ],
            ),
            const SizedBox(height: 12),

            _HelpSectionCard(
              title: 'When predictions fail',
              icon: Icons.refresh_rounded,
              iconColor: Color(0xFF6B7280),
              items: const [
                'Make sure the device is sending fresh vitals data.',
                'Check that heart rate, SpO₂, temperature, age, and activity values are not empty or zero.',
                'Use the retry option on the prediction screen if the AI result does not load.',
              ],
            ),
            const SizedBox(height: 12),

            _HelpSectionCard(
              title: 'Data and device tips',
              icon: Icons.devices_rounded,
              iconColor: Color(0xFF10B981),
              items: const [
                'Keep your device connected so the vitals screen can refresh automatically.',
                'If values look incorrect, confirm the device is linked to the right account.',
                'A stable internet connection helps keep Firebase data in sync.',
              ],
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFEF9F27).withOpacity(0.25),
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFFBA7517),
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This app supports health monitoring only. It does not replace professional medical advice, diagnosis, or emergency services. If you believe there is a medical emergency, contact local emergency services immediately.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.5,
                        color: Color(0xFF854F0B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<String> items;

  const _HelpSectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 7),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: iconColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
