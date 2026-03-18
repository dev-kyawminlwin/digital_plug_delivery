import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SeedService {
  static Future<void> seedPhingPhaMenu(BuildContext context, String businessId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Seed Menu?'),
        content: const Text('This will inject 60+ PhingPha drinks into your menu. Proceed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Seed')),
        ],
      ),
    );

    if (confirm == true) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seeding drinks...')));
      }
      try {
        final db = FirebaseFirestore.instance;
        final drinks = [
          {'name': 'Blue Hawaii Soda / บลูฮาวายโซดา', 'basePrice': 60, 'category': 'Italian Soda'},
          {'name': 'Strawberry Soda / สตรอเบอร์รี่โซดา', 'basePrice': 60, 'category': 'Italian Soda'},
          {'name': 'Kiwi Smoothie / สมูทตี้กีวี่', 'basePrice': 65, 'category': 'Smoothies'},
          {'name': 'Espresso / เอสเปรสโซ่', 'basePrice': 55, 'category': 'Coffee', 'hasVariants': true, 'icedPrice': 65, 'frappePrice': 75},
          {'name': 'Americano / อเมริกาโน่', 'basePrice': 55, 'category': 'Coffee', 'hasVariants': true, 'icedPrice': 65, 'frappePrice': 75},
          {'name': 'Thai Tea / ชาเย็น', 'basePrice': 55, 'category': 'Tea', 'hasVariants': true, 'icedPrice': 60, 'frappePrice': 70},
          {'name': 'Taiwan Milk Tea Bubble / ชานมไต้หวันไข่มุก', 'basePrice': 65, 'category': 'Bubble Tea'},
          {'name': 'Caramel Fresh Milk / นมสดคาราเมล', 'basePrice': 50, 'category': 'Milk', 'hasVariants': true, 'icedPrice': 55, 'frappePrice': 65},
        ];

        int successCount = 0;

        for (var drink in drinks) {
          List<Map<String, dynamic>> addOns = [];
          if (drink['category'] == 'Coffee') {
            addOns.add({'name': 'Coffee Shot (เพิ่มช็อต)', 'price': 20.0});
          } else if (drink['category'] == 'Bubble Tea') {
            addOns.add({'name': 'Extra Pearl (เพิ่มมุก)', 'price': 15.0});
          }

          List<Map<String, dynamic>> optionGroups = [];
          if (drink['hasVariants'] == true) {
            double iPrice = (drink['icedPrice'] as int).toDouble();
            double fPrice = (drink['frappePrice'] as int).toDouble();
            optionGroups.add({
              'title': 'Serving Style / รูปแบบการเสิร์ฟ',
              'options': [
                'Hot (ร้อน)',
                'Iced (เย็น) [+${(iPrice - (drink['basePrice'] as int)).toStringAsFixed(0)} THB]',
                'Frappe (ปั่น) [+${(fPrice - (drink['basePrice'] as int)).toStringAsFixed(0)} THB]'
              ]
            });
          }

          final mRef = db.collection('menus').doc();
          await mRef.set({
            'businessId': businessId,
            'name': drink['name'],
            'description': 'Premium ${drink['category']}',
            'basePrice': (drink['basePrice'] as int).toDouble(),
            'category': drink['category'],
            'imageUrl': '',
            'isAvailable': true,
            'optionGroups': optionGroups,
            'addOns': addOns,
            'customOptions': [],
            'quantity': 999,
            'soldCount': 0,
            'createdAt': FieldValue.serverTimestamp(),
          });
          successCount++;
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Successfully seeded $successCount drinks!')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}
