// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ApprovalLikelihoodController)
final approvalLikelihoodControllerProvider =
    ApprovalLikelihoodControllerProvider._();

final class ApprovalLikelihoodControllerProvider
    extends
        $AsyncNotifierProvider<
          ApprovalLikelihoodController,
          ApprovalLikelihood?
        > {
  ApprovalLikelihoodControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'approvalLikelihoodControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$approvalLikelihoodControllerHash();

  @$internal
  @override
  ApprovalLikelihoodController create() => ApprovalLikelihoodController();
}

String _$approvalLikelihoodControllerHash() =>
    r'c899afd2bff4b4afb827df6bd099812fe787421f';

abstract class _$ApprovalLikelihoodController
    extends $AsyncNotifier<ApprovalLikelihood?> {
  FutureOr<ApprovalLikelihood?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ApprovalLikelihood?>, ApprovalLikelihood?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ApprovalLikelihood?>, ApprovalLikelihood?>,
              AsyncValue<ApprovalLikelihood?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(EligibilityCheckController)
final eligibilityCheckControllerProvider =
    EligibilityCheckControllerProvider._();

final class EligibilityCheckControllerProvider
    extends
        $AsyncNotifierProvider<
          EligibilityCheckController,
          EligibilityAgentResponse?
        > {
  EligibilityCheckControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'eligibilityCheckControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$eligibilityCheckControllerHash();

  @$internal
  @override
  EligibilityCheckController create() => EligibilityCheckController();
}

String _$eligibilityCheckControllerHash() =>
    r'6d35654e1cfae7866476c83914dd377010b72bba';

abstract class _$EligibilityCheckController
    extends $AsyncNotifier<EligibilityAgentResponse?> {
  FutureOr<EligibilityAgentResponse?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<EligibilityAgentResponse?>,
              EligibilityAgentResponse?
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<EligibilityAgentResponse?>,
                EligibilityAgentResponse?
              >,
              AsyncValue<EligibilityAgentResponse?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(IntakeAgentController)
final intakeAgentControllerProvider = IntakeAgentControllerProvider._();

final class IntakeAgentControllerProvider
    extends $AsyncNotifierProvider<IntakeAgentController, IntakePlanModel?> {
  IntakeAgentControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'intakeAgentControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$intakeAgentControllerHash();

  @$internal
  @override
  IntakeAgentController create() => IntakeAgentController();
}

String _$intakeAgentControllerHash() =>
    r'413a5cd7f1ea08efe7fc6125be0a83ae4a47bf22';

abstract class _$IntakeAgentController
    extends $AsyncNotifier<IntakePlanModel?> {
  FutureOr<IntakePlanModel?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<IntakePlanModel?>, IntakePlanModel?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<IntakePlanModel?>, IntakePlanModel?>,
              AsyncValue<IntakePlanModel?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
