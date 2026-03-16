import 'package:flutter/foundation.dart';
import '../models/workplace_model.dart';
import '../models/banner_model.dart';
import '../services/api_service.dart';

class HomeProvider extends ChangeNotifier {
  WorkplaceModel? _assignedWorkplace;
  List<BannerModel> _banners = [];
  List<AnnouncementModel> _announcements = [];
  bool _isLoading = false;

  WorkplaceModel? get assignedWorkplace => _assignedWorkplace;
  List<BannerModel> get banners => _banners;
  List<AnnouncementModel> get announcements => _announcements;
  bool get isLoading => _isLoading;

  Future<void> loadHomeData(String token, String? workplaceId) async {
    _isLoading = true;
    notifyListeners();

    final api = ApiService(token: token);

    try {
      final results = await Future.wait([
        if (workplaceId != null)
          api.get('/workplaces/$workplaceId')
        else
          Future.value(null),
        api.get('/banners'),
        api.get('/announcements'),
      ]);

      if (workplaceId != null && results[0] != null) {
        final wpRes = results[0] as Map<String, dynamic>;
        if (wpRes['success'] == true) {
          _assignedWorkplace = WorkplaceModel.fromJson(wpRes['data']);
        }
      }

      final bannersRes = results[1] as Map<String, dynamic>;
      if (bannersRes['success'] == true) {
        _banners = (bannersRes['data'] as List)
            .map((b) => BannerModel.fromJson(b))
            .toList();
      }

      final announcementsRes = results[2] as Map<String, dynamic>;
      if (announcementsRes['success'] == true) {
        _announcements = (announcementsRes['data'] as List)
            .map((a) => AnnouncementModel.fromJson(a))
            .toList();
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }
}
