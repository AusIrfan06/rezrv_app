import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:croppy/croppy.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../state.dart';
import '../main.dart';
import '../data/user_data.dart';
import '../services/supabase_service.dart';
import '../utils/glass_toast.dart';
import 'package:rezrv/l10n/generated/app_localizations.dart';

import 'auth_screen.dart';
import 'account_details_screen.dart';
import 'personal_info_screen.dart';
import 'payment_methods_screen.dart';
import 'privacy_security_screen.dart';
import 'support_screens.dart';
import 'about_screens.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    if (UserData.userLocation.value.contains(",")) return;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      UserData.userLocation.value = "Location disabled";
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      isBypassingLock = true;
      permission = await Geolocator.requestPermission();
      isBypassingLock = false;

      if (permission == LocationPermission.denied) {
        UserData.userLocation.value = "Permission denied";
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      UserData.userLocation.value = "Permission denied forever";
      return;
    }

    if (UserData.userLocation.value == "Location unavailable") {
      UserData.userLocation.value = "";
    }

    try {
      Position? position = await Geolocator.getLastKnownPosition();
      position ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String city = place.locality?.isNotEmpty == true ? place.locality! : (place.subAdministrativeArea ?? "Unknown City");
        String state = place.administrativeArea ?? "Unknown State";
        UserData.userLocation.value = "$city, $state";
      }
    } catch (e) {
      debugPrint("GPS Error: $e");
      UserData.userLocation.value = "Location unavailable";
    }
  }

  Future<void> _forceRefreshLocation() async {
    UserData.userLocation.value = "Locating...";
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String city = place.locality?.isNotEmpty == true ? place.locality! : (place.subAdministrativeArea ?? "Unknown City");
        String state = place.administrativeArea ?? "Unknown State";
        UserData.userLocation.value = "$city, $state";
      }
    } catch (e) {
      UserData.userLocation.value = "Location unavailable";
    }
  }

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndCropModern(ImageSource source) async {
    isBypassingLock = true;

    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile == null) return;
      if (!mounted) return;

      final result = await showCupertinoImageCropper(
        context,
        imageProvider: FileImage(File(pickedFile.path)),
        allowedAspectRatios: [const CropAspectRatio(width: 1, height: 1)],
      );

      if (result != null) {
        final ui.Image croppedUiImage = result.uiImage;
        final byteData = await croppedUiImage.toByteData(format: ui.ImageByteFormat.png);

        if (byteData != null) {
          final uint8List = byteData.buffer.asUint8List();
          final tempDir = await getTemporaryDirectory();
          final file = await File('${tempDir.path}/profile_crop_${DateTime.now().millisecondsSinceEpoch}.png').create();
          await file.writeAsBytes(uint8List);

          if (SupabaseService.isUserLoggedIn()) {
            final error = await SupabaseService.uploadProfileImage(file);
            if (error != null && mounted) {
              showGlassToast(context, error, isError: true);
            } else if (mounted) {
              showGlassToast(context, "Profile picture updated!");
            }
          } else {
            await UserData.updateProfile(profilePic: file.path);
          }
        }
      }
    } catch (e) {
      debugPrint("Cropping error: $e");
    } finally {
      isBypassingLock = false;
    }
  }

  void _showImageSourceSelector(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasExistingPic = UserData.userProfilePic.value.isNotEmpty;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (dialogContext) => BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.4), width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 10))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Update Photo", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'Inter', color: isDark ? Colors.white : Colors.black87)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOption(dialogContext, HugeIcons.strokeRoundedCamera01, "Camera", Colors.blueAccent, () {
                      Navigator.pop(dialogContext);
                      _pickAndCropModern(ImageSource.camera);
                    }, isDark),
                    _buildOption(dialogContext, HugeIcons.strokeRoundedImage01, "Gallery", Colors.purpleAccent, () {
                      Navigator.pop(dialogContext);
                      _pickAndCropModern(ImageSource.gallery);
                    }, isDark),
                    if (hasExistingPic)
                      _buildOption(dialogContext, HugeIcons.strokeRoundedDelete02, "Remove", Colors.redAccent, () async {
                        Navigator.pop(dialogContext);
                        showGlassToast(context, "Removing picture...");
                        final error = await SupabaseService.deleteProfileImage();
                        if (context.mounted) {
                          if (error != null) {
                            showGlassToast(context, error, isError: true);
                          } else {
                            showGlassToast(context, "Profile picture removed!");
                          }
                        }
                      }, isDark),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                    ),
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text("Cancel", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, dynamic icon, String label, Color color, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.3), width: 1.5)),
            child: HugeIcon(icon: icon, color: color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? Colors.white70 : Colors.black87)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(l10n.profile, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: Colors.grey, size: 24),
            onPressed: () => Navigator.pop(context)
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        ),
      ),
      body: Stack(
        children: [
          Positioned(top: -100, right: -50, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blueAccent.withOpacity(isDark ? 0.05 : 0.1)))),
          Positioned(bottom: -50, left: -50, child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.purpleAccent.withOpacity(isDark ? 0.05 : 0.1)))),

          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 20),

                AnimatedBuilder(
                    animation: Listenable.merge([UserData.userName, UserData.userEmail, UserData.userProfilePic, UserData.userLocation]),
                    builder: (context, _) {
                      final isLoggedIn = SupabaseService.isUserLoggedIn();
                      final hasPic = UserData.userProfilePic.value.isNotEmpty;
                      final name = isLoggedIn && UserData.userName.value.isNotEmpty ? UserData.userName.value : "Guest";
                      final email = isLoggedIn && UserData.userEmail.value.isNotEmpty ? UserData.userEmail.value : "Tap below to log in and sync data";
                      final locationStr = UserData.userLocation.value.isEmpty ? "Locating..." : UserData.userLocation.value;

                      return Center(
                          child: Column(
                              children: [
                                GestureDetector(
                                  onTap: isLoggedIn ? () => _showImageSourceSelector(context) : () {},
                                  child: Stack(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isLoggedIn ? Colors.blue.withOpacity(0.5) : Colors.grey.withOpacity(0.3), width: 2)),
                                        child: CircleAvatar(
                                          radius: 50,
                                          backgroundColor: isDark ? Colors.white10 : Colors.black12,
                                          backgroundImage: hasPic ? (UserData.userProfilePic.value.startsWith('http') ? NetworkImage(UserData.userProfilePic.value) as ImageProvider : FileImage(File(UserData.userProfilePic.value)) as ImageProvider) : null,
                                          child: !hasPic ? const HugeIcon(icon: HugeIcons.strokeRoundedUser, color: Colors.grey, size: 40) : null,
                                        ),
                                      ),
                                      if (isLoggedIn)
                                        Positioned(
                                          bottom: 4, right: 4,
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                                            child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                                const SizedBox(height: 4),
                                Text(email, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                                const SizedBox(height: 8),

                                GestureDetector(
                                  onTap: _forceRefreshLocation, // <--- THIS LINE CONNECTS IT!
                                  behavior: HitTestBehavior.opaque,
                                  child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(20)
                                      ),
                                      child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const HugeIcon(icon: HugeIcons.strokeRoundedLocation01, color: Colors.blue, size: 14),
                                            const SizedBox(width: 4),
                                            Text(locationStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                            const SizedBox(width: 6),
                                            Icon(Icons.refresh_rounded, color: isDark ? Colors.white54 : Colors.black54, size: 12),
                                          ]
                                      )
                                  ),
                                )
                              ]
                          )
                      );
                    }
                ),
                const SizedBox(height: 32),

                if (!SupabaseService.isUserLoggedIn()) ...[
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
                      setState(() {});
                    },
                    child: GlassContainer(
                      useOwnLayer: true, quality: GlassQuality.standard, shape: LiquidRoundedSuperellipse(borderRadius: 24.0), settings: _getGlassSettings(isDark, blur: 10),
                      child: Container(
                        width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(isDark ? 0.1 : 0.15), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.blueAccent.withOpacity(isDark ? 0.3 : 0.5), width: 1.0)),
                        child: const Center(child: Text("Log In / Register", style: TextStyle(color: Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.bold))),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                if (SupabaseService.isUserLoggedIn()) ...[
                  _buildSectionHeader(l10n.account),
                  _buildGlassSection(isDark, Column(children: [
                    _buildSettingsTile(isDark, HugeIcons.strokeRoundedUserEdit01, "Account Details", trailing: _buildArrow(), onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountDetailsScreen()));
                    }),
                    _buildDivider(isDark),
                    _buildSettingsTile(isDark, HugeIcons.strokeRoundedUser, l10n.personalInformation, trailing: _buildArrow(), onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalInfoScreen()));
                    }),
                    _buildDivider(isDark),
                    _buildSettingsTile(isDark, HugeIcons.strokeRoundedCreditCard, l10n.paymentMethods, trailing: _buildArrow(), onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()));
                    }),
                    _buildDivider(isDark),
                    _buildSettingsTile(isDark, HugeIcons.strokeRoundedLock, l10n.privacySecurity, trailing: _buildArrow(), onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacySecurityScreen()));
                    })
                  ])),
                  const SizedBox(height: 24),
                ],

                _buildSectionHeader(l10n.preferences),
                _buildGlassSection(isDark, Column(children: [
                  _buildThemeToggleTile(context, isDark, l10n.darkMode),
                  _buildDivider(isDark),
                  _buildSettingsTile(
                    isDark, HugeIcons.strokeRoundedGlobe02, l10n.language,
                    trailing: ValueListenableBuilder<Locale>(
                        valueListenable: appLocaleNotifier,
                        builder: (context, locale, _) {
                          String displayLanguage = locale.languageCode == 'ms' ? l10n.malay : l10n.english;
                          return Row(mainAxisSize: MainAxisSize.min, children: [Text(displayLanguage, style: const TextStyle(color: Colors.grey, fontSize: 14)), const SizedBox(width: 8), _buildArrow()]);
                        }
                    ),
                    onTap: () => _showLanguageSelector(context),
                  ),
                ])),
                const SizedBox(height: 24),

                if (SupabaseService.isUserLoggedIn()) ...[
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF42A5F5), Color(0xFF1976D2)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))]),
                    child: Row(
                      children: [
                        const HugeIcon(icon: HugeIcons.strokeRoundedGift, color: Colors.white, size: 40),
                        const SizedBox(width: 16),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Invite Friends", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), Text("Get RM10 for every referral", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12))])),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                _buildSectionHeader(l10n.support ?? "SUPPORT"),
                _buildGlassSection(isDark, Column(children: [
                  _buildSettingsTile(isDark, HugeIcons.strokeRoundedCustomerService, l10n.helpCenter ?? "Help Center", trailing: _buildArrow(), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpCenterScreen()))),
                  _buildDivider(isDark),
                  _buildSettingsTile(isDark, HugeIcons.strokeRoundedMessageQuestion, l10n.contactUs ?? "Contact Us", trailing: _buildArrow(), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactUsScreen()))),
                ])),
                const SizedBox(height: 24),

                _buildSectionHeader(l10n.about ?? "ABOUT"),
                _buildGlassSection(isDark, Column(children: [
                  _buildSettingsTile(isDark, HugeIcons.strokeRoundedInformationCircle, l10n.termsOfService ?? "Terms of Service", trailing: _buildArrow(), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalTextScreen(title: "Terms of Service", content: rezrvTermsText)))),
                  _buildDivider(isDark),
                  _buildSettingsTile(isDark, HugeIcons.strokeRoundedShield01, l10n.privacyPolicy ?? "Privacy Policy", trailing: _buildArrow(), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalTextScreen(title: "Privacy Policy", content: rezrvPrivacyText)))),
                  _buildDivider(isDark),
                  _buildSettingsTile(isDark, HugeIcons.strokeRoundedStar, l10n.rateUs ?? "Rate the App", trailing: _buildArrow(), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RateAppScreen(), fullscreenDialog: true))),
                ])),

                const SizedBox(height: 12),
                Center(child: Column(children: [Text("Rezrv v1.0.4", style: TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w600)), const SizedBox(height: 4), Text("Made in Malaysia", style: TextStyle(color: Colors.grey.withOpacity(0.3), fontSize: 10))])),
                const SizedBox(height: 40),

                if (SupabaseService.isUserLoggedIn()) ...[
                  GestureDetector(
                    onTap: () async {
                      await SupabaseService.signOut();
                      if (context.mounted) {
                        showGlassToast(context, "Logged out successfully");
                        setState(() {});
                      }
                    },
                    child: GlassContainer(
                      useOwnLayer: true, quality: GlassQuality.standard, shape: LiquidRoundedSuperellipse(borderRadius: 24.0), settings: _getGlassSettings(isDark, blur: 10),
                      child: Container(
                        width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(color: Colors.redAccent.withOpacity(isDark ? 0.1 : 0.15), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.redAccent.withOpacity(isDark ? 0.3 : 0.5), width: 1.0)),
                        child: Center(child: Text(l10n.logOut, style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold))),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  LiquidGlassSettings _getGlassSettings(bool isDark, {double blur = 15.0}) {
    return LiquidGlassSettings(thickness: 0.1, blur: blur, refractiveIndex: 1.0, glassColor: Colors.transparent, lightAngle: 45.0, lightIntensity: isDark ? 0.1 : 0.2, ambientStrength: 1.0, saturation: 1.0, chromaticAberration: 0.0);
  }

  Widget _buildGlassSection(bool isDark, Widget child) {
    return GlassContainer(
      useOwnLayer: true, quality: GlassQuality.standard, shape: LiquidRoundedSuperellipse(borderRadius: 24.0), settings: _getGlassSettings(isDark),
      child: Container(
        decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.4), borderRadius: BorderRadius.circular(24.0), border: Border.all(color: Colors.white.withOpacity(isDark ? 0.15 : 0.6), width: 1.0), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 16, offset: const Offset(0, 6))]),
        child: child,
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Padding(padding: const EdgeInsets.only(left: 8, bottom: 12), child: Align(alignment: Alignment.centerLeft, child: Text(title.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2))));

  Widget _buildSettingsTile(bool isDark, dynamic icon, String title, {Widget? trailing, VoidCallback? onTap}) => GestureDetector(
    onTap: onTap, behavior: HitTestBehavior.opaque,
    child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04), borderRadius: BorderRadius.circular(12)), child: HugeIcon(icon: icon, color: isDark ? Colors.white : Colors.black87, size: 20)),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
          if (trailing != null) trailing
        ])
    ),
  );

  Widget _buildThemeToggleTile(BuildContext context, bool isDark, String label) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04), borderRadius: BorderRadius.circular(12)), child: HugeIcon(icon: isDark ? HugeIcons.strokeRoundedMoon02 : HugeIcons.strokeRoundedSun01, color: isDark ? Colors.blue : Colors.orange, size: 20)),
        const SizedBox(width: 16),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
        Switch.adaptive(value: isDark, activeColor: Colors.blue, onChanged: (v) { appThemeNotifier.value = v ? ThemeMode.dark : ThemeMode.light; })
      ])
  );

  Widget _buildDivider(bool isDark) => Padding(padding: const EdgeInsets.only(left: 60, right: 16), child: Divider(height: 1, color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)));
  Widget _buildArrow() => const HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: Colors.grey, size: 20);

  void _showLanguageSelector(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context, backgroundColor: isDark ? const Color(0xFF262626) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.selectLanguage, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 24),
            _buildLanguageOption(context, l10n.english, "en", HugeIcons.strokeRoundedTranslate, Colors.blue),
            const SizedBox(height: 12),
            _buildLanguageOption(context, l10n.malay, "ms", HugeIcons.strokeRoundedTranslate, Colors.blue),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext context, String title, String code, dynamic icon, Color color) {
    final isSelected = appLocaleNotifier.value.languageCode == code;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isSelected ? color : Colors.transparent, width: 1.5)),
      tileColor: color.withOpacity(0.05),
      leading: HugeIcon(icon: icon, color: color, size: 22),
      title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? HugeIcon(icon: HugeIcons.strokeRoundedTick01, color: color, size: 20) : null,
      onTap: () {
        appLocaleNotifier.value = Locale(code);
        Navigator.pop(context);
      },
    );
  }
}