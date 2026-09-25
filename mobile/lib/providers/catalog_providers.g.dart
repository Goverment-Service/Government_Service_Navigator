// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every published government service. Kept alive: the catalog is shared by the
/// home, services and discovery screens and rarely changes during a session.

@ProviderFor(services)
final servicesProvider = ServicesProvider._();

/// Every published government service. Kept alive: the catalog is shared by the
/// home, services and discovery screens and rarely changes during a session.

final class ServicesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Map<String, dynamic>>>,
          List<Map<String, dynamic>>,
          FutureOr<List<Map<String, dynamic>>>
        >
    with
        $FutureModifier<List<Map<String, dynamic>>>,
        $FutureProvider<List<Map<String, dynamic>>> {
  /// Every published government service. Kept alive: the catalog is shared by the
  /// home, services and discovery screens and rarely changes during a session.
  ServicesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'servicesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$servicesHash();

  @$internal
  @override
  $FutureProviderElement<List<Map<String, dynamic>>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Map<String, dynamic>>> create(Ref ref) {
    return services(ref);
  }
}

String _$servicesHash() => r'a2c6ff0b151a0b21f7def1dff1ce3e1cba76386e';

/// Active services grouped by department (the service's `category`), departments sorted by name.

@ProviderFor(departments)
final departmentsProvider = DepartmentsProvider._();

/// Active services grouped by department (the service's `category`), departments sorted by name.

final class DepartmentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, List<Map<String, dynamic>>>>,
          Map<String, List<Map<String, dynamic>>>,
          FutureOr<Map<String, List<Map<String, dynamic>>>>
        >
    with
        $FutureModifier<Map<String, List<Map<String, dynamic>>>>,
        $FutureProvider<Map<String, List<Map<String, dynamic>>>> {
  /// Active services grouped by department (the service's `category`), departments sorted by name.
  DepartmentsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'departmentsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$departmentsHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, List<Map<String, dynamic>>>>
  $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, List<Map<String, dynamic>>>> create(Ref ref) {
    return departments(ref);
  }
}

String _$departmentsHash() => r'309fe5634184fe5701faa2f6c9de3fe6a25225b3';

@ProviderFor(serviceDetails)
final serviceDetailsProvider = ServiceDetailsFamily._();

final class ServiceDetailsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, dynamic>>,
          Map<String, dynamic>,
          FutureOr<Map<String, dynamic>>
        >
    with
        $FutureModifier<Map<String, dynamic>>,
        $FutureProvider<Map<String, dynamic>> {
  ServiceDetailsProvider._({
    required ServiceDetailsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'serviceDetailsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$serviceDetailsHash();

  @override
  String toString() {
    return r'serviceDetailsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Map<String, dynamic>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, dynamic>> create(Ref ref) {
    final argument = this.argument as int;
    return serviceDetails(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ServiceDetailsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$serviceDetailsHash() => r'd61d751aad1479b737f792b7967a4ab900a7c286';

final class ServiceDetailsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Map<String, dynamic>>, int> {
  ServiceDetailsFamily._()
    : super(
        retry: null,
        name: r'serviceDetailsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ServiceDetailsProvider call(int serviceId) =>
      ServiceDetailsProvider._(argument: serviceId, from: this);

  @override
  String toString() => r'serviceDetailsProvider';
}

/// Admin-built application form for a service, or null if none is published yet.

@ProviderFor(applicationForm)
final applicationFormProvider = ApplicationFormFamily._();

/// Admin-built application form for a service, or null if none is published yet.

final class ApplicationFormProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, dynamic>?>,
          Map<String, dynamic>?,
          FutureOr<Map<String, dynamic>?>
        >
    with
        $FutureModifier<Map<String, dynamic>?>,
        $FutureProvider<Map<String, dynamic>?> {
  /// Admin-built application form for a service, or null if none is published yet.
  ApplicationFormProvider._({
    required ApplicationFormFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'applicationFormProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$applicationFormHash();

  @override
  String toString() {
    return r'applicationFormProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Map<String, dynamic>?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, dynamic>?> create(Ref ref) {
    final argument = this.argument as int;
    return applicationForm(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ApplicationFormProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$applicationFormHash() => r'7cef5868a379d3ee756470cf75d46bd3f01744be';

/// Admin-built application form for a service, or null if none is published yet.

final class ApplicationFormFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Map<String, dynamic>?>, int> {
  ApplicationFormFamily._()
    : super(
        retry: null,
        name: r'applicationFormProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Admin-built application form for a service, or null if none is published yet.

  ApplicationFormProvider call(int serviceId) =>
      ApplicationFormProvider._(argument: serviceId, from: this);

  @override
  String toString() => r'applicationFormProvider';
}

@ProviderFor(applicationFormData)
final applicationFormDataProvider = ApplicationFormDataFamily._();

final class ApplicationFormDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<ApplicationFormData>,
          ApplicationFormData,
          FutureOr<ApplicationFormData>
        >
    with
        $FutureModifier<ApplicationFormData>,
        $FutureProvider<ApplicationFormData> {
  ApplicationFormDataProvider._({
    required ApplicationFormDataFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'applicationFormDataProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$applicationFormDataHash();

  @override
  String toString() {
    return r'applicationFormDataProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ApplicationFormData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ApplicationFormData> create(Ref ref) {
    final argument = this.argument as int;
    return applicationFormData(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ApplicationFormDataProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$applicationFormDataHash() =>
    r'd32e59c684fb15c013e5aed0d3915edaf3fbd902';

final class ApplicationFormDataFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ApplicationFormData>, int> {
  ApplicationFormDataFamily._()
    : super(
        retry: null,
        name: r'applicationFormDataProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ApplicationFormDataProvider call(int serviceId) =>
      ApplicationFormDataProvider._(argument: serviceId, from: this);

  @override
  String toString() => r'applicationFormDataProvider';
}
