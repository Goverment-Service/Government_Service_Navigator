// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether this device has finished onboarding (slides, terms, first sign-in).

@ProviderFor(onboardingCompleted)
final onboardingCompletedProvider = OnboardingCompletedProvider._();

/// Whether this device has finished onboarding (slides, terms, first sign-in).

final class OnboardingCompletedProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether this device has finished onboarding (slides, terms, first sign-in).
  OnboardingCompletedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingCompletedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingCompletedHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return onboardingCompleted(ref);
  }
}

String _$onboardingCompletedHash() =>
    r'b88fd50397968c32c30685bb50c30e637f9a4b32';

/// Login / sign-up actions. The state is the in-flight request: `isLoading` while
/// talking to the server, `AsyncError` carrying the message to show on failure.

@ProviderFor(AuthController)
final authControllerProvider = AuthControllerProvider._();

/// Login / sign-up actions. The state is the in-flight request: `isLoading` while
/// talking to the server, `AsyncError` carrying the message to show on failure.
final class AuthControllerProvider
    extends $AsyncNotifierProvider<AuthController, void> {
  /// Login / sign-up actions. The state is the in-flight request: `isLoading` while
  /// talking to the server, `AsyncError` carrying the message to show on failure.
  AuthControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authControllerHash();

  @$internal
  @override
  AuthController create() => AuthController();
}

String _$authControllerHash() => r'aa24f90a300616e157aa3b0a6fc977dc1b27cddc';

/// Login / sign-up actions. The state is the in-flight request: `isLoading` while
/// talking to the server, `AsyncError` carrying the message to show on failure.

abstract class _$AuthController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
