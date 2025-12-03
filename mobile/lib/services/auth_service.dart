import 'api_service.dart';
import '../models/user_model.dart';

class AuthService {
  final ApiService apiService;

  AuthService({required this.apiService});

  Future<void> sendOTP(String phoneNumber) async {
    await apiService.post('/auth/login', {
      'phoneNumber': phoneNumber,
    });
  }

  Future<Map<String, dynamic>> verifyOTP(
    String phoneNumber,
    String otp, {
    String? fcmToken,
  }) async {
    final response = await apiService.post('/auth/verify', {
      'phoneNumber': phoneNumber,
      'otp': otp,
      if (fcmToken != null) 'fcmToken': fcmToken,
    });

    return {
      'token': response['token'] as String,
      'user': UserModel.fromJson(response['user'] as Map<String, dynamic>),
    };
  }

  Future<UserModel> updateProfile({
    required String token,
    String? name,
    String? email,
    String? fcmToken,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (email != null) data['email'] = email;
    if (fcmToken != null) data['fcmToken'] = fcmToken;

    final response = await apiService.put('/auth/profile', data, token: token);
    return UserModel.fromJson(response['user'] as Map<String, dynamic>);
  }
}

