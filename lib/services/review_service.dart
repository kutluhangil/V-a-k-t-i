import 'package:in_app_review/in_app_review.dart';

/// In-app rating prompt. Uses the native Play in-app review flow when available
/// (quota-limited by Google), otherwise falls back to the store listing.
class ReviewService {
  ReviewService();

  final InAppReview _inAppReview = InAppReview.instance;

  Future<void> request() async {
    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
      } else {
        await _inAppReview.openStoreListing();
      }
    } catch (_) {
      // Best-effort; never crash the settings screen over a review prompt.
    }
  }
}

final reviewService = ReviewService();
