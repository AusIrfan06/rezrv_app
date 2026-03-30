import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../data/rezrv_data.dart';
import '../screens/booking_ticket_screen.dart';

class MyRezrvView extends StatefulWidget {
  const MyRezrvView({super.key});

  @override
  State<MyRezrvView> createState() => _MyRezrvViewState();
}

class _MyRezrvViewState extends State<MyRezrvView> {
  int _selectedTab = 0;

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
                "My Rezrv",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black,
                )
            ),
            const SizedBox(height: 24),

            // --- TAB BAR ---
            Container(
              height: 50,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[200],
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  _buildTabButton("Upcoming", 0, isDark),
                  _buildTabButton("History", 1, isDark),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- DYNAMIC CONTENT AREA ---
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _selectedTab == 0
                    ? ValueListenableBuilder<List<Map<String, dynamic>>>(
                  key: const ValueKey("upcoming"),
                  valueListenable: RezrvData.upcomingReservations,
                  builder: (context, upcomingList, child) {
                    return _buildListView(upcomingList, isDark, isHistory: false);
                  },
                )
                    : ValueListenableBuilder<List<Map<String, dynamic>>>(
                  key: const ValueKey("history"),
                  valueListenable: RezrvData.historyReservations,
                  builder: (context, historyList, child) {
                    return _buildListView(historyList, isDark, isHistory: true);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, int index, bool isDark) {
    bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? Colors.white.withOpacity(0.15) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected && !isDark ? [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
            ] : [],
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : Colors.black)
                    : (isDark ? Colors.white54 : Colors.black54),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListView(List<Map<String, dynamic>> items, bool isDark, {required bool isHistory}) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          isHistory ? "No past or cancelled reservations." : "No upcoming reservations yet.\nBook a service to see it here!",
          textAlign: TextAlign.center,
          style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, height: 1.5, fontSize: 15),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: isHistory
              ? _buildHistoryTicket(context, item, isDark)
              : _buildUpcomingTicket(context, item, isDark),
        );
      },
    );
  }

  Widget _buildUpcomingTicket(BuildContext context, Map<String, dynamic> item, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 70, height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(image: NetworkImage(item['img']), fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['category'].toUpperCase(), style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(item['title'], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                      const SizedBox(height: 4),
                      Text("${item['date']} • ${item['time']}", style: TextStyle(color: isDark ? Colors.white54 : Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
                  child: const HugeIcon(icon: HugeIcons.strokeRoundedQrCode01, color: Colors.blue, size: 24),
                )
              ],
            ),
          ),

          Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey[200]),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      RezrvData.cancelReservation(item["id"]);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16)
                      ),
                      child: const Center(child: Text("Cancel", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 🟢 FIXED: This now opens the new E-Ticket screen properly!
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                          builder: (_) => BookingTicketScreen(
                            shopName: item['title'] ?? "Shop Name",
                            category: item['category'] ?? "Service",
                            shopImage: item['img'] ?? "",
                            providerName: item['providerName'] ?? "Staff",
                            date: item['date'] ?? "Date",
                            time: item['time'] ?? "Time",
                            totalPrice: item['totalPrice'] ?? "RM0",
                            bookingId: item['id'] ?? "RZRV-0000",
                          ),
                        ),
                      );
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                      ),
                      child: const Center(child: Text("View Ticket", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHistoryTicket(BuildContext context, Map<String, dynamic> item, bool isDark) {
    bool isCancelled = item["status"] == "cancelled";

    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.02) : Colors.grey[100],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
              image: DecorationImage(
                image: NetworkImage(item['img']),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(isCancelled ? 0.6 : 0.3), BlendMode.darken),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['category'].toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                    item['title'],
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white54 : Colors.black87,
                      decoration: isCancelled ? TextDecoration.lineThrough : null,
                    )
                ),
                const SizedBox(height: 4),
                Text("${item['date']} • ${item['time']}", style: TextStyle(color: isDark ? Colors.white30 : Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: isCancelled ? Colors.redAccent.withOpacity(0.1) : (isDark ? Colors.white10 : Colors.grey[300]),
                  borderRadius: BorderRadius.circular(12)
              ),
              child: Text(
                  isCancelled ? "Cancelled" : "Done",
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.bold,
                      color: isCancelled ? Colors.redAccent : (isDark ? Colors.white54 : Colors.black54)
                  )
              ),
            ),
          ),
        ],
      ),
    );
  }
}