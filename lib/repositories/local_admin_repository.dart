import 'admin_repository.dart';
import '../models/admin_account.dart';

class LocalAdminRepository implements AdminRepository {
  AdminAccount? _admin = AdminAccount(
    username: "admin",
    passwordHash: _hash("123456"),
  );

  @override
  Future<AdminAccount?> getAdmin() async {
    return _admin;
  }

  @override
  Future<void> saveAdmin(AdminAccount admin) async {
    _admin = admin;
  }

  static String _hash(String input) {
    // demo hash, phải giống AuthService
    return input.split('').reversed.join();
  }
}
