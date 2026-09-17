import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_asset_image.dart';
import 'store_detail_screen.dart';

/// One card in a BrowseListScreen grid.
class BrowseItem {
  final String? id;
  final String name;
  final String sub;
  final String category;
  final String rating;
  final String asset;
  final String? hours;
  final String? zone;
  final String? phone;
  final String? address;
  final String? description;
  const BrowseItem({
    this.id,
    required this.name,
    required this.sub,
    required this.category,
    required this.rating,
    required this.asset,
    this.hours,
    this.zone,
    this.phone,
    this.address,
    this.description,
  });
}

/// Generic "See all" destination — used by both Home sections (Stores List
/// and Popular Now) so every "See all" tap leads somewhere real instead of
/// being a dead label.
class BrowseListScreen extends StatelessWidget {
  final String title;
  final List<BrowseItem> items;

  const BrowseListScreen({super.key, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => Navigator.of(context).pop()),
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 12,
          childAspectRatio: 0.86,
        ),
        itemBuilder: (context, i) {
          final item = items[i];
          return GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StoreDetailScreen(
                  id: item.id,
                  name: item.name,
                  category: item.category,
                  rating: item.rating,
                  asset: item.asset,
                  hours: item.hours ?? '09:00 – 20:00',
                  zone: item.zone ?? 'Zone A, Stall 2',
                  phone: item.phone ?? '02-XXX-XXXX',
                  address: item.address ?? 'Yuea Market Place, Zone A',
                  description: item.description ??
                      'A regular vendor at Yuea Market Place offering fresh, locally-sourced '
                          'goods every weekend. Known for consistent quality and friendly service — '
                          'a favorite stop for returning market visitors.',
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 90,
                  width: double.infinity,
                  child: AppAssetImage(assetPath: item.asset, fallbackIcon: Icons.storefront_rounded, borderRadius: BorderRadius.circular(14)),
                ),
                const SizedBox(height: 6),
                Text(item.name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(item.sub, style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          );
        },
      ),
    );
  }
}
