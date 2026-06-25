import 'content_pillar.dart';
import 'localized_text.dart';

/// Encyclopedic background detail shown in the full-screen detail view.
/// All fields are optional so older data without a detail block still works.
class TipDetail {
  /// How/where it originates — country, culture, historical note.
  final LocalizedText? origin;

  /// Practical preparation or usage steps.
  final LocalizedText? howToUse;

  /// One surprising / memorable fact.
  final LocalizedText? funFact;

  /// Flag + country name strings, e.g. ["🇮🇳 Hindistan", "🇨🇳 Çin"].
  /// For communication cards this holds the psychological / research basis note.
  final List<String>? countries;

  const TipDetail({this.origin, this.howToUse, this.funFact, this.countries});

  factory TipDetail.fromJson(Map<String, dynamic> j) => TipDetail(
    origin: j['origin'] != null
        ? LocalizedText.fromJson(j['origin'] as Map<String, dynamic>)
        : null,
    howToUse: j['howToUse'] != null
        ? LocalizedText.fromJson(j['howToUse'] as Map<String, dynamic>)
        : null,
    funFact: j['funFact'] != null
        ? LocalizedText.fromJson(j['funFact'] as Map<String, dynamic>)
        : null,
    countries: (j['countries'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList(),
  );
}

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
  final TipDetail? detail; // encyclopedic background (optional)

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
    this.detail,
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
    detail: j['detail'] != null
        ? TipDetail.fromJson(j['detail'] as Map<String, dynamic>)
        : null,
  );
}
