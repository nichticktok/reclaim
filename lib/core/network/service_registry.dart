import 'package:flutter/foundation.dart';

enum ServiceId {
  gateway,
  auth,
  userProfile,
  program,
  reflection,
  community,
  reporting,
}

class ServiceEndpoint {
  const ServiceEndpoint({
    required this.baseUri,
    this.timeout = const Duration(seconds: 15),
    this.defaultHeaders = const {},
  });

  final Uri baseUri;
  final Duration timeout;
  final Map<String, String> defaultHeaders;

  ServiceEndpoint copyWith({
    Uri? baseUri,
    Duration? timeout,
    Map<String, String>? defaultHeaders,
  }) {
    return ServiceEndpoint(
      baseUri: baseUri ?? this.baseUri,
      timeout: timeout ?? this.timeout,
      defaultHeaders: defaultHeaders ?? this.defaultHeaders,
    );
  }
}

class ServiceRegistry {
  ServiceRegistry({Map<ServiceId, ServiceEndpoint>? overrides})
    : _endpoints = Map<ServiceId, ServiceEndpoint>.from(_defaultEndpoints) {
    if (overrides != null) {
      _endpoints.addAll(overrides);
    }
  }

  final Map<ServiceId, ServiceEndpoint> _endpoints;

  ServiceEndpoint endpoint(ServiceId id) {
    final endpoint = _endpoints[id];
    if (endpoint == null) {
      throw ArgumentError('No endpoint registered for $id');
    }
    return endpoint;
  }

  static Map<ServiceId, ServiceEndpoint> get _defaultEndpoints => {
    ServiceId.gateway: ServiceEndpoint(
      baseUri: Uri.parse(_env('GATEWAY_URL', 'https://api.recalim.com')),
    ),
    ServiceId.auth: ServiceEndpoint(
      baseUri: Uri.parse(
        _env('AUTH_SERVICE_URL', 'https://api.recalim.com/auth'),
      ),
    ),
    ServiceId.userProfile: ServiceEndpoint(
      baseUri: Uri.parse(
        _env('USER_PROFILE_SERVICE_URL', 'https://api.recalim.com/profile'),
      ),
    ),
    ServiceId.program: ServiceEndpoint(
      baseUri: Uri.parse(
        _env('PROGRAM_SERVICE_URL', 'https://api.recalim.com/programs'),
      ),
    ),
    ServiceId.reflection: ServiceEndpoint(
      baseUri: Uri.parse(
        _env('REFLECTION_SERVICE_URL', 'https://api.recalim.com/reflections'),
      ),
    ),
    ServiceId.community: ServiceEndpoint(
      baseUri: Uri.parse(
        _env('COMMUNITY_SERVICE_URL', 'https://api.recalim.com/community'),
      ),
    ),
    ServiceId.reporting: ServiceEndpoint(
      baseUri: Uri.parse(
        _env('REPORTING_SERVICE_URL', 'https://api.recalim.com/reporting'),
      ),
    ),
  };

  static String _env(String key, String fallback) {
    final overrides = String.fromEnvironment(
      'SERVICE_OVERRIDES',
      defaultValue: '',
    );
    if (overrides.isNotEmpty) {
      debugPrint('SERVICE_OVERRIDES: $overrides');
    }
    final value = String.fromEnvironment(key, defaultValue: '');
    return value.isNotEmpty ? value : fallback;
  }
}
