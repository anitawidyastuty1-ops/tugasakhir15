class ApiEndpoints {
  static const String baseUrl = 'https://absensib1.mobileprojp.com/api';

  static const String register = '$baseUrl/register';
  static const String login = '$baseUrl/login';
  static const String checkIn = '$baseUrl/absen/check-in';
  static const String checkOut = '$baseUrl/absen/check-out';
  static const String history = '$baseUrl/absen/history';
  static const String profile = '$baseUrl/profile';
  static const String users = '$baseUrl/users';

  static String deleteAbsen(int id) => '$baseUrl/absen/$id';
}
