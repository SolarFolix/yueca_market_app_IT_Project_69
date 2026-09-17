import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'notification_service.dart';
import '../data/mock_market_data.dart' as mock;
import '../models/store_model.dart';
import '../models/stall_model.dart';
import '../models/booking_model.dart';

/// All the market data that isn't about the user's own account:
/// stores, the stall grid, and bookings. Firestore-backed; screens should
/// check `AuthService.instance.isAvailable` before calling anything here
/// and fall back to `lib/data/mock_market_data.dart` when Firebase isn't
/// configured yet (same pattern used everywhere else in this app).
class MarketService {
  MarketService._internal();
  static final MarketService instance = MarketService._internal();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  static const List<String> stallRows = ['G', 'F', 'E', 'D', 'C', 'B', 'A'];
  static const List<String> stallCols = ['7', '6', '5', '4', '3', '2', '1'];

  // ---------------------------------------------------------------------
  // Stores
  // ---------------------------------------------------------------------

  Stream<List<StoreModel>> storesStream() {
    return _db.collection('stores').orderBy('name').snapshots().map(
          (snap) => snap.docs.map(StoreModel.fromDoc).toList(),
        );
  }

  List<StoreModel> _mockStores() => mock.mockStores
      .map((s) => StoreModel(id: s.name, name: s.name, tag: s.tag, category: s.category, rating: double.tryParse(s.rating) ?? 4.5, asset: s.asset))
      .toList();

  /// Same as [storesStream], but works with no Firebase configured (falls
  /// back to bundled mock data) and also falls back if Firestore hasn't
  /// been seeded yet or a rules problem makes the read fail — so the Home
  /// screen never shows an empty grid just because the backend isn't
  /// fully set up.
  Stream<List<StoreModel>> storesStreamWithFallback() async* {
    if (!AuthService.instance.isAvailable) {
      yield _mockStores();
      return;
    }
    try {
      yield* storesStream().map((list) => list.isEmpty ? _mockStores() : list);
    } catch (_) {
      yield _mockStores();
    }
  }

  // ---------------------------------------------------------------------
  // Stalls (the market grid)
  // ---------------------------------------------------------------------

  /// All 49 stall codes in grid order, regardless of whether a Firestore
  /// doc exists for each yet — used to render a full grid even right
  /// after seeding, or if a doc was never created.
  static List<String> allStallCodes() => [
        for (final r in stallRows) for (final c in stallCols) '$r$c',
      ];

  Stream<Map<String, StallModel>> stallsStream() {
    return _db.collection('stalls').snapshots().map((snap) {
      final map = <String, StallModel>{};
      for (final doc in snap.docs) {
        map[doc.id] = StallModel.fromDoc(doc);
      }
      return map;
    });
  }

  /// Same idea as [storesStreamWithFallback]: without Firebase configured,
  /// or before the grid has been seeded, shows the same realistic ~35%
  /// occupancy pattern the frontend used to hardcode — so the grid never
  /// looks broken or empty while the backend isn't fully set up.
  static const Set<String> _mockBooked = {
    'G3', 'G6', 'F1', 'F4', 'F5', 'E2', 'E6', 'D1', 'D3', 'D5',
    'C2', 'C4', 'C7', 'B1', 'B5', 'A2', 'A6',
  };

  Map<String, StallModel> _mockStalls() => {
        for (final code in allStallCodes()) code: StallModel(code: code, booked: _mockBooked.contains(code), storeName: _mockBooked.contains(code) ? 'Fresh Produce' : null),
      };

  Stream<Map<String, StallModel>> stallsStreamWithFallback() async* {
    if (!AuthService.instance.isAvailable) {
      yield _mockStalls();
      return;
    }
    try {
      yield* stallsStream().map((map) => map.isEmpty ? _mockStalls() : map);
    } catch (_) {
      yield _mockStalls();
    }
  }

