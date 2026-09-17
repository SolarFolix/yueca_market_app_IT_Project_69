/// A single vendor/store listing. Shared between the Home screen and the
/// "See all" browse screen so both stay in sync from one source of truth.
/// Swap `mockStores` for a real Firestore query later — nothing else needs
/// to change since screens only depend on this shape.
class StoreListing {
  final String name;
  final String tag; // short "Category • Zone" shown on cards
  final String category; // full description shown on the detail page
  final String rating;
  final String asset;

  const StoreListing({
    required this.name,
    required this.tag,
    required this.category,
    required this.rating,
    required this.asset,
  });
}

const List<StoreListing> mockStores = [
  StoreListing(
    name: 'Fresh Produce',
    tag: 'Food • Zone A',
    category: 'Fresh Produce & Groceries',
    rating: '4.8',
    asset: 'assets/images/store_1.jpg',
  ),
  StoreListing(
    name: 'Street Food Hub',
    tag: 'Food • Zone B',
    category: 'Street Food & Snacks',
    rating: '4.6',
    asset: 'assets/images/store_2.jpg',
  ),
  StoreListing(
    name: 'Handmade Crafts',
    tag: 'Crafts • Zone C',
    category: 'Handmade Crafts & Gifts',
    rating: '4.9',
    asset: 'assets/images/store_3.jpg',
  ),
  StoreListing(
    name: 'Vintage Finds',
    tag: 'Fashion • Zone A',
    category: 'Vintage Clothing & Accessories',
    rating: '4.5',
    asset: 'assets/images/store_4.jpg',
  ),
];

/// A market-wide event/promotion (not a single vendor).
class PopularListing {
  final String name;
  final String sub;
  final String asset;

  const PopularListing({required this.name, required this.sub, required this.asset});
}

const List<PopularListing> mockPopular = [
  PopularListing(name: 'Sunday Night Market', sub: 'Open until 22:00', asset: 'assets/images/popular_1.jpg'),
  PopularListing(name: 'Riverside Bazaar', sub: '250m away', asset: 'assets/images/popular_2.jpg'),
  PopularListing(name: 'Art & Craft Fair', sub: 'This weekend', asset: 'assets/images/popular_3.jpg'),
];
