import 'package:flutter/material.dart';
import '../data/mock_market_data.dart';
import '../models/store_model.dart';
import '../services/auth_service.dart';
import '../services/market_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_asset_image.dart';
import 'browse_list_screen.dart';
import 'store_detail_screen.dart';

/// Bridges the two possible sources of a store card — the bundled mock
/// data (used when Firebase isn't configured, or Firestore is empty) and
/// real StoreModel docs from MarketService — into one shape the UI below
/// doesn't need to know or care about.
class _HomeStoreItem {
  final String? id;
  final String name;
  final String tag;
  final String category;
  final String rating;
  final String asset;
  final String? hours;
  final String? zone;
  final String? phone;
  final String? address;
  final String? description;

  const _HomeStoreItem({
    this.id,
    required this.name,
    required this.tag,
    required this.category,
    required this.rating,
    required this.asset,
    this.hours,
    this.zone,
    this.phone,
    this.address,
    this.description,
  });

  factory _HomeStoreItem.fromModel(StoreModel m) => _HomeStoreItem(
        id: m.id,
        name: m.name,
        tag: m.tag,
        category: m.category,
        rating: m.rating.toStringAsFixed(1),
        asset: m.asset,
        hours: m.hours,
        zone: m.zone,
        phone: m.phone,
        address: m.address,
        description: m.description,
      );

  factory _HomeStoreItem.fromMock(StoreListing s) => _HomeStoreItem(
      name: s.name,
      tag: s.tag,
      category: s.category,
      rating: s.rating,
      asset: s.asset);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Safe to call every time — it's a no-op once `stores` has any docs.
    // This is what turns an empty Firestore project into a populated demo
    // the first time someone with Firebase configured opens the app.
    if (AuthService.instance.isAvailable) {
      MarketService.instance.seedDemoDataIfEmpty();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final firstName = (user?.displayName?.isNotEmpty ?? false)
        ? user!.displayName!.split(' ').first
        : 'there';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryDark,
              backgroundImage: (user?.photoURL != null)
                  ? NetworkImage(user!.photoURL!)
                  : null,
              child: user?.photoURL == null
                  ? const Icon(Icons.person, color: Colors.white, size: 18)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Good to see you',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                  Text('Hi, $firstName 👋',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark)),
                ],
              ),
            ),
          ],
        ),
        // The only notification entry point on this screen — the Quick
        // Actions row below intentionally does NOT repeat it.
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded),
                onPressed: () =>
                    Navigator.of(context).pushNamed('/notifications'),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  height: 8,
                  width: 8,
                  decoration: const BoxDecoration(
                      color: AppColors.danger, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: AppColors.textSecondary, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Smart Search',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                Icon(Icons.tune_rounded,
                    color: AppColors.textSecondary, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Quick actions — shortcuts into the sections people jump to most.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _quickAction(context, Icons.bar_chart_rounded, 'Analytics',
                  () => Navigator.of(context).pushNamed('/analytics')),
              _quickAction(context, Icons.event_note_rounded, 'My Bookings',
                  () => Navigator.of(context).pushNamed('/calendar')),
              _quickAction(context, Icons.map_outlined, 'Market Map',
                  () => Navigator.of(context).pushNamed('/location')),
            ],
          ),
          const SizedBox(height: 22),

          // Market banner
          Stack(
            children: [
              SizedBox(
                height: 140,
                width: double.infinity,
                child: AppAssetImage(
                  assetPath: 'assets/images/market_banner.jpg',
                  fallbackIcon: Icons.storefront_rounded,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              Positioned(
                left: 16,
                bottom: 14,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(6)),
                      child: const Text('Open Now',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Text(
                        'ตลาดนัด การค้า',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Stores grid — live from Firestore when available, mock data
          // otherwise (offline, guest mode, or Firestore still empty).
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Stores List',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary)),
              GestureDetector(
                onTap: () => _openBrowseAll(context),
                child: const Text('See all',
                    style: TextStyle(fontSize: 12, color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _storesSection(context),
          const SizedBox(height: 22),

          // Popular now — still mock/event data; not backed by Firestore
          // yet, this is market-wide promo content rather than a vendor.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Popular Now',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary)),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BrowseListScreen(
                      title: 'Popular Now',
                      items: mockPopular
                          .map((p) => BrowseItem(
                              name: p.name,
                              sub: p.sub,
                              category: 'Weekend Market Event',
                              rating: '4.7',
                              asset: p.asset))
                          .toList(),
                    ),
                  ),
                ),
                child: const Text('See all',
                    style: TextStyle(fontSize: 12, color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: mockPopular.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final item = mockPopular[i];
                return SizedBox(
                  width: 170,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StoreDetailScreen(
                          name: item.name,
                          category: 'Weekend Market Event',
                          rating: '4.7',
                          asset: item.asset,
                        ),
                      ),
                    ),
                    child: Stack(
                      children: [
                        SizedBox(
                          height: 130,
                          width: 170,
                          child: AppAssetImage(
                            assetPath: item.asset,
                            fallbackIcon: Icons.storefront_rounded,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        Positioned(
                          left: 10,
                          right: 10,
                          bottom: 10,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5),
                              ),
                              Text(item.sub,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  void _openBrowseAll(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StreamBuilder<List<StoreModel>>(
          stream: MarketService.instance.storesStreamWithFallback(),
          builder: (context, snapshot) {
            final items = (snapshot.data ?? const [])
                .map((m) => BrowseItem(
                      id: m.id,
                      name: m.name,
                      sub: m.tag,
                      category: m.category,
                      rating: m.rating.toStringAsFixed(1),
                      asset: m.asset,
                      hours: m.hours,
                      zone: m.zone,
                      phone: m.phone,
                      address: m.address,
                      description: m.description,
                    ))
                .toList();
            return BrowseListScreen(title: 'All Stores', items: items);
          },
        ),
      ),
    );
  }

  Widget _storesSection(BuildContext context) {
    return StreamBuilder<List<StoreModel>>(
      stream: MarketService.instance.storesStreamWithFallback(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
              height: 90,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
        }
        final items =
            (snapshot.data ?? const []).map(_HomeStoreItem.fromModel).toList();
        return _storesGrid(context, items);
      },
    );
  }

  Widget _storesGrid(BuildContext context, List<_HomeStoreItem> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 12,
        childAspectRatio: 0.86,
      ),
      itemBuilder: (context, i) => _storeCard(context, items[i]),
    );
  }

  Widget _quickAction(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 76,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _storeCard(BuildContext context, _HomeStoreItem store) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StoreDetailScreen(
            id: store.id,
            name: store.name,
            category: store.category,
            rating: store.rating,
            asset: store.asset,
            hours: store.hours ?? '09:00 – 20:00',
            zone: store.zone ?? 'Zone A, Stall 2',
            phone: store.phone ?? '02-XXX-XXXX',
            address: store.address ?? 'Yuea Market Place, Zone A',
            description: store.description ??
                'A regular vendor at Yuea Market Place offering fresh, locally-sourced '
                    'goods every weekend. Known for consistent quality and friendly service — '
                    'a favorite stop for returning market visitors.',
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 90,
                width: double.infinity,
                child: AppAssetImage(
                  assetPath: store.asset,
                  fallbackIcon: Icons.storefront_rounded,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFFFC94A), size: 11),
                      const SizedBox(width: 2),
                      Text(store.rating,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(store.name,
              style:
                  const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(store.tag,
              style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
