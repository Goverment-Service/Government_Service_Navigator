// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide auth session. Kept alive for the whole app run so every screen and
/// service provider can read the token instead of having it passed down by hand.

@ProviderFor(Session)
final sessionProvider = SessionProvider._();

/// App-wide auth session. Kept alive for the whole app run so every screen and
/// service provider can read the token instead of having it passed down by hand.
final class SessionProvider extends $NotifierProvider<Session, SessionState> {
  /// App-wide auth session. Kept alive for the whole app run so every screen and
  /// service provider can read the token instead of having it passed down by hand.
  SessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionHash();

  @$internal
  @override
  Session create() => Session();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionState>(value),
    );
  }
}

String _$sessionHash() => r'e73f8b1099f06889a2f8c4a7a6a1a4d5902536c5';

/// App-wide auth session. Kept alive for the whole app run so every screen and
/// service provider can read the token instead of having it passed down by hand.

abstract class _$Session extends $Notifier<SessionState> {
  SessionState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SessionState, SessionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SessionState, SessionState>,
              SessionState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Just the bearer token. Service providers watch this so they rebuild on login/logout.

@ProviderFor(authToken)
final authTokenProvider = AuthTokenProvider._();

/// Just the bearer token. Service providers watch this so they rebuild on login/logout.

final class AuthTokenProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// Just the bearer token. Service providers watch this so they rebuild on login/logout.
  AuthTokenProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authTokenProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authTokenHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return authToken(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$authTokenHash() => r'bf2a2fe2a88a76fc4ccc4d6012cf039865d4e8a5';
