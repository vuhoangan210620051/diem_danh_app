import '../repositories/admin_repository.dart';

class AuthService {
  final AdminRepository repo;

  AuthService(this.repo);

  Future<bool> loginAdmin(String username, String password) async {
    final admin = await repo.getAdmin();
    if (admin == null) return false;

    return admin.username == username && admin.passwordHash == _hash(password);
  }

  String _hash(String input) {
    // demo
    return input.split('').reversed.join();
  }
}
