class BannerModel {
  final String id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? workplaceId;
  final int displayOrder;
  final bool isActive;

  BannerModel({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.workplaceId,
    this.displayOrder = 0,
    this.isActive = true,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'],
      imageUrl: json['image_url'],
      workplaceId: json['workplace_id'],
      displayOrder: json['display_order'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }
}

class AnnouncementModel {
  final String id;
  final String title;
  final String body;
  final String targetAudience;
  final bool isActive;
  final String? createdAt;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.body,
    this.targetAudience = 'all',
    this.isActive = true,
    this.createdAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      targetAudience: json['target_audience'] ?? 'all',
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'],
    );
  }
}