  /// Books a stall for the given store, atomically. Runs inside a
  /// Firestore transaction so two people tapping "Rent" on the same stall
  /// at the same moment can't both succeed — whoever's transaction commits
  /// first wins, and the second one throws `stall-already-booked` instead
  /// of silently overwriting the first booking. This is the actual fix for
  /// double-booking, not just a UI-level check.
  Future<String> bookStall({
    required String code,
    required String storeName,
    required DateTime date,
    required double feeAmount,
  }) async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      throw StateError('Sign in to book a stall.');
    }

    final stallRef = _db.collection('stalls').doc(code);
    final bookingRef = _db.collection('bookings').doc();

    await _db.runTransaction((tx) async {
      final stallDoc = await tx.get(stallRef);
      final alreadyBooked = stallDoc.exists && stallDoc.data()?['booked'] == true;
      if (alreadyBooked) {
        throw StateError('stall-already-booked');
      }

      tx.set(stallRef, {
        'booked': true,
        'bookedByUid': user.uid,
        'storeName': storeName,
      });

      tx.set(bookingRef, {
        'uid': user.uid,
        'stallCode': code,
        'storeName': storeName,
        'date': Timestamp.fromDate(date),
        'feeAmount': feeAmount,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    // Best-effort — a booking still succeeds even if the notification
    // write fails (see NotificationService.create's doc comment).
    NotificationService.instance.create(
      iconKey: 'booking',
      title: 'Stall reserved',
      subtitle: 'You reserved stall $code at $storeName — complete payment to confirm.',
    );

    return bookingRef.id;
  }

  /// Releases a stall back to available — used when a pending booking is
  /// cancelled from the Payment screen instead of confirmed.
  Future<void> releaseStall(String code) {
    return _db.collection('stalls').doc(code).set({
      'booked': false,
      'bookedByUid': null,
      'storeName': null,
    });
  }

  // ---------------------------------------------------------------------
  // Bookings
  // ---------------------------------------------------------------------

  Stream<List<BookingModel>> myBookingsStream() {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return Stream.value([]);
    return _db
        .collection('bookings')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(BookingModel.fromDoc).toList());
  }

  Future<BookingModel?> getBooking(String bookingId) async {
    final doc = await _db.collection('bookings').doc(bookingId).get();
    if (!doc.exists) return null;
    return BookingModel.fromDoc(doc);
  }

  Future<void> confirmBooking(String bookingId) async {
    await _db.collection('bookings').doc(bookingId).update({'status': 'confirmed'});
    final booking = await getBooking(bookingId);
    if (booking != null) {
      NotificationService.instance.create(
        iconKey: 'payment',
        title: 'Booking confirmed',
        subtitle: 'Your slot ${booking.stallCode} at ${booking.storeName} is confirmed — ฿${booking.feeAmount.toStringAsFixed(0)} received.',
      );
    }
  }

  Future<void> cancelBooking(String bookingId, String stallCode) async {
    await _db.collection('bookings').doc(bookingId).update({'status': 'cancelled'});
    await releaseStall(stallCode);
  }

  // ---------------------------------------------------------------------
  // Demo seeding
  // ---------------------------------------------------------------------

  /// Populates `stores` and `stalls` from the bundled mock data, but only
  /// if `stores` is currently empty — safe to call every time the app
  /// starts. This solves the "Firestore starts completely empty" problem
  /// without needing a separate admin tool. Exposed as a button in
  /// Settings when Firebase is connected.
  Future<void> seedDemoDataIfEmpty() async {
    final existing = await _db.collection('stores').limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final batch = _db.batch();

    const seedStores = [
      {
        'name': 'Fresh Produce',
        'tag': 'Food • Zone A',
        'category': 'Fresh Produce & Groceries',
        'rating': 4.8,
        'asset': 'assets/images/store_1.jpg',
        'zone': 'Zone A, Stall 2',
      },
      {
        'name': 'Street Food Hub',
        'tag': 'Food • Zone B',
        'category': 'Street Food & Snacks',
        'rating': 4.6,
        'asset': 'assets/images/store_2.jpg',
        'zone': 'Zone B',
      },
      {
        'name': 'Handmade Crafts',
        'tag': 'Crafts • Zone C',
        'category': 'Handmade Crafts & Gifts',
        'rating': 4.9,
        'asset': 'assets/images/store_3.jpg',
        'zone': 'Zone C',
      },
      {
        'name': 'Vintage Finds',
        'tag': 'Fashion • Zone A',
        'category': 'Vintage Clothing & Accessories',
        'rating': 4.5,
        'asset': 'assets/images/store_4.jpg',
        'zone': 'Zone A',
      },
    ];
    for (final s in seedStores) {
      batch.set(_db.collection('stores').doc(), s);
    }

    // A realistic ~35% occupancy scattered across the grid, matching what
    // the frontend previously hardcoded — now it's real, shared data.
    const bookedSeed = {
      'G3', 'G6', 'F1', 'F4', 'F5', 'E2', 'E6', 'D1', 'D3', 'D5',
      'C2', 'C4', 'C7', 'B1', 'B5', 'A2', 'A6',
    };
    for (final code in allStallCodes()) {
      batch.set(_db.collection('stalls').doc(code), {
        'booked': bookedSeed.contains(code),
        'bookedByUid': null,
        'storeName': bookedSeed.contains(code) ? 'Fresh Produce' : null,
      });
    }

    await batch.commit();
  }
}
