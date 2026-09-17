import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_asset_image.dart';
import 'market_selection_screen.dart';

/// Shown when a user taps a store from Home — this is the store's actual
/// profile (photo, description, hours, location) rather than dropping
/// them straight into the stall-selection grid. "Book a Stall" is the
/// only thing on this page that leads into booking.
class StoreDetailScreen extends StatelessWidget {
  final String? id;
  final String name;
  final String category;
  final String rating;
  final String asset;
  final String hours;
  final String zone;
  final String phone;
  final String address;
  final String description;

  const StoreDetailScreen({
    super.key,
    this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.asset,
    this.hours = '09:00 – 20:00',
    this.zone = 'Zone A, Stall 2',
    this.phone = '02-XXX-XXXX',
    this.address = 'Yuea Market Place, Zone A',
    this.description =
        'A regular vendor at Yuea Market Place offering fresh, locally-sourced '
            'goods every weekend. Known for consistent quality and friendly service — '
            'a favorite stop for returning market visitors.',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.4),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.4),
                  child: const Icon(Icons.favorite_border_rounded, size: 16, color: Colors.white),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: AppAssetImage(assetPath: asset, fallbackIcon: Icons.storefront_rounded),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(name, style: AppTextStyles.heading)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFFFC94A), size: 14),
                            const SizedBox(width: 3),
                            Text(rating, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(category, style: AppTextStyles.subheading),
                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(child: _infoTile(Icons.schedule_rounded, 'Open Hours', hours)),
                      const SizedBox(width: 10),
                      Expanded(child: _infoTile(Icons.location_on_outlined, 'Zone', zone)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  const Text('About', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 20),

                  const Text('Contact', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 10),
                  _contactRow(Icons.call_outlined, phone),
                  const SizedBox(height: 8),
                  _contactRow(Icons.place_outlined, address),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => MarketSelectionScreen(storeName: name)),
                      ),
                      child: const Text('Book a Stall'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(text, style: TextStyle(fontSize: 12.5, color: AppColors.textPrimary)),
      ],
    );
  }
}
