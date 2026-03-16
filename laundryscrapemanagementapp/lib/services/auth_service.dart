import 'api_service.dart';
import '../models/user_model.dart';

class AuthService {
  final ApiService _api;
  AuthService({String? token}) : _api = ApiService(token: token);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _api
        .post('/auth/login', body: {'email': email, 'password': password});
    return res as Map<String, dynamic>;
  }

  Future<void> logout(String token) async {
    final api = ApiService(token: token);
    await api.post('/auth/logout');
  }

  Future<UserModel> getMe(String token) async {
    final api = ApiService(token: token);
    final res = await api.get('/auth/me') as Map<String, dynamic>;
    return UserModel.fromJson(res['data']);
  }

  Future<void> forgotPassword(String email) async {
    await _api.post('/auth/forgot-password', body: {'email': email});
  }
}
