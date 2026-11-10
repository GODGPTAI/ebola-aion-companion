/// Existing PHP login/signup/dashboard/session stays authoritative.
abstract class EbolaExistingAccountPort {
  Future<bool> isAuthenticated();
  Future<String> currentUserCode();
  Future<String> existingDashboardUrl();
  Future<String> existingOneQrUrl();
}
