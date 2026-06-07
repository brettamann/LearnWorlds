// ConceptRegistry — in-memory snapshot of concept-registry/<grade>.json.

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/concept.dart';
import 'asset_paths.dart';

class ConceptRegistry {
  const ConceptRegistry({
    required this.version,
    required this.concepts,
  });

  final int version;
  final List<Concept> concepts;

  Concept byId(String id) => concepts.firstWhere(
        (c) => c.id == id,
        orElse: () => throw StateError('No concept registered with id "$id"'),
      );

  static Future<ConceptRegistry> loadKindergarten() async {
    final raw =
        await rootBundle.loadString(AssetPaths.kindergartenConceptRegistry);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return ConceptRegistry(
      version: json['version'] as int,
      concepts: (json['concepts'] as List<dynamic>)
          .map((e) => Concept.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}
