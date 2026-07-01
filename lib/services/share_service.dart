import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../app/theme/app_colors.dart';
import '../data/models/tip.dart';
import '../l10n/app_localizations.dart';
import '../widgets/share_card.dart';

/// Renders a tip into a branded PNG and opens the system share sheet (§9.2).
/// The user first picks an aspect ratio (Post 4:5 / Story 9:16 / Square 1:1).
class ShareService {
  const ShareService();

  Future<void> shareTip(BuildContext context, Tip tip, String lang) async {
    final format = await _pickFormat(context);
    if (format == null || !context.mounted) return;
    await _renderAndShare(context, tip, lang, format);
  }

  Future<ShareFormat?> _pickFormat(BuildContext context) {
    final l = AppLocalizations.of(context);
    return showModalBottomSheet<ShareFormat>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l.shareFormatTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            _FormatTile(
              format: ShareFormat.post,
              label: l.shareFormatPost,
              ratio: 4 / 5,
            ),
            _FormatTile(
              format: ShareFormat.story,
              label: l.shareFormatStory,
              ratio: 9 / 16,
            ),
            _FormatTile(
              format: ShareFormat.square,
              label: l.shareFormatSquare,
              ratio: 1,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _renderAndShare(
    BuildContext context,
    Tip tip,
    String lang,
    ShareFormat format,
  ) async {
    final controller = ScreenshotController();
    final bytes = await controller.captureFromWidget(
      ShareCard(tip: tip, lang: lang, format: format),
      context: context,
      pixelRatio: 1,
      targetSize: format.size,
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/vakti_${tip.id}_${format.name}.png');
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'Vakti'),
    );
  }
}

/// A single format row: a mini preview rect in the correct ratio + label.
class _FormatTile extends StatelessWidget {
  const _FormatTile({
    required this.format,
    required this.label,
    required this.ratio,
  });

  final ShareFormat format;
  final String label;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => Navigator.of(context).pop(format),
      leading: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: AspectRatio(
            aspectRatio: ratio,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.saffron, width: 1.5),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ),
      title: Text(label),
    );
  }
}

final shareService = ShareService();
