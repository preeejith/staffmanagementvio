import 'package:flutter/material.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? aadhaarNumber;
  final String? aadhaarUrl;
  final String? drivingLicenceUrl;
  final String role;
  final String? assignedWorkplaceId;
  final bool isActive;
  final String? profilePhotoUrl;
  final String? createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.aadhaarNumber,
    this.aadhaarUrl,
    this.drivingLicenceUrl,
    required this.role,
    this.assignedWorkplaceId,
    this.isActive = true,
    this.profilePhotoUrl,
    this.createdAt,
  });

  bool get isAdmin => role == 'admin' || role == 'superadmin';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      aadhaarNumber: json['aadhaar_number'],
      aadhaarUrl: json['aadhaar_url'],
      drivingLicenceUrl: json['driving_licence_url'],
      role: json['role'] ?? 'employee',
      assignedWorkplaceId: json['assigned_workplace_id'],
      isActive: json['is_active'] ?? true,
      profilePhotoUrl: json['profile_photo_url'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'aadhaar_number': aadhaarNumber,
        'aadhaar_url': aadhaarUrl,
        'driving_licence_url': drivingLicenceUrl,
        'role': role,
        'assigned_workplace_id': assignedWorkplaceId,
        'is_active': isActive,
        'profile_photo_url': profilePhotoUrl,
        'created_at': createdAt,
      };
}
