import 'content_pillar.dart';
import 'localized_text.dart';

/// A single tip card. Carries both pillars' shape with one model:
/// wellness -> title = food/habit; communication -> title = phrase to say.
class Tip {
  final String id;
  final ContentPillar pillar;
  final String category; // category id (see categories.dart)
  final String emoji; // quick visual cue
  final LocalizedText title; // wellness: name / communication: sentence
  final LocalizedText primary; // the "when" line
  final LocalizedText secondary; // the "why" line
  final LocalizedText primaryLabel; // e.g. "Ne Zaman" / "When to Say It"
  final LocalizedText secondaryLabel; // e.g. "Neden" / "Why It Works"

  const Tip({
    required this.id,
    required this.pillar,
    required this.category,
    required this.emoji,
    required this.title,
    required this.primary,
    required this.secondary,
    required this.primaryLabel,
    required this.secondaryLabel,
  });

  factory Tip.fromJson(Map<String, dynamic> j) => Tip(
    id: j['id'] as String,
    pillar: ContentPillar.values.byName(j['pillar'] as String),
    category: j['category'] as String,
    emoji: j['emoji'] as String,
    title: LocalizedText.fromJson(j['title'] as Map<String, dynamic>),
    primary: LocalizedText.fromJson(j['primary'] as Map<String, dynamic>),
    secondary: LocalizedText.fromJson(j['secondary'] as Map<String, dynamic>),
    primaryLabel: LocalizedText.fromJson(
      j['primaryLabel'] as Map<String, dynamic>,
    ),
    secondaryLabel: LocalizedText.fromJson(
      j['secondaryLabel'] as Map<String, dynamic>,
    ),
  );
}
