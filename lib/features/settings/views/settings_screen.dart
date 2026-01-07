import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/ruby_theme.dart';
import '../controllers/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  final SettingsController settingsController;

  const SettingsScreen({super.key, required this.settingsController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settingsController,
      builder: (context, _) {
        final isDark = settingsController.isDarkMode;

        return Scaffold(
          backgroundColor: RubyTheme.background(context),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Text('الإعدادات', style: RubyTheme.heading2(context)),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: RubyTheme.textPrimary(context),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: ListView(
              padding: EdgeInsets.all(RubyTheme.spacingL(context)),
              children: [
                // Dark Mode Section
                _buildSectionHeader(context, 'المظهر'),
                SizedBox(height: RubyTheme.spacingM(context)),
                _buildSettingCard(
                  context,
                  child: SwitchListTile(
                    value: isDark,
                    onChanged: (value) =>
                        settingsController.toggleDarkMode(value),
                    title: Row(
                      children: [
                        Icon(
                          isDark
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          color: isDark
                              ? RubyTheme.darkGold
                              : RubyTheme.rubyRed,
                        ),
                        SizedBox(width: RubyTheme.spacingM(context)),
                        Text(
                          'الوضع الليلي',
                          style: RubyTheme.bodyMedium(context).copyWith(
                            color: RubyTheme.textPrimary(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    activeColor: RubyTheme.primary(context),
                    activeTrackColor: RubyTheme.primary(
                      context,
                    ).withOpacity(0.3),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                  ),
                ),

                SizedBox(height: RubyTheme.spacingXL(context)),

                // Notifications Section
                _buildSectionHeader(context, 'الإشعارات'),
                SizedBox(height: RubyTheme.spacingM(context)),
                _buildSettingCard(
                  context,
                  child: SwitchListTile(
                    value: settingsController.enableNotifications,
                    onChanged: (value) =>
                        settingsController.toggleNotifications(value),
                    title: Row(
                      children: [
                        Icon(
                          Icons.notifications_active_rounded,
                          color: RubyTheme.textSecondary(context),
                        ),
                        SizedBox(width: RubyTheme.spacingM(context)),
                        Text(
                          'تفعيل الإشعارات',
                          style: RubyTheme.bodyMedium(context).copyWith(
                            color: RubyTheme.textPrimary(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    activeColor: RubyTheme.primary(context),
                    activeTrackColor: RubyTheme.primary(
                      context,
                    ).withOpacity(0.3),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                  ),
                ),

                SizedBox(height: RubyTheme.spacingXL(context)),

                // Wallpaper Section
                _buildSectionHeader(context, 'خلفية الشاشة'),
                SizedBox(height: RubyTheme.spacingM(context)),
                _buildWallpaperSelector(context),
                SizedBox(height: RubyTheme.spacingM(context)),
                _buildOpacitySlider(context),

                SizedBox(height: RubyTheme.spacingXL(context)),

                // About Section
                // _buildSectionHeader(context, 'عن التطبيق'),
                // SizedBox(height: RubyTheme.spacingM(context)),
                // _buildAboutCard(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: RubyTheme.spacingS(context)),
      child: Text(
        title,
        style: RubyTheme.bodyLarge(context).copyWith(
          color: RubyTheme.primary(context),
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildSettingCard(BuildContext context, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: RubyTheme.surface(context),
        borderRadius: BorderRadius.circular(RubyTheme.radiusMedium(context)),
        boxShadow: RubyTheme.softShadow(context),
        border: Border.all(
          color: RubyTheme.textSecondary(context).withOpacity(0.05),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(RubyTheme.radiusMedium(context)),
        child: child,
      ),
    );
  }

  Widget _buildWallpaperSelector(BuildContext context) {
    final colors = [
      {'name': 'أبيض', 'color': 0xFFFFFFFF},
      {'name': 'أسود', 'color': 0xFF121212},
      {'name': 'رمادي داكن', 'color': 0xFF1E1E1E},
      {'name': 'أزرق ليلي', 'color': 0xFF0D1B2A},
      {'name': 'أحمر داكن', 'color': 0xFF2A0D0D},
      {'name': 'بنفسجي', 'color': 0xFF1A0D2A},
    ];

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RubyTheme.surface(context),
        borderRadius: BorderRadius.circular(RubyTheme.radiusMedium(context)),
        boxShadow: RubyTheme.softShadow(context),
        border: Border.all(
          color: RubyTheme.textSecondary(context).withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 70,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: colors.length + 2,
              separatorBuilder: (_, __) => SizedBox(width: 12),
              itemBuilder: (context, index) {
                // Default pattern asset
                if (index == 0) {
                  final isSelected =
                      settingsController.wallpaperType == 'image' &&
                      settingsController.isAssetWallpaper;
                  return GestureDetector(
                    onTap: () => settingsController.setWallpaperImage(
                      'assets/pattern.jpg',
                      isAsset: true,
                    ),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: AssetImage('assets/pattern.jpg'),
                          fit: BoxFit.cover,
                        ),
                        border: Border.all(
                          color: isSelected
                              ? RubyTheme.primary(context)
                              : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? RubyTheme.softShadow(context)
                            : null,
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              color: RubyTheme.pureWhite,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                }

                // Image picker button
                if (index == colors.length + 1) {
                  final isImageSelected =
                      settingsController.wallpaperType == 'image';
                  return GestureDetector(
                    onTap: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.gallery,
                      );

                      if (image != null) {
                        await settingsController.setWallpaperImage(image.path);
                      }
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: RubyTheme.surfaceVariant(context),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isImageSelected
                              ? RubyTheme.primary(context)
                              : RubyTheme.textTertiary(
                                  context,
                                ).withOpacity(0.3),
                          width: isImageSelected ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        Icons.add_photo_alternate_rounded,
                        color: isImageSelected
                            ? RubyTheme.primary(context)
                            : RubyTheme.textSecondary(context),
                        size: 24,
                      ),
                    ),
                  );
                }

                final colorData = colors[index - 1];
                final colorValue = colorData['color'] as int;
                final color = Color(colorValue);

                final isSelected =
                    settingsController.wallpaperType == 'color' &&
                    settingsController.backgroundColor.value == colorValue;

                return GestureDetector(
                  onTap: () => settingsController.setBackgroundColor(color),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? RubyTheme.textPrimary(context)
                            : Colors.transparent,
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            color: color.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white,
                            size: 20,
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpacitySlider(BuildContext context) {
    if (settingsController.wallpaperType != 'image' ||
        settingsController.isAssetWallpaper) {
      return const SizedBox.shrink();
    }

    return _buildSettingCard(
      context,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'شفافية الخلفية',
                  style: RubyTheme.bodyMedium(context).copyWith(
                    color: RubyTheme.textPrimary(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${(settingsController.wallpaperOpacity * 100).toInt()}%',
                  style: RubyTheme.caption(context),
                ),
              ],
            ),
            Row(
              children: [
                Icon(
                  Icons.opacity,
                  size: 20,
                  color: RubyTheme.textTertiary(context),
                ),
                Expanded(
                  child: Slider(
                    value: settingsController.wallpaperOpacity,
                    onChanged: (value) =>
                        settingsController.setWallpaperOpacity(value),
                    activeColor: RubyTheme.primary(context),
                    inactiveColor: RubyTheme.surfaceVariant(context),
                  ),
                ),
                Icon(
                  Icons.blur_on,
                  size: 24,
                  color: RubyTheme.textTertiary(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    return _buildSettingCard(
      context,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: RubyTheme.textSecondary(context),
            ),
            SizedBox(width: RubyTheme.spacingM(context)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'روبي للمهام',
                  style: RubyTheme.bodyMedium(context).copyWith(
                    color: RubyTheme.textPrimary(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('الإصدار 1.0.0', style: RubyTheme.caption(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
