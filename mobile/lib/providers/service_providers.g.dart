// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(authService)
final authServiceProvider = AuthServiceProvider._();

final class AuthServiceProvider
    extends $FunctionalProvider<AuthService, AuthService, AuthService>
    with $Provider<AuthService> {
  AuthServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authServiceHash();

  @$internal
  @override
  $ProviderElement<AuthService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthService create(Ref ref) {
    return authService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthService>(value),
    );
  }
}

String _$authServiceHash() => r'21d842d4dceafa3d239c0196a0f2b890d37c0b71';

@ProviderFor(paymentService)
final paymentServiceProvider = PaymentServiceProvider._();

final class PaymentServiceProvider
    extends $FunctionalProvider<PaymentService, PaymentService, PaymentService>
    with $Provider<PaymentService> {
  PaymentServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'paymentServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$paymentServiceHash();

  @$internal
  @override
  $ProviderElement<PaymentService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PaymentService create(Ref ref) {
    return paymentService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PaymentService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PaymentService>(value),
    );
  }
}

String _$paymentServiceHash() => r'deebf6d52ffdfdc6e915a4254fb5e04b30a340aa';

@ProviderFor(installmentService)
final installmentServiceProvider = InstallmentServiceProvider._();

final class InstallmentServiceProvider
    extends
        $FunctionalProvider<
          InstallmentService,
          InstallmentService,
          InstallmentService
        >
    with $Provider<InstallmentService> {
  InstallmentServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'installmentServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$installmentServiceHash();

  @$internal
  @override
  $ProviderElement<InstallmentService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InstallmentService create(Ref ref) {
    return installmentService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InstallmentService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InstallmentService>(value),
    );
  }
}

String _$installmentServiceHash() =>
    r'13bcecf7b6b0cf6ab2574b72e99c16412699b0fc';

@ProviderFor(refundService)
final refundServiceProvider = RefundServiceProvider._();

final class RefundServiceProvider
    extends $FunctionalProvider<RefundService, RefundService, RefundService>
    with $Provider<RefundService> {
  RefundServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'refundServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$refundServiceHash();

  @$internal
  @override
  $ProviderElement<RefundService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RefundService create(Ref ref) {
    return refundService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RefundService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RefundService>(value),
    );
  }
}

String _$refundServiceHash() => r'85b03a5b5406f3141b8cab2a3fe0f5cc7916a4a1';

@ProviderFor(analyticsService)
final analyticsServiceProvider = AnalyticsServiceProvider._();

final class AnalyticsServiceProvider
    extends
        $FunctionalProvider<
          AnalyticsService,
          AnalyticsService,
          AnalyticsService
        >
    with $Provider<AnalyticsService> {
  AnalyticsServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analyticsServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analyticsServiceHash();

  @$internal
  @override
  $ProviderElement<AnalyticsService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AnalyticsService create(Ref ref) {
    return analyticsService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AnalyticsService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AnalyticsService>(value),
    );
  }
}

String _$analyticsServiceHash() => r'66a5a320cd1da376f1c6a2319557d983bf9e3598';

@ProviderFor(notificationApiService)
final notificationApiServiceProvider = NotificationApiServiceProvider._();

final class NotificationApiServiceProvider
    extends
        $FunctionalProvider<
          NotificationApiService,
          NotificationApiService,
          NotificationApiService
        >
    with $Provider<NotificationApiService> {
  NotificationApiServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationApiServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationApiServiceHash();

  @$internal
  @override
  $ProviderElement<NotificationApiService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotificationApiService create(Ref ref) {
    return notificationApiService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationApiService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationApiService>(value),
    );
  }
}

String _$notificationApiServiceHash() =>
    r'9be0fc1b12694da18d37651e29343d362555c630';
