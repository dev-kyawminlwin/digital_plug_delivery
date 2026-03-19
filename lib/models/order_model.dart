import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  lookingForRider,
  assigned,
  pickedUp,
  arrived,
  completed,
  cancelled
}

extension OrderStatusExt on OrderStatus {
  String get value {
    switch (this) {
      case OrderStatus.lookingForRider: return 'looking_for_rider';
      case OrderStatus.assigned: return 'assigned';
      case OrderStatus.pickedUp: return 'picked_up';
      case OrderStatus.arrived: return 'arrived';
      case OrderStatus.completed: return 'completed';
      case OrderStatus.cancelled: return 'cancelled';
    }
  }

  String get displayName => value.toUpperCase().replaceAll('_', ' ');

  static OrderStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'looking_for_rider': return OrderStatus.lookingForRider;
      case 'assigned': return OrderStatus.assigned;
      case 'picked_up': return OrderStatus.pickedUp;
      case 'arrived': return OrderStatus.arrived;
      case 'completed': return OrderStatus.completed;
      case 'cancelled': return OrderStatus.cancelled;
      default: return OrderStatus.lookingForRider;
    }
  }
}

class OrderModel {
  // 1. Static Logic for UI colors
  static Color getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.assigned:
        return Colors.orange;
      case OrderStatus.pickedUp:
        return Colors.blue;
      case OrderStatus.arrived:
        return Colors.deepPurple;
      case OrderStatus.completed:
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
  final OrderStatus status;
  final String assignedRider;
  final String riderId; // Phase 9: Broadcast matching
  final String riderName; // Phase 9: Show assigned rider name to customer
  final DateTime createdAt;
  final DateTime updatedAt;
  final String paymentMethod;
  final String itemsSummary; // Phase 14: Human-readable items list for order cards
  final double customerLat; // Phase 15: GPS Navigation
  final double customerLng; // Phase 15: GPS Navigation
  final String cancellationReason;

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
    this.cancellationReason = '',
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
      status: OrderStatusExt.fromString(map['status'] ?? 'looking_for_rider'),
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
      cancellationReason: map['cancellationReason'] as String? ?? '',
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
      'status': status.value,
      'assignedRider': assignedRider,
      'riderId': riderId,
      'riderName': riderName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'paymentMethod': paymentMethod,
      'itemsSummary': itemsSummary,
      'customerLat': customerLat,
      'customerLng': customerLng,
      'cancellationReason': cancellationReason,
    };
  }
}