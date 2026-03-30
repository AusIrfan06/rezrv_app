import 'package:flutter/material.dart';
import '../screens/detail_screen.dart';
import '../data/shop_data.dart'; // 🟢 IMPORTANT: Import your shop data

class SavedView extends StatelessWidget {
  const SavedView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
                "My Saved Spots",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black,
                )
            ),
            const SizedBox(height: 24),

            // 🟢 NEW: This listens to the broadcaster and builds the grid live
            Expanded(
              child: ValueListenableBuilder<Set<String>>(
                valueListenable: ShopData.savedShopNames,
                builder: (context, savedNames, child) {
                  // Filter the shops to only show the saved ones
                  final List<Map<String, dynamic>> savedSpots = ShopData.shops
                      .where((shop) => savedNames.contains(shop['name']))
                      .toList();

                  // Empty State
                  if (savedSpots.isEmpty) {
                    return Center(
                      child: Text(
                        "You haven't saved any spots yet.",
                        style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 16),
                      ),
                    );
                  }

                  // Populated Grid
                  return GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.75
                      ),
                      itemCount: savedSpots.length,
                      itemBuilder: (context, index) {
                        return _buildSavedCard(context, savedSpots[index], isDark);
                      }
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🟢 Takes the full 'shop' object and builds the card
  Widget _buildSavedCard(BuildContext context, Map<String, dynamic> shop, bool isDark) {
    final String title = shop["name"] ?? "Unknown";
    final String category = shop["category"]?.toString().toUpperCase() ?? "GENERAL";
    final String img = shop["image"] ?? "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=400";

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ReservationDetailScreen(
                  title: title,
                  category: category,
                  imageUrl: img
              )
          )
      ),
      child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              image: DecorationImage(image: NetworkImage(img), fit: BoxFit.cover)
          ),
          child: Stack(
              children: [
                Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withOpacity(0.7)]
                        )
                    )
                ),

                // 🟢 UNLIKE BUTTON: Instantly removes from global state
                Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () {
                        final currentSet = Set<String>.from(ShopData.savedShopNames.value);
                        currentSet.remove(title);
                        ShopData.savedShopNames.value = currentSet; // Broadcasts removal
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
                          child: const Icon(Icons.favorite, color: Colors.redAccent, size: 18)
                      ),
                    )
                ),

                Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              category,
                              style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)
                          ),
                          const SizedBox(height: 4),
                          Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, height: 1.2)
                          )
                        ]
                    )
                )
              ]
          )
      ),
    );
  }
}