// App-scoped providers — registries that live for the lifetime of the process.
// Per system-architecture.md these are app-scope: read-only after boot, shared
// across all kids on the device.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/activity_registry.dart';
import '../data/concept_registry.dart';

final activityRegistryProvider = FutureProvider<ActivityRegistry>((ref) async {
  return ActivityRegistry.loadKindergarten();
});

final conceptRegistryProvider = FutureProvider<ConceptRegistry>((ref) async {
  return ConceptRegistry.loadKindergarten();
});
