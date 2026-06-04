import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/application_model.dart';
import '../models/booth_package_model.dart';
import '../models/booth_spot_model.dart';
import '../models/exhibition_model.dart';
import '../models/user_model.dart';

class DatabaseSeeder {
  DatabaseSeeder._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _seedTag = 'boothify_seed';
  static const String _seedPassword = '12345678';

  static Future<void> seedLargeDemoData({
    bool clearExistingSeedData = true,
  }) async {
    final now = DateTime.now();

    final userInputs = _buildSeedUserInputs();

    // Create real Firebase Auth accounts only for demo login users.
    final authUsers = <_SeedAuthUser>[];

    for (int i = 0; i < userInputs.length; i++) {
      final input = userInputs[i];

      final shouldCreateAuthAccount =
          input.email == 'admin@boothify.io' ||
          input.email == 'organizer.aisyah@gmail.com' ||
          input.email == 'organizer.danial@gmail.com' ||
          input.email == 'exhibitor.nexatech@gmail.com' ||
          input.email == 'exhibitor.greenbite@gmail.com';

      if (shouldCreateAuthAccount) {
        final firebaseUser = await _createOrSignInSeedAuthUser(
          email: input.email,
          password: _seedPassword,
          displayName: input.name,
        );

        authUsers.add(_SeedAuthUser(uid: firebaseUser.uid, input: input));
      } else {
        authUsers.add(
          _SeedAuthUser(
            uid: 'seed_user_${(i + 1).toString().padLeft(3, '0')}',
            input: input,
          ),
        );
      }
    }

    if (clearExistingSeedData) {
      await clearSeedData();
    }

    final exhibitionIds = List.generate(
      8,
      (index) => 'seed_exhibition_${(index + 1).toString().padLeft(2, '0')}',
    );

    final users = <UserModel>[];
    final organizerIds = <String>[];

    int exhibitorIndex = 0;

    for (final authUser in authUsers) {
      final favoriteIds = authUser.input.role == 'Exhibitor'
          ? [
              exhibitionIds[exhibitorIndex % exhibitionIds.length],
              exhibitionIds[(exhibitorIndex + 3) % exhibitionIds.length],
            ]
          : <String>[];

      final user = authUser.input.toUserModel(
        uid: authUser.uid,
        now: now,
        favoriteExhibitionIds: favoriteIds,
        profileIndex: exhibitorIndex,
      );

      users.add(user);

      if (user.role == 'Organizer') {
        organizerIds.add(user.uid);
      }

      if (user.role == 'Exhibitor') {
        exhibitorIndex++;
      }
    }

    final exhibitions = _buildExhibitions(
      now: now,
      organizerIds: organizerIds,
      exhibitionIds: exhibitionIds,
    );

    final boothPackages = _buildBoothPackages(
      now: now,
      exhibitionIds: exhibitionIds,
    );

    final boothSpots = _buildBoothSpots(
      now: now,
      exhibitionIds: exhibitionIds,
      boothPackages: boothPackages,
    );

    final applications = _buildApplications(
      now: now,
      exhibitors: users.where((user) => user.role == 'Exhibitor').toList(),
      exhibitions: exhibitions,
      boothSpots: boothSpots,
    );

    final writes = <_SeedWrite>[];

    for (final user in users) {
      writes.add(
        _SeedWrite(
          ref: _firestore.collection('users').doc(user.uid),
          data: _withSeedTag(user.toMap()),
        ),
      );
    }

    for (final exhibition in exhibitions) {
      writes.add(
        _SeedWrite(
          ref: _firestore.collection('exhibitions').doc(exhibition.id),
          data: _withSeedTag(exhibition.toMap()),
        ),
      );
    }

    for (final booth in boothPackages) {
      writes.add(
        _SeedWrite(
          ref: _firestore.collection('booth_packages').doc(booth.id),
          data: _withSeedTag(booth.toMap()),
        ),
      );
    }

    for (final spot in boothSpots) {
      writes.add(
        _SeedWrite(
          ref: _firestore.collection('booth_spots').doc(spot.id),
          data: _withSeedTag(spot.toMap()),
        ),
      );
    }

    for (final application in applications) {
      writes.add(
        _SeedWrite(
          ref: _firestore.collection('applications').doc(application.id),
          data: _withSeedTag(application.toMap()),
        ),
      );
    }

    await _commitWrites(writes);

    await _auth.signOut();

    // ignore: avoid_print
    print('Large demo seed completed.');
    // ignore: avoid_print
    print('Default password: $_seedPassword');
    // ignore: avoid_print
    print('Users: ${users.length}');
    // ignore: avoid_print
    print('Exhibitions: ${exhibitions.length}');
    // ignore: avoid_print
    print('Booth packages: ${boothPackages.length}');
    // ignore: avoid_print
    print('Booth spots: ${boothSpots.length}');
    // ignore: avoid_print
    print('Applications: ${applications.length}');
  }

