import 'package:flutter/material.dart';

class ExpenseModel {
  final String id;
  final String? employeeId;
  final String? workplaceId;
  final String date;
  final String description;
  final double amount;
  final List<String> billImageUrls;
  final String status;
  final String? adminNotes;
  final String? submittedAt;
  final String? updatedAt;

  ExpenseModel({
    required this.id,
    this.employeeId,
    this.workplaceId,
    required this.date,
    required this.description,
    required this.amount,
    this.billImageUrls = const [],
    required this.status,
    this.adminNotes,
    this.submittedAt,
    this.updatedAt,
  });

  Color get statusColor {
    switch (status) {
      case 'approved':
        return const Color(0xFF10B981);
      case 'rejected':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String get statusLabel {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] ?? '',
      employeeId: json['employee_id'],
      workplaceId: json['workplace_id'],
      date: json['date'] ?? '',
      description: json['description'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      billImageUrls:
          (json['bill_image_urls'] as List<dynamic>?)?.cast<String>() ?? [],
      status: json['status'] ?? 'pending',
      adminNotes: json['admin_notes'],
      submittedAt: json['submitted_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employee_id': employeeId,
        'workplace_id': workplaceId,
        'date': date,
        'description': description,
        'amount': amount,
        'bill_image_urls': billImageUrls,
        'status': status,
        'admin_notes': adminNotes,
        'submitted_at': submittedAt,
      };
}
