class AuthResponseModel {
  const AuthResponseModel({required this.accessToken});

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) =>
      AuthResponseModel(
        accessToken: json['accessToken'] as String,
      );

  final String accessToken;
}