  static Future<void> clearSeedData() async {
    final collections = [
      'applications',
      'booth_spots',
      'booth_packages',
      'exhibitions',
      'users',
    ];

    for (final collection in collections) {
      final snapshot = await _firestore
          .collection(collection)
          .where('seedTag', isEqualTo: _seedTag)
          .get();

      final refs = snapshot.docs.map((doc) => doc.reference).toList();

      await _commitDeletes(refs);
    }

    // ignore: avoid_print
    print('Existing seed data cleared.');
  }

  static Future<User> _createOrSignInSeedAuthUser({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user?.updateDisplayName(displayName);

      return credential.user!;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        final credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        await credential.user?.updateDisplayName(displayName);

        return credential.user!;
      }

      rethrow;
    }
  }

  static List<_SeedUserInput> _buildSeedUserInputs() {
    return const [
      _SeedUserInput(
        name: 'Boothify Admin',
        email: 'admin@boothify.io',
        role: 'Admin',
        phone: '+60120000001',
      ),

      // Organizers: 6 users.
      _SeedUserInput(
        name: 'Aisyah Rahman',
        email: 'organizer.aisyah@gmail.com',
        role: 'Organizer',
        organizationName: 'KL Expo Management',
        phone: '+60130000001',
      ),
      _SeedUserInput(
        name: 'Danial Hakim',
        email: 'organizer.danial@gmail.com',
        role: 'Organizer',
        organizationName: 'MATRADE Event Group',
        phone: '+60130000002',
      ),
      _SeedUserInput(
        name: 'Sofia Zainal',
        email: 'organizer.sofia@gmail.com',
        role: 'Organizer',
        organizationName: 'Penang Convention Team',
        phone: '+60130000003',
      ),
      _SeedUserInput(
        name: 'Imran Yusof',
        email: 'organizer.imran@gmail.com',
        role: 'Organizer',
        organizationName: 'Johor Event Network',
        phone: '+60130000004',
      ),
      _SeedUserInput(
        name: 'Mira Hassan',
        email: 'organizer.mira@gmail.com',
        role: 'Organizer',
        organizationName: 'Sabah Trade Organizer',
        phone: '+60130000005',
      ),
      _SeedUserInput(
        name: 'Farhan Iskandar',
        email: 'organizer.farhan@gmail.com',
        role: 'Organizer',
        organizationName: 'Sarawak Business Expo',
        phone: '+60130000006',
      ),

      // Exhibitors: 13 users.
      _SeedUserInput(
        name: 'Adam Lim',
        email: 'exhibitor.nexatech@gmail.com',
        role: 'Exhibitor',
        companyName: 'NexaTech Solutions',
        businessType: 'Technology',
        productCategory: 'Workflow Automation',
        phone: '+60140000001',
      ),
      _SeedUserInput(
        name: 'Sarah Tan',
        email: 'exhibitor.greenbite@gmail.com',
        role: 'Exhibitor',
        companyName: 'GreenBite Foods',
        businessType: 'Food & Beverage',
        productCategory: 'Organic Food',
        phone: '+60140000002',
      ),
      _SeedUserInput(
        name: 'Aina Khalid',
        email: 'exhibitor.modavista@gmail.com',
        role: 'Exhibitor',
        companyName: 'ModaVista Apparel',
        businessType: 'Fashion',
        productCategory: 'Modest Clothing',
        phone: '+60140000003',
      ),
      _SeedUserInput(
        name: 'Jason Wong',
        email: 'exhibitor.eduspark@gmail.com',
        role: 'Exhibitor',
        companyName: 'EduSpark Academy',
        businessType: 'Education',
        productCategory: 'Learning Services',
        phone: '+60140000004',
      ),
      _SeedUserInput(
        name: 'Nurul Iman',
        email: 'exhibitor.healthplus@gmail.com',
        role: 'Exhibitor',
        companyName: 'HealthPlus Care',
        businessType: 'Healthcare',
        productCategory: 'Wellness Products',
        phone: '+60140000005',
      ),
      _SeedUserInput(
        name: 'Brandon Lee',
        email: 'exhibitor.ecohome@gmail.com',
        role: 'Exhibitor',
        companyName: 'EcoHome Living',
        businessType: 'Home & Living',
        productCategory: 'Eco Products',
        phone: '+60140000006',
      ),
      _SeedUserInput(
        name: 'Hannah Teo',
        email: 'exhibitor.autonova@gmail.com',
        role: 'Exhibitor',
        companyName: 'AutoNova Parts',
        businessType: 'Automotive',
        productCategory: 'Car Accessories',
        phone: '+60140000007',
      ),
      _SeedUserInput(
        name: 'Iqbal Faiz',
        email: 'exhibitor.pixelcraft@gmail.com',
        role: 'Exhibitor',
        companyName: 'PixelCraft Studio',
        businessType: 'Creative',
        productCategory: 'Digital Design',
        phone: '+60140000008',
      ),
      _SeedUserInput(
        name: 'Melissa Chan',
        email: 'exhibitor.beantrail@gmail.com',
        role: 'Exhibitor',
        companyName: 'BeanTrail Coffee',
        businessType: 'Food & Beverage',
        productCategory: 'Coffee Products',
        phone: '+60140000009',
      ),
      _SeedUserInput(
        name: 'Faris Nordin',
        email: 'exhibitor.smartagro@gmail.com',
        role: 'Exhibitor',
        companyName: 'SmartAgro MY',
        businessType: 'Agriculture',
        productCategory: 'Smart Farming',
        phone: '+60140000010',
      ),
      _SeedUserInput(
        name: 'Priya Menon',
        email: 'exhibitor.urbanfit@gmail.com',
        role: 'Exhibitor',
        companyName: 'UrbanFit Gear',
        businessType: 'Sports',
        productCategory: 'Fitness Equipment',
        phone: '+60140000011',
      ),
      _SeedUserInput(
        name: 'Ethan Goh',
        email: 'exhibitor.cloudsync@gmail.com',
        role: 'Exhibitor',
        companyName: 'CloudSync Systems',
        businessType: 'Technology',
        productCategory: 'Cloud Services',
        phone: '+60140000012',
      ),
      _SeedUserInput(
        name: 'Yasmin Salleh',
        email: 'exhibitor.littlebloom@gmail.com',
        role: 'Exhibitor',
        companyName: 'LittleBloom Kids',
        businessType: 'Retail',
        productCategory: 'Kids Products',
        phone: '+60140000013',
      ),
    ];
  }

  static List<ExhibitionModel> _buildExhibitions({
    required DateTime now,
    required List<String> organizerIds,
    required List<String> exhibitionIds,
  }) {
    final data = [
      _SeedExhibitionInput(
        name: 'Malaysia Tech & Innovation Expo 2026',
        location: 'Kuala Lumpur Convention Centre',
        category: 'Technology',
        eventType: 'Trade Exhibition',
        startOffsetDays: -1,
        durationDays: 5,
        isPublished: true,
        isBookingOpen: true,
        expectedVisitors: '12,000+',
        contactEmail: 'tech.expo.my@gmail.com',
      ),
      _SeedExhibitionInput(
        name: 'Selangor Food & Lifestyle Fair',
        location: 'Setia City Convention Centre',
        category: 'Food & Beverage',
        eventType: 'Consumer Fair',
        startOffsetDays: -2,
        durationDays: 6,
        isPublished: true,
        isBookingOpen: true,
        expectedVisitors: '8,500+',
        contactEmail: 'food.lifestyle.fair@gmail.com',
      ),
      _SeedExhibitionInput(
        name: 'Penang Education & Career Expo',
        location: 'SPICE Convention Centre, Penang',
        category: 'Education',
        eventType: 'Career Fair',
        startOffsetDays: -3,
        durationDays: 7,
        isPublished: true,
        isBookingOpen: true,
        expectedVisitors: '10,000+',
        contactEmail: 'penang.education.expo@gmail.com',
      ),
      _SeedExhibitionInput(
        name: 'Johor Smart Business Showcase',
        location: 'Persada Johor International Convention Centre',
        category: 'Business',
        eventType: 'Business Expo',
        startOffsetDays: -1,
        durationDays: 4,
        isPublished: true,
        isBookingOpen: true,
        expectedVisitors: '7,000+',
        contactEmail: 'johor.business.showcase@gmail.com',
      ),
      _SeedExhibitionInput(
        name: 'Sabah Tourism & Culture Expo',
        location: 'Sabah International Convention Centre',
        category: 'Tourism',
        eventType: 'Public Expo',
        startOffsetDays: -4,
        durationDays: 8,
        isPublished: true,
        isBookingOpen: false,
        expectedVisitors: '9,200+',
        contactEmail: 'sabah.tourism.expo@gmail.com',
      ),
      _SeedExhibitionInput(
        name: 'Sarawak Green Energy Forum',
        location: 'Borneo Convention Centre Kuching',
        category: 'Energy',
        eventType: 'Conference Expo',
        startOffsetDays: 14,
        durationDays: 3,
        isPublished: true,
        isBookingOpen: true,
        expectedVisitors: '5,500+',
        contactEmail: 'sarawak.energy.forum@gmail.com',
      ),
      _SeedExhibitionInput(
        name: 'Cyberjaya Startup Demo Day',
        location: 'Cyberview Resort Convention Hall',
        category: 'Startup',
        eventType: 'Startup Showcase',
        startOffsetDays: -2,
        durationDays: 5,
        isPublished: true,
        isBookingOpen: true,
        expectedVisitors: '3,000+',
        contactEmail: 'cyberjaya.startup.day@gmail.com',
      ),
      _SeedExhibitionInput(
        name: 'Melaka Heritage Craft Market',
        location: 'Melaka International Trade Centre',
        category: 'Craft',
        eventType: 'Market Fair',
        startOffsetDays: 28,
        durationDays: 4,
        isPublished: true,
        isBookingOpen: true,
        expectedVisitors: '4,800+',
        contactEmail: 'melaka.craft.market@gmail.com',
      ),
    ];

    return List.generate(data.length, (index) {
      final input = data[index];
      final startDate = DateTime(
        now.year,
        now.month,
        now.day,
        10,
      ).add(Duration(days: input.startOffsetDays));

      final endDate = startDate.add(Duration(days: input.durationDays));

      return ExhibitionModel(
        id: exhibitionIds[index],
        organizerId: organizerIds[index % organizerIds.length],
        name: input.name,
        location: input.location,
        description:
            '${input.name} brings together exhibitors, visitors, and industry partners for product showcases, business networking, live demonstrations, and market discovery.',
        startDate: startDate,
        endDate: endDate,
        isPublished: input.isPublished,
        isBookingOpen: input.isBookingOpen,
        category: input.category,
        eventType: input.eventType,
        contactEmail: input.contactEmail,
        contactPhone: '+603${(80000000 + index).toString()}',
        openingHours: '10:00 AM - 8:00 PM',
        expectedVisitors: input.expectedVisitors,
        imageUrls: const [],
        layoutRows: 4,
        layoutColumns: 5,
        createdAt: now.subtract(Duration(days: 70 - index)),
        updatedAt: now.subtract(Duration(days: index)),
      );
    });
  }

  static List<BoothPackageModel> _buildBoothPackages({
    required DateTime now,
    required List<String> exhibitionIds,
  }) {
    final templates = [
      _SeedBoothPackageInput(
        name: 'Standard Booth',
        size: '3m x 3m',
        price: 1800,
        amenities: ['Table', '2 Chairs', 'Power Socket', 'Name Board'],
      ),
      _SeedBoothPackageInput(
        name: 'Premium Booth',
        size: '6m x 3m',
        price: 3200,
        amenities: [
          'Table',
          '4 Chairs',
          'Power Socket',
          'Premium Location',
          'LED Fascia',
        ],
      ),
      _SeedBoothPackageInput(
        name: 'Corner Booth',
        size: '4m x 4m',
        price: 4200,
        amenities: [
          'Corner Access',
          'Display Lighting',
          'Storage Space',
          'Power Socket',
        ],
      ),
      _SeedBoothPackageInput(
        name: 'Food Booth',
        size: '5m x 4m',
        price: 5000,
        amenities: [
          'Water Point',
          'Power Socket',
          'Waste Area',
          'Preparation Counter',
        ],
      ),
    ];

    final boothPackages = <BoothPackageModel>[];

    for (final exhibitionId in exhibitionIds) {
      for (int i = 0; i < templates.length; i++) {
        final template = templates[i];

        boothPackages.add(
          BoothPackageModel(
            id: '${exhibitionId}_package_${i + 1}',
            exhibitionId: exhibitionId,
            name: template.name,
            size: template.size,
            price: template.price,
            amenities: template.amenities,
            createdAt: now.subtract(Duration(days: 40 - i)),
          ),
        );
      }
    }

    return boothPackages;
  }

  static List<BoothSpotModel> _buildBoothSpots({
    required DateTime now,
    required List<String> exhibitionIds,
    required List<BoothPackageModel> boothPackages,
  }) {
    final spots = <BoothSpotModel>[];

    for (
      int exhibitionIndex = 0;
      exhibitionIndex < exhibitionIds.length;
      exhibitionIndex++
    ) {
      final exhibitionId = exhibitionIds[exhibitionIndex];

      final packages = boothPackages
          .where((booth) => booth.exhibitionId == exhibitionId)
          .toList();

      final statusPlan = _naturalSpotStatusPlan(exhibitionIndex);

      for (int row = 0; row < 4; row++) {
        final rowLetter = String.fromCharCode('A'.codeUnitAt(0) + row);

        for (int column = 1; column <= 5; column++) {
          final spotNumber = '$rowLetter${column.toString().padLeft(2, '0')}';

          // Spread booth package types naturally across the floor plan.
          final packageIndex =
              ((row * 2) + column + exhibitionIndex) % packages.length;

          spots.add(
            BoothSpotModel(
              id: '${exhibitionId}_spot_$spotNumber',
              exhibitionId: exhibitionId,
              boothPackageId: packages[packageIndex].id,
              spotNumber: spotNumber,
              status: statusPlan[spotNumber] ?? 'Available',
              createdAt: now.subtract(
                Duration(days: 35 - row, hours: column + exhibitionIndex),
              ),
            ),
          );
        }
      }
    }

    return spots;
  }

  static List<ApplicationModel> _buildApplications({
    required DateTime now,
    required List<UserModel> exhibitors,
    required List<ExhibitionModel> exhibitions,
    required List<BoothSpotModel> boothSpots,
  }) {
    final applications = <ApplicationModel>[];
    final rng = Random(2026);

    int appCounter = 1;
    int exhibitorCursor = 0;

    final productNames = [
      'AI Booking Assistant',
      'Organic Meal Box',
      'Modest Wear Collection',
      'Career Learning Bundle',
      'Wellness Screening Kit',
      'Eco Home Starter Pack',
      'Smart Car Accessory Kit',
      'Brand Identity Package',
      'Premium Coffee Beans',
      'Smart Farming Sensor',
      'Fitness Training Gear',
      'Cloud Backup Platform',
      'Educational Toy Set',
    ];

    for (final exhibition in exhibitions) {
      final spots = boothSpots
          .where((spot) => spot.exhibitionId == exhibition.id)
          .toList();

      final activeSpots =
          spots
              .where(
                (spot) => spot.status == 'Booked' || spot.status == 'Pending',
              )
              .toList()
            ..shuffle(rng);

      final inactiveSpots =
          spots.where((spot) => spot.status == 'Available').toList()
            ..shuffle(rng);

      final activeBusinessBySpot = <String, String>{};

      for (int i = 0; i < activeSpots.length; i++) {
        final spot = activeSpots[i];

        final status = spot.status == 'Pending'
            ? 'Pending'
            : _activeApplicationStatus(i);

        final exhibitorIndex = _findValidExhibitorIndex(
          exhibitors: exhibitors,
          startIndex: exhibitorCursor,
          spotNumber: spot.spotNumber,
          activeBusinessBySpot: activeBusinessBySpot,
        );

        final exhibitor = exhibitors[exhibitorIndex];
        final datePair = _randomApplicationDates(now, rng);

        applications.add(
          _createApplication(
            id: 'seed_application_${appCounter.toString().padLeft(3, '0')}',
            status: status,
            spot: spot,
            exhibition: exhibition,
            exhibitor: exhibitor,
            productName: productNames[exhibitorCursor % productNames.length],
            createdAt: datePair.createdAt,
            updatedAt: datePair.updatedAt,
            paidAt: status == 'Paid'
                ? datePair.updatedAt.add(Duration(hours: 2 + rng.nextInt(12)))
                : null,
          ),
        );

        activeBusinessBySpot[spot.spotNumber] =
            exhibitor.businessType ?? 'General';

        appCounter++;
        exhibitorCursor = exhibitorIndex + 1;
      }

      // Rejected and cancelled applications do not lock the booth.
      final inactiveApplicationCount = min(4, inactiveSpots.length);

      for (int i = 0; i < inactiveApplicationCount; i++) {
        final spot = inactiveSpots[i];
        final exhibitor = exhibitors[exhibitorCursor % exhibitors.length];
        final status = rng.nextBool() ? 'Rejected' : 'Cancelled';
        final datePair = _randomApplicationDates(now, rng);

        applications.add(
          _createApplication(
            id: 'seed_application_${appCounter.toString().padLeft(3, '0')}',
            status: status,
            spot: spot,
            exhibition: exhibition,
            exhibitor: exhibitor,
            productName: productNames[exhibitorCursor % productNames.length],
            createdAt: datePair.createdAt,
            updatedAt: datePair.updatedAt,
            rejectReason: status == 'Rejected'
                ? _rejectReasons[rng.nextInt(_rejectReasons.length)]
                : null,
          ),
        );

        appCounter++;
        exhibitorCursor++;
      }
    }

    // Make Firestore insertion order look less artificial.
    applications.shuffle(rng);

    return applications;
  }

  static Map<String, String> _naturalSpotStatusPlan(int exhibitionIndex) {
    final plans = [
      {
        'A01': 'Booked',
        'A04': 'Pending',
        'B02': 'Booked',
        'B05': 'Booked',
        'C01': 'Pending',
        'C03': 'Booked',
        'C05': 'Pending',
        'D02': 'Booked',
        'D04': 'Pending',
        'A03': 'Booked',
        'B04': 'Pending',
      },
      {
        'A02': 'Pending',
        'A05': 'Booked',
        'B01': 'Booked',
        'B03': 'Pending',
        'C02': 'Booked',
        'C04': 'Booked',
        'D01': 'Pending',
        'D03': 'Booked',
        'D05': 'Pending',
        'A04': 'Booked',
        'B05': 'Pending',
      },
      {
        'A01': 'Pending',
        'A03': 'Booked',
        'B02': 'Pending',
        'B04': 'Booked',
        'C01': 'Booked',
        'C03': 'Pending',
        'C05': 'Booked',
        'D02': 'Booked',
        'D04': 'Pending',
        'A05': 'Booked',
        'B01': 'Pending',
      },
    ];

    return plans[exhibitionIndex % plans.length];
  }

  static String _activeApplicationStatus(int index) {
    if (index % 4 == 0) return 'Paid';
    if (index % 3 == 0) return 'Paid';
    return 'Approved';
  }

  static int _findValidExhibitorIndex({
    required List<UserModel> exhibitors,
    required int startIndex,
    required String spotNumber,
    required Map<String, String> activeBusinessBySpot,
  }) {
    for (int attempt = 0; attempt < exhibitors.length; attempt++) {
      final index = (startIndex + attempt) % exhibitors.length;
      final exhibitor = exhibitors[index];
      final businessType = exhibitor.businessType ?? 'General';

      final hasConflict = _hasNearbySameBusinessType(
        spotNumber: spotNumber,
        businessType: businessType,
        activeBusinessBySpot: activeBusinessBySpot,
      );

      if (!hasConflict) return index;
    }

    return startIndex % exhibitors.length;
  }

  static bool _hasNearbySameBusinessType({
    required String spotNumber,
    required String businessType,
    required Map<String, String> activeBusinessBySpot,
  }) {
    for (final entry in activeBusinessBySpot.entries) {
      final existingSpotNumber = entry.key;
      final existingBusinessType = entry.value;

      if (existingBusinessType == businessType &&
          _isAdjacentSpot(spotNumber, existingSpotNumber)) {
        return true;
      }
    }

    return false;
  }

  static bool _isAdjacentSpot(String spot1, String spot2) {
    if (spot1.length < 2 || spot2.length < 2) return false;

    final row1 = spot1[0].toUpperCase().codeUnitAt(0);
    final row2 = spot2[0].toUpperCase().codeUnitAt(0);

    final col1 = int.tryParse(spot1.substring(1));
    final col2 = int.tryParse(spot2.substring(1));

    if (col1 == null || col2 == null) return false;

    final rowDiff = (row1 - row2).abs();
    final colDiff = (col1 - col2).abs();

    return (rowDiff == 0 && colDiff == 1) || (rowDiff == 1 && colDiff == 0);
  }

  static _SeedDatePair _randomApplicationDates(DateTime now, Random rng) {
    final updatedDaysAgo = 1 + rng.nextInt(28);
    final createdDaysAgo = updatedDaysAgo + 1 + rng.nextInt(18);

    final createdAt = now.subtract(
      Duration(
        days: createdDaysAgo,
        hours: rng.nextInt(12),
        minutes: rng.nextInt(60),
      ),
    );

    final updatedAt = now.subtract(
      Duration(
        days: updatedDaysAgo,
        hours: rng.nextInt(12),
        minutes: rng.nextInt(60),
      ),
    );

    return _SeedDatePair(createdAt: createdAt, updatedAt: updatedAt);
  }

  static ApplicationModel _createApplication({
    required String id,
    required String status,
    required BoothSpotModel spot,
    required ExhibitionModel exhibition,
    required UserModel exhibitor,
    required String productName,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? paidAt,
    String? rejectReason,
  }) {
    final companyName = exhibitor.companyName ?? exhibitor.name;
    final businessType = exhibitor.businessType ?? 'General';

    return ApplicationModel(
      id: id,
      userId: exhibitor.uid,
      exhibitionId: exhibition.id,
      boothSpotId: spot.id,
      boothNumber: spot.spotNumber,
      companyName: companyName,
      businessType: businessType,
      productName: productName,
      description:
          '$companyName plans to showcase $productName at ${exhibition.name}. The booth will be used for product display, visitor engagement, business enquiries, and live demonstration sessions.',
      requirements: _requirementsForBusiness(businessType),
      status: status,
      rejectReason: rejectReason,
      createdAt: createdAt,
      updatedAt: updatedAt,
      paymentMethod: status == 'Paid'
          ? _paymentMethods[id.hashCode.abs() % _paymentMethods.length]
          : null,
      paidAt: paidAt,
      transactionId: status == 'Paid'
          ? 'BTFY-${createdAt.year}-${id.replaceAll('seed_application_', '')}'
          : null,
      participationStartDate: exhibition.startDate,
      participationEndDate: exhibition.endDate,
    );
  }

  static List<String> _requirementsForBusiness(String businessType) {
    switch (businessType) {
      case 'Food & Beverage':
        return [
          'Power socket',
          'Water access',
          'Waste disposal area',
          'Food preparation counter',
        ];
      case 'Technology':
        return [
          'Power socket',
          'Internet access',
          'Demo table',
          'Monitor stand',
        ];
      case 'Fashion':
        return ['Clothing rack', 'Mirror', 'Extra lighting', 'Storage space'];
      case 'Education':
        return ['Brochure stand', 'Consultation table', 'Power socket'];
      case 'Healthcare':
        return ['Privacy corner', 'Power socket', 'Consultation table'];
      case 'Tourism':
        return ['Brochure stand', 'Consultation table', 'TV display area'];
      case 'Energy':
        return [
          'Power socket',
          'Product demonstration area',
          'Safety clearance',
        ];
      default:
        return ['Power socket', 'Display table', '2 Chairs'];
    }
  }

  static Map<String, dynamic> _withSeedTag(Map<String, dynamic> data) {
    return {...data, 'seedTag': _seedTag};
  }

  static Future<void> _commitWrites(List<_SeedWrite> writes) async {
    const int batchLimit = 450;

    for (int i = 0; i < writes.length; i += batchLimit) {
      final batch = _firestore.batch();
      final chunk = writes.skip(i).take(batchLimit);

      for (final write in chunk) {
        batch.set(write.ref, write.data);
      }

      await batch.commit();
    }
  }

  static Future<void> _commitDeletes(
    List<DocumentReference<Map<String, dynamic>>> refs,
  ) async {
    const int batchLimit = 450;

    for (int i = 0; i < refs.length; i += batchLimit) {
      final batch = _firestore.batch();
      final chunk = refs.skip(i).take(batchLimit);

      for (final ref in chunk) {
        batch.delete(ref);
      }

      await batch.commit();
    }
  }

  static const List<String> _rejectReasons = [
    'Business category does not match the selected exhibition theme.',
    'Required supporting details are incomplete.',
    'Selected product type is too similar to nearby approved booths.',
    'Application information needs further verification.',
  ];

  static const List<String> _paymentMethods = [
    'Online Banking',
    'Credit Card',
    'Debit Card',
    'E-Wallet',
  ];
}

