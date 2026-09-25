// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The signed-in citizen's payments. Invalidate after anything that creates or settles a payment.

@ProviderFor(myPayments)
final myPaymentsProvider = MyPaymentsProvider._();

/// The signed-in citizen's payments. Invalidate after anything that creates or settles a payment.

final class MyPaymentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Payment>>,
          List<Payment>,
          FutureOr<List<Payment>>
        >
    with $FutureModifier<List<Payment>>, $FutureProvider<List<Payment>> {
  /// The signed-in citizen's payments. Invalidate after anything that creates or settles a payment.
  MyPaymentsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myPaymentsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myPaymentsHash();

  @$internal
  @override
  $FutureProviderElement<List<Payment>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Payment>> create(Ref ref) {
    return myPayments(ref);
  }
}

String _$myPaymentsHash() => r'9d23d4cde3d6393b6638b475f88fa6132b2b9b52';

/// Confirms a checkout with the backend (which checks Stripe) and returns the up-to-date payment.

@ProviderFor(paymentConfirmation)
final paymentConfirmationProvider = PaymentConfirmationFamily._();

/// Confirms a checkout with the backend (which checks Stripe) and returns the up-to-date payment.

final class PaymentConfirmationProvider
    extends $FunctionalProvider<AsyncValue<Payment>, Payment, FutureOr<Payment>>
    with $FutureModifier<Payment>, $FutureProvider<Payment> {
  /// Confirms a checkout with the backend (which checks Stripe) and returns the up-to-date payment.
  PaymentConfirmationProvider._({
    required PaymentConfirmationFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'paymentConfirmationProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$paymentConfirmationHash();

  @override
  String toString() {
    return r'paymentConfirmationProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Payment> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Payment> create(Ref ref) {
    final argument = this.argument as String;
    return paymentConfirmation(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PaymentConfirmationProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$paymentConfirmationHash() =>
    r'4db26e90d0bcf64918e9e58e350ef99d4ac0378a';

/// Confirms a checkout with the backend (which checks Stripe) and returns the up-to-date payment.

final class PaymentConfirmationFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Payment>, String> {
  PaymentConfirmationFamily._()
    : super(
        retry: null,
        name: r'paymentConfirmationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Confirms a checkout with the backend (which checks Stripe) and returns the up-to-date payment.

  PaymentConfirmationProvider call(String paymentId) =>
      PaymentConfirmationProvider._(argument: paymentId, from: this);

  @override
  String toString() => r'paymentConfirmationProvider';
}

@ProviderFor(paymentLedger)
final paymentLedgerProvider = PaymentLedgerFamily._();

final class PaymentLedgerProvider
    extends
        $FunctionalProvider<
          AsyncValue<PaymentLedger>,
          PaymentLedger,
          FutureOr<PaymentLedger>
        >
    with $FutureModifier<PaymentLedger>, $FutureProvider<PaymentLedger> {
  PaymentLedgerProvider._({
    required PaymentLedgerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'paymentLedgerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$paymentLedgerHash();

  @override
  String toString() {
    return r'paymentLedgerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PaymentLedger> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PaymentLedger> create(Ref ref) {
    final argument = this.argument as String;
    return paymentLedger(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PaymentLedgerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$paymentLedgerHash() => r'4065febe509a9eb0253f1b2051e3e4f89b69963c';

final class PaymentLedgerFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PaymentLedger>, String> {
  PaymentLedgerFamily._()
    : super(
        retry: null,
        name: r'paymentLedgerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PaymentLedgerProvider call(String paymentId) =>
      PaymentLedgerProvider._(argument: paymentId, from: this);

  @override
  String toString() => r'paymentLedgerProvider';
}

/// An installment plan by id. With an empty id (opened from the menu), finds the first
/// of the citizen's payments that has a plan. Throws [InstallmentPlanNotFound] if none.

@ProviderFor(installmentPlan)
final installmentPlanProvider = InstallmentPlanFamily._();

/// An installment plan by id. With an empty id (opened from the menu), finds the first
/// of the citizen's payments that has a plan. Throws [InstallmentPlanNotFound] if none.

final class InstallmentPlanProvider
    extends
        $FunctionalProvider<
          AsyncValue<InstallmentPlan>,
          InstallmentPlan,
          FutureOr<InstallmentPlan>
        >
    with $FutureModifier<InstallmentPlan>, $FutureProvider<InstallmentPlan> {
  /// An installment plan by id. With an empty id (opened from the menu), finds the first
  /// of the citizen's payments that has a plan. Throws [InstallmentPlanNotFound] if none.
  InstallmentPlanProvider._({
    required InstallmentPlanFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'installmentPlanProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$installmentPlanHash();

  @override
  String toString() {
    return r'installmentPlanProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<InstallmentPlan> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<InstallmentPlan> create(Ref ref) {
    final argument = this.argument as String;
    return installmentPlan(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is InstallmentPlanProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$installmentPlanHash() => r'eb87f0bd2efc49d7acaff24781128736b70e66fd';

/// An installment plan by id. With an empty id (opened from the menu), finds the first
/// of the citizen's payments that has a plan. Throws [InstallmentPlanNotFound] if none.

final class InstallmentPlanFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<InstallmentPlan>, String> {
  InstallmentPlanFamily._()
    : super(
        retry: null,
        name: r'installmentPlanProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// An installment plan by id. With an empty id (opened from the menu), finds the first
  /// of the citizen's payments that has a plan. Throws [InstallmentPlanNotFound] if none.

  InstallmentPlanProvider call(String planId) =>
      InstallmentPlanProvider._(argument: planId, from: this);

  @override
  String toString() => r'installmentPlanProvider';
}

/// The department account citizens transfer installments into.

@ProviderFor(bankDetails)
final bankDetailsProvider = BankDetailsProvider._();

/// The department account citizens transfer installments into.

final class BankDetailsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, String>>,
          Map<String, String>,
          FutureOr<Map<String, String>>
        >
    with
        $FutureModifier<Map<String, String>>,
        $FutureProvider<Map<String, String>> {
  /// The department account citizens transfer installments into.
  BankDetailsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bankDetailsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bankDetailsHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, String>> create(Ref ref) {
    return bankDetails(ref);
  }
}

String _$bankDetailsHash() => r'541a613abe755e3fb2ea6a9f66f9f7ac6e5d1c73';
