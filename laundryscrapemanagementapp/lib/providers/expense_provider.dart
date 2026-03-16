import 'package:flutter/foundation.dart';
import '../models/expense_model.dart';
import '../services/api_service.dart';

class ExpenseProvider extends ChangeNotifier {
  List<ExpenseModel> _expenses = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  double _totalAmount = 0;
  int _pendingCount = 0;

  List<ExpenseModel> get expenses => _expenses;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  double get totalAmount => _totalAmount;
  int get pendingCount => _pendingCount;

  Future<void> loadMyExpenses(String token, {String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final api = ApiService(token: token);
      final params = <String, String>{};
      if (status != null) params['status'] = status;
      final res = await api.get('/expenses', queryParams: params)
          as Map<String, dynamic>;
      if (res['success'] == true) {
        _expenses =
            (res['data'] as List).map((e) => ExpenseModel.fromJson(e)).toList();
        final summary = res['summary'] as Map<String, dynamic>? ?? {};
        _totalAmount = (summary['total_amount'] as num?)?.toDouble() ?? 0.0;
        _pendingCount = (summary['pending_count'] as num?)?.toInt() ?? 0;
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> submitExpense(
    String token, {
    required String date,
    required String description,
    required double amount,
    required String workplaceId,
    required List<String> billImageUrls,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final api = ApiService(token: token);
      final res = await api.post('/expenses', body: {
        'date': date,
        'description': description,
        'amount': amount,
        'workplace_id': workplaceId,
        'bill_image_urls': billImageUrls,
      }) as Map<String, dynamic>;
      if (res['success'] == true) {
        _expenses.insert(0, ExpenseModel.fromJson(res['data']));
        _isSubmitting = false;
        notifyListeners();
        return true;
      }
      _error = res['error'] ?? 'Failed to submit';
    } catch (e) {
      _error = e.toString();
    }

    _isSubmitting = false;
    notifyListeners();
    return false;
  }
}
