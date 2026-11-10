/// The host application provides tokens at call time; no hardcoded credentials.
abstract class EbolaAccessTokenProvider {
  Future<String> getFreshUserAccessToken();
  Future<void> invalidateCurrentToken();
}
