import '../models/admin_account.dart';

abstract class AdminRepository {
  Future<AdminAccount?> getAdmin();
  Future<void> saveAdmin(AdminAccount admin);
}
