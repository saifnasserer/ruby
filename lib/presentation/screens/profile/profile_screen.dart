import 'package:flutter/material.dart';
import 'package:ruby/core/services/auth_service.dart';
import 'package:ruby/core/services/sync_service.dart';
import 'package:ruby/core/services/backend_service.dart';
import 'package:ruby/core/theme/ruby_theme.dart';
import 'package:ruby/core/utils/ruby_snackbars.dart';
import 'package:ruby/features/settings/controllers/settings_controller.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ruby/presentation/screens/auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  final SettingsController? settingsController;

  const ProfileScreen({super.key, this.settingsController});

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'لم يتم المزامنة بعد';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settingsController ?? ChangeNotifier(),
      builder: (context, _) {
        final user = AuthService.instance.currentUser;
        final isAuthenticated = AuthService.instance.isAuthenticated;
        final lastSync = SyncService.instance.lastSyncTime;

        // Construct avatar URL
        String? avatarUrl;
        final avatarName = user?.getStringValue('avatar') ?? '';
        if (user != null && avatarName.isNotEmpty) {
          avatarUrl = BackendService.instance
              .getFileUrl(user, avatarName)
              .toString();
        }

        return Scaffold(
          backgroundColor: RubyTheme.background(context),
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 60,
                  floating: true,
                  pinned: true,
                  backgroundColor: RubyTheme.background(context),
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  leading: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_rounded,
                      color: RubyTheme.textPrimary(context),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  centerTitle: true,
                  title: Text(
                    'الملف الشخصي',
                    style: RubyTheme.heading2(context).copyWith(
                      color: RubyTheme.textPrimary(context),
                      fontSize: 18,
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // USER HEADER (Simplified, no box)
                        _buildHeroHeader(
                          context,
                          user: user,
                          avatarUrl: avatarUrl,
                          isAuthenticated: isAuthenticated,
                        ),

                        const SizedBox(height: 48),

                        // SECTION 1: ACCOUNT DETAILS (Linear, no box)
                        _buildSectionHeader(context, 'حالة الحساب'),
                        _buildDetailTile(
                          context,
                          icon: Icons.cloud_done_rounded,
                          label: 'آخر مزامنة',
                          value: _formatDateTime(lastSync),
                          color: Colors.blueAccent,
                        ),
                        _buildDetailTile(
                          context,
                          icon: Icons.calendar_today_rounded,
                          label: 'عضو من',
                          value: user != null
                              ? _formatDateTime(
                                  DateTime.tryParse(
                                    user.getStringValue('created'),
                                  ),
                                )
                              : 'غير متوفر',
                          color: Colors.orangeAccent,
                        ),

                        const SizedBox(height: 32),

                        // SECTION 2: ACTIONS
                        _buildSectionHeader(context, 'تطوير وتواصل'),
                        _buildActionTile(
                          context,
                          icon: Icons.share_rounded,
                          label: 'شارك بكيزة مع صحابك',
                          iconColor: Colors.deepPurpleAccent,
                          onTap: () {
                            Share.share(
                              'حمل تطبيق بكيزة ونظم يومك بسهولة! ✨\nhttps://play.google.com/store/apps/details?id=cloud.kingsaif.bakiza',
                            );
                          },
                        ),
                        _buildActionTile(
                          context,
                          icon: Icons.bug_report_rounded,
                          label: 'بلغ عن مشكلة',
                          iconColor: Colors.teal,
                          onTap: () async {
                            final whatsappUrl = Uri.parse(
                              "https://wa.me/201120352161",
                            );
                            if (await canLaunchUrl(whatsappUrl)) {
                              await launchUrl(
                                whatsappUrl,
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              RubySnackBar.showError(
                                context,
                                "مش عارفين نفتح واتساب.. جرب تاني؟ �",
                              );
                            }
                          },
                        ),

                        const SizedBox(height: 48),

                        // AUTH ACTION (Login/Logout)
                        _buildAuthButton(
                          context,
                          isAuthenticated: isAuthenticated,
                        ),

                        const SizedBox(height: 60),

                        // FOOTER
                        Text(
                          "Bakiza - v1.0.0+14",
                          style: RubyTheme.caption(context).copyWith(
                            color: RubyTheme.textTertiary(context),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String label) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      alignment: Alignment.centerRight,
      child: Text(
        label,
        style: RubyTheme.bodyMedium(context).copyWith(
          color: RubyTheme.textSecondary(context),
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildHeroHeader(
    BuildContext context, {
    required dynamic user,
    required String? avatarUrl,
    required bool isAuthenticated,
  }) {
    return Column(
      children: [
        // Avatar with premium glow (kept circular but without the outer box)
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RubyTheme.rubyGradient,
            boxShadow: [
              BoxShadow(
                color: RubyTheme.primary(context).withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(4), // Ring effect
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: RubyTheme.background(context),
              ),
              child: ClipOval(
                child: avatarUrl != null
                    ? Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => _buildInitials(user),
                      )
                    : _buildInitials(user),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          user?.getStringValue('name') ?? (isAuthenticated ? 'بكيزة' : 'ضيف'),
          textAlign: TextAlign.center,
          style: RubyTheme.heading2(
            context,
          ).copyWith(fontSize: 26, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          user?.getStringValue('email') ?? 'سجل دخولك عشان تاسكاتك تفضل معاك',
          textAlign: TextAlign.center,
          style: RubyTheme.bodyLarge(context).copyWith(
            fontSize: 15,
            color: RubyTheme.textSecondary(context).withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildInitials(dynamic user) {
    return Center(
      child: Text(
        user?.getStringValue('name').isNotEmpty == true
            ? user!.getStringValue('name')[0].toUpperCase()
            : 'B',
        style: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: Colors.pink.shade300,
        ),
      ),
    );
  }

  Widget _buildDetailTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: RubyTheme.caption(context).copyWith(
                    color: RubyTheme.textSecondary(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  value,
                  style: RubyTheme.bodyLarge(context).copyWith(
                    color: RubyTheme.textPrimary(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  label,
                  style: RubyTheme.bodyLarge(context).copyWith(
                    color: RubyTheme.textPrimary(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: RubyTheme.textTertiary(context),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthButton(
    BuildContext context, {
    required bool isAuthenticated,
  }) {
    if (!isAuthenticated) {
      return Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          gradient: RubyTheme.rubyGradient,
          boxShadow: [
            BoxShadow(
              color: RubyTheme.primary(context).withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    LoginScreen(settingsController: settingsController),
              ),
            );
          },
          icon: const Icon(Icons.login_rounded, color: Colors.white),
          label: const Text(
            'تسجيل الدخول',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              fontFamily: 'NotoSansArabic',
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () {
          AuthService.instance.signOut();
          RubySnackBar.showInfo(context, "خرجت.. مستنيينك تاني! 👋");
          Navigator.pop(context);
        },
        icon: const Icon(Icons.logout_rounded, color: Colors.white),
        label: const Text(
          'تسجيل الخروج',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            fontFamily: 'NotoSansArabic',
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
        ),
      ),
    );
  }
}
