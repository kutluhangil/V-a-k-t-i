import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../data/models/tip.dart';
import '../widgets/share_card.dart';

/// Renders a tip into a 4:5 PNG and opens the system share sheet (§9.2).
class ShareService {
  const ShareService();

  Future<void> shareTip(BuildContext context, Tip tip, String lang) async {
    final controller = ScreenshotController();
    final bytes = await controller.captureFromWidget(
      ShareCard(tip: tip, lang: lang),
      context: context,
      pixelRatio: 1,
      targetSize: ShareCard.size,
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/vakti_${tip.id}.png');
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'Vakti'),
    );
  }
}

final shareService = ShareService();
