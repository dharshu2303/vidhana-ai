import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import '../services/translation_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _stationCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthService>(context, listen: false);
      _stationCtrl.text = auth.currentUser?.policeStation ?? '';
      _nameCtrl.text = auth.currentUser?.complainantName.isNotEmpty == true
          ? auth.currentUser!.complainantName
          : auth.currentUser?.name ?? '';
    });
  }

  @override
  void dispose() {
    _stationCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = Provider.of<TranslationService>(context);
    final auth = Provider.of<AuthService>(context);
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(tr.t('profile')),
        backgroundColor: AppColors.surfaceCard,
        automaticallyImplyLeading: false,
        actions: [
          TextButton.icon(
            onPressed: () {
              if (_editing) {
                auth.updateProfile(
                  policeStation: _stationCtrl.text.trim(),
                  complainantName: _nameCtrl.text.trim(),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile saved successfully')),
                );
              }
              setState(() => _editing = !_editing);
            },
            icon: Icon(_editing ? Icons.check_rounded : Icons.edit_rounded,
                size: 18),
            label: Text(_editing ? 'Save' : 'Edit'),
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Hero profile card - Now Minimalist White
            FadeInDown(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Avatar circle
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceElevated,
                        border: Border.all(color: AppColors.border, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          user?.name.isNotEmpty == true
                              ? user!.name[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      user?.name ?? 'User',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Role & Badge chips
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _MonoBadge(
                            icon: Icons.security_rounded,
                            label: user?.role ?? 'Officer'),
                        const SizedBox(width: 12),
                        _MonoBadge(
                            icon: Icons.badge_rounded,
                            label: user?.badgeNo ?? 'N/A'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Auto-fill Setup section
            FadeInUp(
              delay: const Duration(milliseconds: 100),
              child: _SectionHeader(
                icon: Icons.auto_fix_high_rounded,
                title: 'FIR Auto-Fill Settings',
                subtitle: 'Pre-fill FIR forms from your profile',
              ),
            ),
            const SizedBox(height: 12),

            // Complainant Name
            FadeInUp(
              delay: const Duration(milliseconds: 150),
              child: _editing
                  ? _EditField(
                      controller: _nameCtrl,
                      label: 'Default Complainant Name',
                      icon: Icons.person_outline_rounded,
                    )
                  : _InfoTile(
                      icon: Icons.person_rounded,
                      iconColor: AppColors.accent,
                      label: 'Complainant Name',
                      value: user?.complainantName.isNotEmpty == true
                          ? user!.complainantName
                          : user?.name ?? 'Not set',
                    ),
            ),
            const SizedBox(height: 8),

            // Police Station
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: _editing
                  ? _EditField(
                      controller: _stationCtrl,
                      label: 'Police Station',
                      icon: Icons.local_police_outlined,
                    )
                  : _InfoTile(
                      icon: Icons.local_police_rounded,
                      iconColor: AppColors.info,
                      label: 'Police Station',
                      value: user?.policeStation.isNotEmpty == true
                          ? user!.policeStation
                          : 'Not set',
                    ),
            ),
            const SizedBox(height: 24),

            // Language & Settings
            FadeInUp(
              delay: const Duration(milliseconds: 250),
              child: _SectionHeader(
                icon: Icons.settings_rounded,
                title: 'App Settings',
                subtitle: 'Configure your preferences',
              ),
            ),
            const SizedBox(height: 12),

            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: _InfoTile(
                icon: Icons.language_rounded,
                iconColor: AppColors.info,
                label: tr.t('language'),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: tr.locale,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    items: TranslationService.supportedLocales.entries
                        .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) tr.setLocale(v);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            FadeInUp(
              delay: const Duration(milliseconds: 350),
              child: _InfoTile(
                icon: Icons.info_outline_rounded,
                iconColor: AppColors.accentGold,
                label: tr.t('about_app'),
                value: tr.t('about_desc'),
              ),
            ),
            const SizedBox(height: 8),
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: _InfoTile(
                icon: Icons.verified_rounded,
                iconColor: AppColors.success,
                label: tr.t('app_version'),
                trailing: const Text('1.0.0',
                    style:
                        TextStyle(color: AppColors.textMuted, fontSize: 14)),
              ),
            ),
            const SizedBox(height: 28),

            // Logout
            FadeInUp(
              delay: const Duration(milliseconds: 450),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    auth.logout();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                  label: Text(tr.t('logout'),
                      style: const TextStyle(color: AppColors.error)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.error.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.accent, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                )),
            Text(subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                )),
          ],
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? value;
  final Widget? trailing;

  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.lightCard(),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    )),
                if (value != null) ...[
                  const SizedBox(height: 2),
                  Text(value!,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;

  const _EditField({
    required this.controller,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
    );
  }
}

class _MonoBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MonoBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.accent),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
