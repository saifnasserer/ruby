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
    // Set status bar based on current background
    final isLightBg =
        settingsController.backgroundColor.computeLuminance() > 0.5;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isLightBg ? Brightness.dark : Brightness.light,
        statusBarBrightness: isLightBg ? Brightness.light : Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: RubyTheme.softGray,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('الإعدادات', style: RubyTheme.heading2(context)),
        leading: AnimatedBuilder(
          animation: settingsController,
          builder: (context, _) {
            final isLightBg =
                settingsController.backgroundColor.computeLuminance() > 0.5;
            // Force dark icon if background is transparent (image) or very light
            final useDarkIcon =
                isLightBg ||
                settingsController.backgroundColor == Colors.transparent;

            return IconButton(
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: useDarkIcon ? RubyTheme.charcoal : RubyTheme.pureWhite,
              ),
              onPressed: () => Navigator.pop(context),
            );
          },
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: EdgeInsets.all(RubyTheme.spacingL(context)),
          children: [
            // Wallpaper Section
            _buildSectionHeader(context, 'خلفية الشاشة'),
            SizedBox(height: RubyTheme.spacingM(context)),
            _buildWallpaperSelector(context),

            SizedBox(height: RubyTheme.spacingXL(context)),

            // Notifications Section
            _buildSectionHeader(context, 'الإشعارات'),
            SizedBox(height: RubyTheme.spacingM(context)),
            _buildNotificationSwitch(context),

            SizedBox(height: RubyTheme.spacingXL(context)),

            // About Section
            _buildSectionHeader(context, 'عن التطبيق'),
            SizedBox(height: RubyTheme.spacingM(context)),
            _buildAboutCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: RubyTheme.bodyLarge(
        context,
      ).copyWith(color: RubyTheme.rubyRed, fontWeight: FontWeight.bold),
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

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: colors.length + 1, // +1 for the add image button
        separatorBuilder: (_, __) =>
            SizedBox(width: RubyTheme.spacingM(context)),
        itemBuilder: (context, index) {
          // Last item is the + button for image picker
          if (index == colors.length) {
            return AnimatedBuilder(
              animation: settingsController,
              builder: (context, _) {
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
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: RubyTheme.softGray,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isImageSelected
                            ? RubyTheme.rubyRed
                            : RubyTheme.mediumGray.withOpacity(0.5),
                        width: isImageSelected ? 3 : 1,
                      ),
                    ),
                    child: Icon(
                      Icons.add,
                      color: isImageSelected
                          ? RubyTheme.rubyRed
                          : RubyTheme.mediumGray,
                      size: 30,
                    ),
                  ),
                );
              },
            );
          }

          final colorData = colors[index];
          final colorValue = colorData['color'] as int;
          final color = Color(colorValue);

          return AnimatedBuilder(
            animation: settingsController,
            builder: (context, _) {
              final isSelected =
                  settingsController.wallpaperType == 'color' &&
                  settingsController.backgroundColor.value == colorValue;

              return GestureDetector(
                onTap: () => settingsController.setBackgroundColor(color),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? RubyTheme.pureWhite
                          : RubyTheme.darkGray,
                      width: isSelected ? 3 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color: color.computeLuminance() > 0.5
                              ? RubyTheme.charcoal
                              : RubyTheme.pureWhite,
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationSwitch(BuildContext context) {
    return AnimatedBuilder(
      animation: settingsController,
      builder: (context, _) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: RubyTheme.spacingM(context),
            vertical: RubyTheme.spacingS(context),
          ),
          decoration: BoxDecoration(
            color: RubyTheme.pureWhite,
            borderRadius: BorderRadius.circular(
              RubyTheme.radiusMedium(context),
            ),
          ),
          child: SwitchListTile(
            value: settingsController.enableNotifications,
            onChanged: (value) => settingsController.toggleNotifications(value),
            title: Text(
              'تفعيل الإشعارات',
              style: RubyTheme.bodyMedium(
                context,
              ).copyWith(color: RubyTheme.charcoal),
            ),
            activeColor: RubyTheme.rubyRed,
            contentPadding: EdgeInsets.zero,
          ),
        );
      },
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(RubyTheme.spacingM(context)),
      decoration: BoxDecoration(
        color: RubyTheme.pureWhite,
        borderRadius: BorderRadius.circular(RubyTheme.radiusMedium(context)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: RubyTheme.mediumGray),
              SizedBox(width: RubyTheme.spacingS(context)),
              Text(
                'الإصدار 1.0.0',
                style: RubyTheme.bodyMedium(
                  context,
                ).copyWith(color: RubyTheme.mediumGray),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
