// Conditional import - exports the right implementation based on platform
export 'notification_service_web_stub.dart' if (dart.library.io) 'notification_service_mobile.dart';

