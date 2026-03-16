import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  // 1. Static Logic for UI colors
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return Colors.orange;
      case 'picked_up':
        return Colors.blue;
      case 'arrived':
        return Colors.deepPurple;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // 2. Class Fields
  final String id;
  final String businessId;
  final String customerId;
  final String customerName;
  final String phone;
  final String address;
  final double totalPrice;
  final double deliveryFee;
  final String status;
  final String assignedRider;
  final String riderId; // Phase 9: Broadcast matching
  final String riderName; // Phase 9: Show assigned rider name to customer
  final DateTime createdAt;
  final DateTime updatedAt;
  final String paymentMethod;
  final String itemsSummary; // Phase 14: Human-readable items list for order cards
  final double customerLat; // Phase 15: GPS Navigation
  final double customerLng; // Phase 15: GPS Navigation

  OrderModel({
    required this.id,
    required this.businessId,
    required this.customerId,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.totalPrice,
    required this.deliveryFee,
    required this.status,
    required this.assignedRider,
    required this.riderId,
    required this.riderName,
    required this.createdAt,
    required this.updatedAt,
    required this.paymentMethod,
    this.itemsSummary = '',
    this.customerLat = 0.0,
    this.customerLng = 0.0,
  });

  // 3. Factory for reading from Firestore
  factory OrderModel.fromMap(Map<String, dynamic> map, String docId) {
    return OrderModel(
      id: docId,
      businessId: map['businessId'] ?? '', // Default to empty if missing
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      totalPrice: (map['totalPrice'] as num).toDouble(),
      deliveryFee: (map['deliveryFee'] as num).toDouble(),
      status: map['status'] ?? 'assigned',
      assignedRider: map['assignedRider'] ?? '',
      riderId: map['riderId'] ?? '',
      riderName: map['riderName'] ?? 'Rider',
      createdAt: map['createdAt'] is Timestamp ? (map['createdAt'] as Timestamp).toDate() : (map['createdAt'] is String ? DateTime.tryParse(map['createdAt']) ?? DateTime.now() : DateTime.now()),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] is Timestamp ? (map['updatedAt'] as Timestamp).toDate() : DateTime.tryParse(map['updatedAt']) ?? DateTime.now())
          : (map['createdAt'] is Timestamp ? (map['createdAt'] as Timestamp).toDate() : DateTime.tryParse(map['createdAt']) ?? DateTime.now()),
      paymentMethod: map['paymentMethod'] ?? 'Cash',
      itemsSummary: map['itemsSummary'] as String? ?? '',
      customerLat: (map['customerLat'] as num?)?.toDouble() ?? 0.0,
      customerLng: (map['customerLng'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // 4. Method for saving to Firestore
  Map<String, dynamic> toMap() {
    return {
      'businessId': businessId, // Critical: Ties the order to the shop
      'customerId': customerId,
      'customerName': customerName,
      'phone': phone,
      'address': address,
      'totalPrice': totalPrice,
      'deliveryFee': deliveryFee,
      'status': status,
      'assignedRider': assignedRider,
      'riderId': riderId,
      'riderName': riderName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'paymentMethod': paymentMethod,
      'itemsSummary': itemsSummary,
      'customerLat': customerLat,
      'customerLng': customerLng,
    };
  }
}