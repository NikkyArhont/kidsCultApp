/// Leave the splash only after its asynchronous session check has completed.
/// Later navigation must not be redirected back to the initial destination.
String? startupRedirect({
  required bool isCheckingAuth,
  required String location,
  required String? initialRoute,
}) {
  if (isCheckingAuth) return location == '/splash' ? null : '/splash';
  if (location == '/splash') return initialRoute ?? '/auth';
  return null;
}