class _SeedAuthUser {
  final String uid;
  final _SeedUserInput input;

  const _SeedAuthUser({required this.uid, required this.input});
}

class _SeedWrite {
  final DocumentReference<Map<String, dynamic>> ref;
  final Map<String, dynamic> data;

  const _SeedWrite({required this.ref, required this.data});
}

class _SeedDatePair {
  final DateTime createdAt;
  final DateTime updatedAt;

  const _SeedDatePair({required this.createdAt, required this.updatedAt});
}

class _SeedUserInput {
  final String name;
  final String email;
  final String role;
  final String? companyName;
  final String? businessType;
  final String? productCategory;
  final String? organizationName;
  final String? phone;

  const _SeedUserInput({
    required this.name,
    required this.email,
    required this.role,
    this.companyName,
    this.businessType,
    this.productCategory,
    this.organizationName,
    this.phone,
  });

  UserModel toUserModel({
    required String uid,
    required DateTime now,
    required List<String> favoriteExhibitionIds,
    required int profileIndex,
  }) {
    final isOrganizer = role == 'Organizer';
    final isExhibitor = role == 'Exhibitor';

    return UserModel(
      uid: uid,
      name: name,
      preferredName: name.split(' ').first,
      email: email,
      role: role,
      isActive: true,
      companyName: companyName,
      favoriteExhibitionIds: favoriteExhibitionIds,
      createdAt: now.subtract(Duration(days: 60 - (profileIndex % 30))),
      updatedAt: now.subtract(Duration(days: profileIndex % 10)),
      phoneNumber: phone,
      residentialAddress: isExhibitor
          ? '${profileIndex + 1}, Jalan Usahawan ${profileIndex + 1}, Kuala Lumpur'
          : null,
      postalAddress: isExhibitor
          ? '${profileIndex + 1}, Business Centre ${profileIndex + 1}, Malaysia'
          : null,
      emergencyContact: isExhibitor
          ? '+6019${(5000000 + profileIndex).toString()}'
          : null,
      contactEmail: email,
      isVerified: true,
      businessType: businessType,
      companyRegistration: isExhibitor
          ? 'SSM${(2026001000 + profileIndex).toString()}'
          : null,
      productCategory: productCategory,
      contactPerson: isExhibitor ? name : null,
      companyPhone: isExhibitor ? phone : null,
      companyEmail: isExhibitor ? email : null,
      organizationName: organizationName,
      organizerPhone: isOrganizer ? phone : null,
      organizerEmail: isOrganizer ? email : null,
      organizerVerificationStatus: isOrganizer ? 'Verified' : null,
    );
  }
}

class _SeedExhibitionInput {
  final String name;
  final String location;
  final String category;
  final String eventType;
  final int startOffsetDays;
  final int durationDays;
  final bool isPublished;
  final bool isBookingOpen;
  final String expectedVisitors;
  final String contactEmail;

  const _SeedExhibitionInput({
    required this.name,
    required this.location,
    required this.category,
    required this.eventType,
    required this.startOffsetDays,
    required this.durationDays,
    required this.isPublished,
    required this.isBookingOpen,
    required this.expectedVisitors,
    required this.contactEmail,
  });
}

class _SeedBoothPackageInput {
  final String name;
  final String size;
  final double price;
  final List<String> amenities;

  const _SeedBoothPackageInput({
    required this.name,
    required this.size,
    required this.price,
    required this.amenities,
  });
}
