import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/installment_service.dart';
import '../services/notification_api_service.dart';
import '../services/payment_service.dart';
import '../services/refund_service.dart';
import 'session_provider.dart';

part 'service_providers.g.dart';

// API clients bound to the current session token. They rebuild automatically
// when the token changes, so screens never construct a service themselves.

@Riverpod(keepAlive: true)
AuthService authService(Ref ref) => AuthService();

@Riverpod(keepAlive: true)
PaymentService paymentService(Ref ref) => PaymentService(ref.watch(authTokenProvider));

@Riverpod(keepAlive: true)
InstallmentService installmentService(Ref ref) => InstallmentService(ref.watch(authTokenProvider));

@Riverpod(keepAlive: true)
RefundService refundService(Ref ref) => RefundService(ref.watch(authTokenProvider));

@Riverpod(keepAlive: true)
AnalyticsService analyticsService(Ref ref) => AnalyticsService(ref.watch(authTokenProvider));

@Riverpod(keepAlive: true)
NotificationApiService notificationApiService(Ref ref) => NotificationApiService(ref.watch(authTokenProvider));
