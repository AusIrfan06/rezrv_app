import 'dart:ui';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import '../screens/profile_screen.dart';
import '../data/shop_data.dart';
import 'package:rezrv/l10n/generated/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../screens/shop_detail_screen.dart';
import '../data/user_data.dart';
import '../screens/notifications_screen.dart';
import '../services/supabase_service.dart';
import '../data/notification_data.dart'; // 🟢 ADD THIS LINE


class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  // 🟢 Category State
  String _selectedCategory = "Haircuts";

  // 🟢 SAVED SHOPS STATE: This stores the names of the shops you "Like"
  final Set<String> _savedShops = {};

  // 🟢 3D Stack & Timer State
  int _frontAdIndex = 0;
  Timer? _adTimer;

  // 🟢 VIBRANT GRADIENTS FOR ADS
  final List<Map<String, dynamic>> _promoAds = [
    {
      "title": "50% Off",
      "subtitle": "Premium Haircuts",
      "date": "Ends Mar 24",
      "image": "https://images.unsplash.com/photo-1599351431202-1e0f0137899a?q=80&w=300",
      "colors": [const Color(0xFF42A5F5), const Color(0xFF1976D2)], // Vibrant Blue
    },
    {
      "title": "RM30 Cash",
      "subtitle": "Spa & Massage",
      "date": "First time users",
      "image": "https://images.unsplash.com/photo-1540555700478-4be289fbecef?q=80&w=300",
      "colors": [const Color(0xFFAB47BC), const Color(0xFF7B1FA2)], // Vibrant Purple
    },
    {
      "title": "Free Wash",
      "subtitle": "With every cut",
      "date": "Limited time",
      "image": "https://images.unsplash.com/photo-1622286342621-4bd786c2447c?q=80&w=300",
      "colors": [const Color(0xFFFFA726), const Color(0xFFF57C00)], // Vibrant Orange
    },
    {
      "title": "20% Off",
      "subtitle": "VIP Grooming",
      "date": "Weekends only",
      "image": "https://images.unsplash.com/photo-1503951914875-452162b0f3f1?q=80&w=300",
      "colors": [const Color(0xFF26A69A), const Color(0xFF00695C)], // Vibrant Teal
    }
  ];

  // Data for the Categories
  final List<Map<String, dynamic>> _serviceCategories = [
    {"name": "Haircuts", "icon": Icons.content_cut},
    {"name": "Shaving", "icon": Icons.face},
    {"name": "Coloring", "icon": Icons.color_lens_outlined},
    {"name": "Styling", "icon": Icons.auto_awesome},
    {"name": "Facial", "icon": Icons.face_retouching_natural},
    {"name": "Massage", "icon": Icons.spa_outlined},
    {"name": "Nails", "icon": Icons.back_hand_outlined},
    {"name": "More", "icon": Icons.more_horiz},
  ];

  @override
  void initState() {
    super.initState();
    _startAdTimer();
    _getCurrentLocation(); // 🟢 Fetch GPS as soon as screen loads
  }

  Future<void> _getCurrentLocation() async {
    // 🟢 REMOVED: The check that stopped the GPS from running if a cache existed.
    // Now it will ALWAYS fetch your real live location silently in the background!

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    try {
      // 🟢 Fetch fresh, real-time location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // Medium is faster and perfect for getting the City
        timeLimit: const Duration(seconds: 10),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String city = place.locality?.isNotEmpty == true ? place.locality! : (place.subAdministrativeArea ?? "Unknown City");
        String state = place.administrativeArea ?? "Unknown State";

        // 🟢 Update the global state! This updates HomeView and ProfileScreen instantly.
        UserData.userLocation.value = "$city, $state";
      }
    } catch (e) {
      debugPrint("HomeView GPS Error: $e");
    }
  }

  // Auto-slide every 5 seconds
  void _startAdTimer() {
    _adTimer?.cancel();
    _adTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _frontAdIndex = (_frontAdIndex + 1) % _promoAds.length;
        });
      }
    });
  }

  void _resetAdTimer() {
    _startAdTimer();
  }

  @override
  void dispose() {
    _adTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // 🟢 Add this!
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF2C2C2C);

    List<int> orderedAdIndices = List.generate(_promoAds.length, (i) => i);
    orderedAdIndices.sort((a, b) {
      int relA = (a - _frontAdIndex + _promoAds.length) % _promoAds.length;
      int relB = (b - _frontAdIndex + _promoAds.length) % _promoAds.length;
      return relB.compareTo(relA);
    });

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF13171B) : const Color(0xFFE5ECF1),
      body: SizedBox.expand(
        child: Stack(
          children: [
            // --- 1. AMBIENT BLURRED BACKGROUND ---
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF1E242B), const Color(0xFF13171B)]
                        : [const Color(0xFFE5ECF1), const Color(0xFFD4DEE5)],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -100, left: -100,
              child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withOpacity(isDark ? 0.2 : 0.35))),
            ),
            Positioned(
              bottom: 100, right: -50,
              child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.indigo.withOpacity(isDark ? 0.15 : 0.25))),
            ),
            Positioned.fill(
              child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60), child: const SizedBox()),
            ),

            // --- 2. MAIN CONTENT ---
            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- HEADER AREA ---
                    AnimatedBuilder(
                      // 🟢 ADDED: NotificationData.unreadCount to the merge list
                        animation: Listenable.merge([
                          UserData.userName,
                          UserData.userProfilePic,
                          UserData.userLocation,
                          NotificationData.unreadCount
                        ]),
                        builder: (context, _) {
                          final bool isLoggedIn = SupabaseService.isUserLoggedIn();
                          // 🟢 Get the current unread count
                          final int unreadCount = NotificationData.unreadCount.value;

                          final String displayName = isLoggedIn && UserData.userName.value.isNotEmpty
                              ? UserData.userName.value.split(" ")[0]
                              : "Guest";

                          final location = UserData.userLocation.value;
                          final displayAddress = location.isEmpty ? l10n.locating : location;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // 🟢 1. AVATAR CIRCLE (Left)
                                GestureDetector(
                                  onTap: () => Navigator.of(context, rootNavigator: true).push(
                                      MaterialPageRoute(builder: (context) => const ProfileSettingsScreen())
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDark ? Colors.white10 : Colors.black12,
                                      border: Border.all(color: Colors.white.withOpacity(isDark ? 0.1 : 0.6), width: 2),
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                                    ),
                                    child: ValueListenableBuilder<String>(
                                      valueListenable: UserData.userProfilePic,
                                      builder: (context, picPath, _) {
                                        final bool showPic = isLoggedIn && picPath.isNotEmpty;
                                        return CircleAvatar(
                                          radius: 24,
                                          backgroundColor: Colors.transparent,
                                          backgroundImage: showPic
                                              ? (picPath.startsWith('http')
                                              ? NetworkImage(picPath) as ImageProvider
                                              : FileImage(File(picPath)) as ImageProvider)
                                              : null,
                                          child: !showPic ? const Icon(Icons.person, color: Colors.grey, size: 22) : null,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // 🟢 2. COLUMN: NAME & LOCATION (Middle)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        l10n.hiUser(displayName),
                                        // 👇 ADJUST DISPLAY NAME SIZE HERE (fontSize: 22)
                                        style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.5),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      // 👇 ADJUST SPACE BETWEEN NAME AND LOCATION HERE (height: 4)
                                      const SizedBox(height: 0),
                                      Row(
                                        children: [
                                          // 👇 ADJUST LOCATION PIN ICON SIZE HERE (size: 16)
                                          const Icon(Icons.location_on_rounded, color: Colors.blue, size: 16),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              displayAddress,
                                              // 👇 ADJUST LOCATION TEXT SIZE HERE (fontSize: 14)
                                              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14, fontWeight: FontWeight.w600),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // 🟢 3. NOTIFICATION BUTTON (Right - Bare Icon Now!)
                                // 🟢 3. NOTIFICATION BUTTON (Right - Bare Icon)
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    GestureDetector(
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                                      child: Icon(
                                          Icons.notifications_none_rounded,
                                          color: textColor,
                                          size: 28
                                      ),
                                    ),

                                    // 🟢 THE FIX: Only render the red dot if unreadCount is greater than 0
                                    if (unreadCount > 0)
                                      Positioned(
                                        top: 2, right: 3,
                                        child: Container(
                                            width: 9, height: 9,
                                            decoration: BoxDecoration(
                                                color: Colors.redAccent,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: isDark ? const Color(0xFF13171B) : const Color(0xFFE5ECF1), width: 1.5)
                                            )
                                        ),
                                      )
                                  ],
                                )
                              ],
                            ),
                          );
                        }
                    ),
                    const SizedBox(height: 12),

                    // --- PROMOTIONS TEXT ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(l10n.promotions, style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),

                    // --- 3D SWIPEABLE AD STACK ---
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragEnd: (DragEndDetails details) {
                        if (details.primaryVelocity == null) return;
                        _resetAdTimer();

                        if (details.primaryVelocity! < -300) {
                          setState(() => _frontAdIndex = (_frontAdIndex + 1) % _promoAds.length);
                        } else if (details.primaryVelocity! > 300) {
                          setState(() => _frontAdIndex = (_frontAdIndex - 1 + _promoAds.length) % _promoAds.length);
                        }
                      },
                      child: SizedBox(
                        // 🟢 TWEAK 2: Reduced height from 230 to 200! This brings the categories much closer to the ads.
                        height: 200,
                        child: Stack(
                          alignment: Alignment.topCenter,
                          clipBehavior: Clip.none,
                          children: orderedAdIndices.map((index) {
                            int relativePosition = (index - _frontAdIndex + _promoAds.length) % _promoAds.length;

                            double top;
                            double scale;
                            double opacity;

                            if (relativePosition == 0) {
                              top = 0; scale = 1.0; opacity = 1.0;
                            } else if (relativePosition == 1) {
                              top = 18; scale = 0.94; opacity = 0.95;
                            } else if (relativePosition == 2) {
                              top = 36; scale = 0.88; opacity = 0.7;
                            } else {
                              top = 36; scale = 0.88; opacity = 0.0;
                            }

                            return AnimatedPositioned(
                              key: ValueKey(index),
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOutQuint,
                              top: top,
                              left: 20,
                              right: 20,
                              child: AnimatedScale(
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeOutQuint,
                                scale: scale,
                                alignment: Alignment.topCenter,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 400),
                                  opacity: opacity,
                                  child: GestureDetector(
                                    onTap: () {
                                      if (relativePosition != 0) {
                                        _resetAdTimer();
                                        setState(() => _frontAdIndex = index);
                                      }
                                    },
                                    child: AbsorbPointer(
                                      absorbing: relativePosition != 0,
                                      child: _buildAdWalletCard(_promoAds[index]),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // --- CATEGORY SECTION ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        children: [
                          Text(l10n.categories, style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _serviceCategories.length,
                        itemBuilder: (context, index) {
                          return _buildHorizontalCategoryItem(_serviceCategories[index], isDark);
                        },
                      ),
                    ),
                    const SizedBox(height: 8),

                    // --- RECOMMENDED SECTION ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.recommended, style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
                          Text(l10n.seeAll, style: TextStyle(color: Colors.blue.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.bold)),                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 🟢 NATIVE STAGGERED GRID
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: _buildStaggeredGrid(isDark),
                    ),

                    const SizedBox(height: 120), // Bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---

  // 🟢 FIXED: Added 'VoidCallback onTap'
  Widget _buildGlassIconButton(IconData icon, bool isDark, Color iconColor, VoidCallback onTap) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.5),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(isDark ? 0.1 : 0.6), width: 1.5),
          ),
          child: IconButton(
            icon: Icon(icon, color: iconColor, size: 22),
            onPressed: onTap, // 🟢 Trigger the passed function
          ),
        ),
      ),
    );
  }

  // --- AD CARD ---
  Widget _buildAdWalletCard(Map<String, dynamic> ad) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 170,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: ad["colors"],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),

        // 🟢 TWEAK 1: SHORTER, TIGHTER SHADOWS
        boxShadow: [
          BoxShadow(
            color: ad["colors"][0].withOpacity(0.5), // Slightly less intense
            offset: const Offset(0, 8), // 🟢 Reduced drop from 15 to 8
            blurRadius: 15, // 🟢 Reduced blur from 30 to 15
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 4), // 🟢 Reduced drop from 5 to 4
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0, top: 0, bottom: 0,
            child: SizedBox(
              width: 150,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(28),
                        bottomRight: Radius.circular(28)),
                    child: Image.network(ad["image"], fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft, end: Alignment.centerRight,
                        colors: [
                          ad["colors"][0].withOpacity(1.0),
                          Colors.transparent
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(l10n.promoLabel, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),                ),
                const Spacer(),
                Text(
                  ad["title"],
                  style: const TextStyle(color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1.1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  ad["subtitle"],
                  style: const TextStyle(color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(ad["date"], style: const TextStyle(color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white,
                          borderRadius: BorderRadius.circular(16)),
                      child: Text(l10n.claimButton, style: TextStyle(color: ad["colors"][1], fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getLocalizedCategoryName(String originalName) {
    final l10n = AppLocalizations.of(context)!;
    switch (originalName) {
      case "Haircuts": return l10n.catHaircuts;
      case "Shaving": return l10n.catShaving;
      case "Coloring": return l10n.catColoring;
      case "Styling": return l10n.catStyling;
      case "Facial": return l10n.catFacial;
      case "Massage": return l10n.catMassage;
      case "Nails": return l10n.catNails;
      case "More": return l10n.catMore;
      default: return originalName;
    }
  }

  Widget _buildHorizontalCategoryItem(Map<String, dynamic> category, bool isDark) {
    bool isSelected = _selectedCategory == category["name"];
    String localizedName = _getLocalizedCategoryName(category["name"]); // 🟢 Translate here

    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category["name"]),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 72,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.blue.withOpacity(0.2)
                    : (isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6)),
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: Colors.blue, width: 1.5)
                    : Border.all(color: Colors.white.withOpacity(isDark ? 0.1 : 0.8), width: 1.5),
              ),
              child: Icon(
                category["icon"],
                color: isSelected ? Colors.blue : (isDark ? Colors.white70 : Colors.black87),
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              localizedName,
              style: TextStyle(
                color: isSelected ? Colors.blue : (isDark ? Colors.white70 : Colors.black87),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // --- STAGGERED GRID ---
  Widget _buildStaggeredGrid(bool isDark) {
    List<Widget> leftColumn = [];
    List<Widget> rightColumn = [];

    final displayShops = ShopData.shops.take(6).toList();

    for (int i = 0; i < displayShops.length; i++) {
      Widget card = _buildRecommendedCard(displayShops[i], isDark);
      if (i % 2 == 0) {
        leftColumn.add(card);
      } else {
        rightColumn.add(card);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(children: leftColumn)),
        const SizedBox(width: 16),
        Expanded(child: Column(children: rightColumn)),
      ],
    );
  }

  // --- RECOMMENDED CARD ---
  Widget _buildRecommendedCard(Map<String, dynamic> shop, bool isDark) {
    final l10n = AppLocalizations.of(context)!;

    final String shopName = shop["name"] ?? l10n.unknownShop;
    final String rating = shop["rating"]?.toString() ?? "0.0";
    final String reviews = shop["reviews"]?.toString() ?? "0";

    final List<dynamic>? serviceList = shop["services"];
    final String servicesStr = (serviceList != null && serviceList.isNotEmpty)
        ? serviceList.join(", ")
        : (shop["category"]?.toString() ?? l10n.generalCategory);

    return GestureDetector( // 🟢 ADD THIS WRAPPER
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ShopDetailScreen(shop: shop),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(isDark ? 0.1 : 0.6), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          child: Image.network(shop["image"] ?? "https://images.unsplash.com/photo-1503951914875-452162b0f3f1?q=80&w=300", fit: BoxFit.cover, width: double.infinity, height: 120),
                        ),

                        Positioned(
                          top: 8,
                          right: 8,
                          child: ValueListenableBuilder<Set<String>>(
                            valueListenable: ShopData.savedShopNames,
                            builder: (context, savedSet, child) {
                              final bool isSaved = savedSet.contains(shopName);

                              return GestureDetector(
                                onTap: () {
                                  final newSet = Set<String>.from(savedSet);
                                  if (isSaved) {
                                    newSet.remove(shopName);
                                  } else {
                                    newSet.add(shopName);
                                  }
                                  ShopData.savedShopNames.value = newSet;
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
                                  child: Icon(
                                    isSaved ? Icons.favorite : Icons.favorite_border,
                                    color: isSaved ? Colors.redAccent : Colors.white,
                                    size: 16,
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      ],
                    ),

                    Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(shopName, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15, fontWeight: FontWeight.bold, height: 1.2)),
                          const SizedBox(height: 6),
                          Text(servicesStr, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12, height: 1.3)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 14),
                              const SizedBox(width: 4),
                              Text(rating, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 4),
                              Text("($reviews)", style: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontSize: 11)),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}