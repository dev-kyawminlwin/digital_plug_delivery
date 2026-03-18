import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:digital_plug_delivery/firebase_options.dart';

void main() async {
  print('Initializing Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('Firebase Initialized.');

  final db = FirebaseFirestore.instance;
  // Use a real business ID if we know it. We'll find it via query, or default to a mock.
  // First let's find PhingPha if it exists, otherwise create it.
  
  String businessId = '';
  final qs = await db.collection('businesses').where('name', isEqualTo: 'PhingPha Cafe & Restaurants').get();
  
  if (qs.docs.isNotEmpty) {
    businessId = qs.docs.first.id;
    print('Found PhingPha Cafe with ID: $businessId');
  } else {
    print('PhingPha Cafe not found! Creating a placeholder business for the menu...');
    final docRef = await db.collection('businesses').add({
      'name': 'PhingPha Cafe & Restaurants',
      'category': 'Cafe',
      'description': 'Premium coffee, smoothies, and Italian Sodas.',
      'imageUrl': '',
      'ownerId': 'MOCK_OWNER_ID',
      'address': 'Testing Address',
      'isApproved': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    businessId = docRef.id;
    print('Created business ID: $businessId');
  }

  print('Starting batch insertion for drinks...');
  
  final drinks = [
    // --- Italian Sodas (อิตาเลียนโซดา) 60 THB ---
    {'name': 'Blue Hawaii Soda / บลูฮาวายโซดา', 'basePrice': 60, 'category': 'Italian Soda'}, // B385
    {'name': 'Blue Lemon Soda / บลูเลม่อนโซดา', 'basePrice': 60, 'category': 'Italian Soda'}, // B386
    {'name': 'Blueberry Soda / บลูเบอร์รี่โซดา', 'basePrice': 60, 'category': 'Italian Soda'}, // B387
    {'name': 'Kiwi Soda / กีวี่โซดา', 'basePrice': 60, 'category': 'Italian Soda'}, // B388
    {'name': 'Strawberry Soda / สตรอเบอร์รี่โซดา', 'basePrice': 60, 'category': 'Italian Soda'}, // B389
    {'name': 'Raspberry Soda / ราสเบอร์รี่โซดา', 'basePrice': 60, 'category': 'Italian Soda'}, // B390
    {'name': 'Passion Fruit Soda / เสาวรสโซดา', 'basePrice': 60, 'category': 'Italian Soda'}, // B391
    {'name': 'Lychee Soda / ลิ้นจี่โซดา', 'basePrice': 60, 'category': 'Italian Soda'}, // B392
    {'name': 'Green Apple Soda / แอปเปิ้ลเขียวโซดา', 'basePrice': 60, 'category': 'Italian Soda'}, // B393
    {'name': 'Lemon Soda / มะนาวโซดา', 'basePrice': 60, 'category': 'Italian Soda'}, // B394
    {'name': 'Grape Soda / องุ่นโซดา', 'basePrice': 60, 'category': 'Italian Soda'}, // B395
    {'name': 'Orange Soda / ส้มโซดา', 'basePrice': 60, 'category': 'Italian Soda'}, // B396
    {'name': 'Pineapple Soda / สับปะรดโซดา', 'basePrice': 60, 'category': 'Italian Soda'}, // B397
    {'name': 'Honey Lemon Soda / น้ำผึ้งมะนาวโซดา', 'basePrice': 60, 'category': 'Italian Soda'}, // B398
    {'name': 'Punch Soda / พันซ์โซดา', 'basePrice': 60, 'category': 'Italian Soda'}, // B399
    {'name': 'Red Syrup Soda / น้ำแดงโซดา', 'basePrice': 60, 'category': 'Italian Soda'}, // B400

    // --- Smoothies (สมูทตี้) 65 THB ---
    {'name': 'Kiwi Smoothie / สมูทตี้กีวี่', 'basePrice': 65, 'category': 'Smoothies'}, // B410
    {'name': 'Blueberry Smoothie / สมูทตี้บลูเบอร์รี่', 'basePrice': 65, 'category': 'Smoothies'}, // B411
    {'name': 'Strawberry Smoothie / สมูทตี้สตรอเบอร์รี่', 'basePrice': 65, 'category': 'Smoothies'}, // B412
    {'name': 'Raspberry Smoothie / สมูทตี้ราสเบอร์รี่', 'basePrice': 65, 'category': 'Smoothies'}, // B413
    {'name': 'Passion Fruit Smoothie / สมูทตี้เสาวรส', 'basePrice': 65, 'category': 'Smoothies'}, // B414
    {'name': 'Lychee Smoothie / สมูทตี้ลิ้นจี่', 'basePrice': 65, 'category': 'Smoothies'}, // B415
    {'name': 'Green Apple Smoothie / สมูทตี้แอปเปิ้ลเขียว', 'basePrice': 65, 'category': 'Smoothies'}, // B416
    {'name': 'Lemon Smoothie / สมูทตี้มะนาว', 'basePrice': 65, 'category': 'Smoothies'}, // B417
    {'name': 'Yogurt Smoothie / สมูทตี้โยเกิร์ต', 'basePrice': 65, 'category': 'Smoothies'}, // B418

    // --- Coffee (เมนูกาแฟ) with variants (Hot, Iced, Frappe)
    // We will set their base price to the "Hot" price, and add variant options
    {'name': 'Espresso / เอสเปรสโซ่', 'basePrice': 55, 'category': 'Coffee', 'hasVariants': true, 'icedPrice': 65, 'frappePrice': 75}, // B300
    {'name': 'Americano / อเมริกาโน่', 'basePrice': 55, 'category': 'Coffee', 'hasVariants': true, 'icedPrice': 65, 'frappePrice': 75}, // B301
    {'name': 'Cappuccino / คาปูชิโน่', 'basePrice': 55, 'category': 'Coffee', 'hasVariants': true, 'icedPrice': 65, 'frappePrice': 75}, // B302
    {'name': 'Mocha / มอคค่า', 'basePrice': 55, 'category': 'Coffee', 'hasVariants': true, 'icedPrice': 65, 'frappePrice': 75}, // B303
    {'name': 'Latte / ลาเต้', 'basePrice': 55, 'category': 'Coffee', 'hasVariants': true, 'icedPrice': 65, 'frappePrice': 75}, // B304
    {'name': 'Honey Coffee / กาแฟน้ำผึ้ง', 'basePrice': 55, 'category': 'Coffee', 'hasVariants': true, 'icedPrice': 65, 'frappePrice': 75}, // B305
    {'name': 'Black Coffee Honey / กาแฟดำน้ำผึ้ง', 'basePrice': 55, 'category': 'Coffee', 'hasVariants': true, 'icedPrice': 65, 'frappePrice': 75}, // B306
    {'name': 'Black Coffee Orange / กาแฟดำน้ำส้ม', 'basePrice': 75, 'category': 'Coffee'}, // B307 (Only 75THB)

    // --- Tea (ชา)
    {'name': 'Thai Tea / ชาเย็น', 'basePrice': 55, 'category': 'Tea', 'hasVariants': true, 'icedPrice': 60, 'frappePrice': 70}, // B313
    {'name': 'Green Tea / ชาเขียว', 'basePrice': 55, 'category': 'Tea', 'hasVariants': true, 'icedPrice': 60, 'frappePrice': 70}, // B314
    {'name': 'Lemon Tea / ชามะนาว', 'basePrice': 50, 'category': 'Tea', 'hasVariants': true, 'icedPrice': 55, 'frappePrice': 65}, // B315
    {'name': 'Honey Lemon Tea / ชาน้ำผึ้งมะนาว', 'basePrice': 50, 'category': 'Tea', 'hasVariants': true, 'icedPrice': 55, 'frappePrice': 65}, // B316
    {'name': 'Apple Tea / ชาแอปเปิ้ล', 'basePrice': 50, 'category': 'Tea', 'hasVariants': true, 'icedPrice': 55, 'frappePrice': 65}, // B317
    {'name': 'Peach Tea / ชาพีช', 'basePrice': 50, 'category': 'Tea', 'hasVariants': true, 'icedPrice': 55, 'frappePrice': 65}, // B318
    {'name': 'Butterfly Pea Honey Lemon / อัญชันน้ำผึ้งมะนาว', 'basePrice': 50, 'category': 'Tea', 'hasVariants': true, 'icedPrice': 55, 'frappePrice': 65}, // B319

    // --- Milk (นม)
    {'name': 'Honey Lemon Milk / น้ำผึ้งมะนาว (นม)', 'basePrice': 50, 'category': 'Milk', 'hasVariants': true, 'icedPrice': 55, 'frappePrice': 65}, // B320
    {'name': 'Fresh Milk / นมสด', 'basePrice': 50, 'category': 'Milk', 'hasVariants': true, 'icedPrice': 55, 'frappePrice': 65}, // B321
    {'name': 'Honey Milk / นมน้ำผึ้ง', 'basePrice': 50, 'category': 'Milk', 'hasVariants': true, 'icedPrice': 55, 'frappePrice': 65}, // B322
    {'name': 'Pink Milk (Sala) / นมชมพู', 'basePrice': 50, 'category': 'Milk', 'hasVariants': true, 'icedPrice': 55, 'frappePrice': 65}, // B323
    {'name': 'Green Milk / นมเขียว', 'basePrice': 50, 'category': 'Milk', 'hasVariants': true, 'icedPrice': 55, 'frappePrice': 65}, // B324
    {'name': 'Cocoa / โกโก้', 'basePrice': 50, 'category': 'Milk', 'hasVariants': true, 'icedPrice': 55, 'frappePrice': 65}, // B325
    {'name': 'Matcha Latte / มัทฉะลาเต้', 'basePrice': 65, 'category': 'Milk'}, // B326
    {'name': 'Caramel Fresh Milk / นมสดคาราเมล', 'basePrice': 50, 'category': 'Milk', 'hasVariants': true, 'icedPrice': 55, 'frappePrice': 65}, // B327
    {'name': 'Banana Milk Frappe / กล้วยหอมนมสดปั่น', 'basePrice': 65, 'category': 'Milk'}, // B328
    {'name': 'Oreo Milk / นมโอริโอ้', 'basePrice': 65, 'category': 'Milk'}, // B329
    {'name': 'Butterfly Pea Milk / อัญชันนมสด', 'basePrice': 55, 'category': 'Milk', 'hasVariants': true, 'icedPrice': 55, 'frappePrice': 65}, // B330
    {'name': 'Avocado / อะโวคาโด้', 'basePrice': 65, 'category': 'Milk'}, // B331
    {'name': 'Coconut Milk / มะพร้าวนมสด', 'basePrice': 65, 'category': 'Milk'}, // B332
    {'name': 'Coconut Avocado Milk / มะพร้าวอะโวคาโด้นมสด', 'basePrice': 65, 'category': 'Milk'}, // B333

    // --- Bubble Tea (เมนูชามุก) - Cold Only
     {'name': 'Taiwan Milk Tea Bubble / ชานมไต้หวันไข่มุก', 'basePrice': 65, 'category': 'Bubble Tea'}, // B334
     {'name': 'Matcha Green Tea Bubble / มัทฉะกรีนทีมุก', 'basePrice': 65, 'category': 'Bubble Tea'}, // B335
     {'name': 'Chocolate Bubble / ช็อกโกแลตมุก', 'basePrice': 65, 'category': 'Bubble Tea'}, // B336
     {'name': 'Melon Bubble / เมล่อนมุก', 'basePrice': 65, 'category': 'Bubble Tea'}, // B337
     {'name': 'Strawberry Bubble / สตรอเบอร์รี่มุก', 'basePrice': 65, 'category': 'Bubble Tea'}, // B338
     {'name': 'Taro Bubble / เผือกมุก', 'basePrice': 65, 'category': 'Bubble Tea'}, // B339
     {'name': 'Rose Tea Bubble / ชากุหลาบมุก', 'basePrice': 65, 'category': 'Bubble Tea'}, // 
     // B340 is an Add-on: +Extra Pearl (15 THB), which we'll add as an addon to all bubble teas.

    // --- Fresh Fruit Juices (น้ำผลไม้สด)
    {'name': 'Mango Smoothie / มะม่วงปั่น', 'basePrice': 85, 'category': 'Fresh Fruit'}, // B365
    {'name': 'Strawberry Cheesecake / สตรอเบอร์รี่ปั่นชีสเค้ก', 'basePrice': 85, 'category': 'Fresh Fruit'}, // B366
    {'name': 'Green Tea Red Bean / ชาเขียวปั่นถั่วแดง', 'basePrice': 85, 'category': 'Fresh Fruit'}, // B367
    {'name': 'Watermelon / น้ำแตงโม', 'basePrice': 65, 'category': 'Fresh Fruit'}, // B368
    {'name': 'Strawberry Juice / น้ำสตรอเบอร์รี่', 'basePrice': 65, 'category': 'Fresh Fruit'}, // B369
    {'name': 'Mango / น้ำมะม่วง', 'basePrice': 65, 'category': 'Fresh Fruit'}, // B378
    {'name': 'Orange Juice / น้ำส้ม', 'basePrice': 65, 'category': 'Fresh Fruit'}, // B379
    {'name': 'Lemon Juice / น้ำมะนาว', 'basePrice': 50, 'category': 'Fresh Fruit', 'hasVariants': true, 'icedPrice': 55, 'frappePrice': 65}, // B370
    {'name': 'Blueberry Juice / น้ำบลูเบอร์รี่', 'basePrice': 65, 'category': 'Fresh Fruit'}, // B371
    {'name': 'Kiwi Juice / น้ำกีวี่', 'basePrice': 65, 'category': 'Fresh Fruit'}, // B372
    {'name': 'Passion Fruit Juice / น้ำเสาวรส', 'basePrice': 65, 'category': 'Fresh Fruit'}, // B373
    {'name': 'Apple Juice / น้ำแอปเปิ้ล', 'basePrice': 65, 'category': 'Fresh Fruit'}, // B374
    {'name': 'Lychee Juice / น้ำลิ้นจี่', 'basePrice': 65, 'category': 'Fresh Fruit'}, // B375
    {'name': 'Carrot Juice / น้ำแครอท', 'basePrice': 65, 'category': 'Fresh Fruit'}, // B377
    {'name': 'Fresh Coconut / มะพร้าวสด', 'basePrice': 65, 'category': 'Fresh Fruit'}, // Only Iced/Frappe
  ];

  int count = 0;
  for (var drink in drinks) {
    // Construct Add-ons
    List<Map<String, dynamic>> addOns = [];
    if (drink['category'] == 'Coffee') {
      addOns.add({'name': 'Coffee Shot (เพิ่มช็อต)', 'price': 20.0});
    } else if (drink['category'] == 'Bubble Tea') {
       addOns.add({'name': 'Extra Pearl (เพิ่มมุก)', 'price': 15.0});
    }

    // Construct Options Group (e.g. Hot/Iced/Frappe)
    List<Map<String, dynamic>> optionGroups = [];
    if (drink['hasVariants'] == true) {
      double iPrice = (drink['icedPrice'] as int).toDouble();
      double fPrice = (drink['frappePrice'] as int).toDouble();
      
      optionGroups.add({
        'title': 'Serving Style / รูปแบบการเสิร์ฟ',
        'options': [
          'Hot (ร้อน)', // Base Price
          'Iced (เย็น) [+${(iPrice - (drink['basePrice'] as int)).toStringAsFixed(0)} THB]', 
          'Frappe (ปั่น) [+${(fPrice - (drink['basePrice'] as int)).toStringAsFixed(0)} THB]'
        ]
      });
    } else if (drink['category'] == 'Fresh Fruit' || drink['category'] == 'Smoothies' || drink['category'] == 'Italian Soda') {
        // Cold implicitly
        optionGroups.add({
        'title': 'Serving Style / รูปแบบการเสิร์ฟ',
        'options': ['Frappe (ปั่น) / Iced (เย็น)']
      });
    }

    await db.collection('products').add({
      'businessId': businessId,
      'name': drink['name'],
      'description': 'Refreshing ${drink['name']} from PhingPha Cafe',
      'basePrice': (drink['basePrice'] as int).toDouble(),
      'category': drink['category'],
      'imageUrl': '', // Needs real image uploading later
      'isAvailable': true,
      'optionGroups': optionGroups,
      'addOns': addOns,
      'customOptions': [],
      'quantity': 999, // Unlimited stock
      'soldCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    count++;
    if (count % 10 == 0) print('Inserted $count items...');
  }

  print('Successfully inserted ${drinks.length} drinks for PhingPha Cafe (Business ID: $businessId). Exiting script.');
  exit(0);
}
