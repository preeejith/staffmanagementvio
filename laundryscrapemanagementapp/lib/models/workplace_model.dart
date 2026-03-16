class WorkplaceModel {
  final String id;
  final String name;
  final String? description;
  final String? location;
  final String? instructions;
  final String? contactName;
  final String? contactPhone;
  final String? contactEmail;
  final bool isFeatured;
  final String? bannerImageUrl;
  final List<String> assignedEmployees;
  final bool isActive;

  WorkplaceModel({
    required this.id,
    required this.name,
    this.description,
    this.location,
    this.instructions,
    this.contactName,
    this.contactPhone,
    this.contactEmail,
    this.isFeatured = false,
    this.bannerImageUrl,
    this.assignedEmployees = const [],
    this.isActive = true,
  });

  factory WorkplaceModel.fromJson(Map<String, dynamic> json) {
    return WorkplaceModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      location: json['location'],
      instructions: json['instructions'],
      contactName: json['contact_name'],
      contactPhone: json['contact_phone'],
      contactEmail: json['contact_email'],
      isFeatured: json['is_featured'] ?? false,
      bannerImageUrl: json['banner_image_url'],
      assignedEmployees:
          (json['assigned_employees'] as List<dynamic>?)?.cast<String>() ?? [],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'location': location,
        'instructions': instructions,
        'contact_name': contactName,
        'contact_phone': contactPhone,
        'contact_email': contactEmail,
        'is_featured': isFeatured,
        'banner_image_url': bannerImageUrl,
        'assigned_employees': assignedEmployees,
        'is_active': isActive,
      };
}
