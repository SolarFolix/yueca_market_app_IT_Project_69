import 'package:cloud_firestore/cloud_firestore.dart';

/// A vendor/store listing. Mirrors `lib/data/mock_market_data.dart`'s
/// StoreListing shape on purpose — screens that used the mock data barely
/// change when switching to this.
class StoreModel {
  final String id;
  final String name;
  final String tag; // short "Category • Zone" shown on cards
  final String category; // fuller description shown on the detail page
  final double rating;
  final String asset; // bundled fallback image (assets/images/...)
  final String? imageUrl; // remote photo once you're storing real photos
  final String zone;
  final String hours;
  final String phone;
  final String address;
  final String description;

  const StoreModel({
    required this.id,
    required this.name,
    required this.tag,
    required this.category,
    required this.rating,
    required this.asset,
    this.imageUrl,
    this.zone = 'Zone A',
    this.hours = '09:00 – 20:00',
    this.phone = '02-XXX-XXXX',
    this.address = 'Yuea Market Place',
    this.description =
        'A regular vendor at Yuea Market Place offering fresh, locally-sourced '
            'goods every weekend. Known for consistent quality and friendly service.',
  });

  factory StoreModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return StoreModel(
      id: doc.id,
      name: data['name'] ?? 'Unnamed Store',
      tag: data['tag'] ?? '',
      category: data['category'] ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 4.5,
      asset: data['asset'] ?? 'assets/images/store_1.jpg',
      imageUrl: data['imageUrl'],
      zone: data['zone'] ?? 'Zone A',
      hours: data['hours'] ?? '09:00 – 20:00',
      phone: data['phone'] ?? '02-XXX-XXXX',
      address: data['address'] ?? 'Yuea Market Place',
      description: data['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'tag': tag,
        'category': category,
        'rating': rating,
        'asset': asset,
        'imageUrl': imageUrl,
        'zone': zone,
        'hours': hours,
        'phone': phone,
        'address': address,
        'description': description,
      };
}
