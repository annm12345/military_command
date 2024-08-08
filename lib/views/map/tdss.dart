import 'package:latlong2/latlong.dart';

class TacticalEvaluation {
  final double terrainDifficulty; // Higher value means more difficult terrain
  final double visibility; // Lower value means poorer visibility
  final double threatLevel; // Higher value means more threats
  final double cover; // Higher value means better cover

  TacticalEvaluation({
    required this.terrainDifficulty,
    required this.visibility,
    required this.threatLevel,
    required this.cover,
  });

  double get tacticalScore {
    // Simple formula to calculate a tactical score; you can adjust the weights as needed
    return (terrainDifficulty * 0.3) + (visibility * 0.2) + (threatLevel * 0.3) + (cover * 0.2);
  }
}

TacticalEvaluation evaluateTacticalSituation(LatLng location) {
  // Dummy data for demonstration purposes; replace with real evaluations
  return TacticalEvaluation(
    terrainDifficulty: 2.0, // Example value
    visibility: 3.0, // Example value
    threatLevel: 1.5, // Example value
    cover: 4.0, // Example value
  );
}
