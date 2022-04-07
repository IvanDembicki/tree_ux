class ErrorUx extends Error {

  final String message;
  final Object? object;

  ErrorUx(this.message, [this.object]);

  @override
  String toString() => '༄ ErrorUx ༄ $message ${Error.safeToString(object)}';

}
