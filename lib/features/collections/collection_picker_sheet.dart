import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/collections_repository.dart';
import '../../l10n/app_localizations.dart';

/// Bottom sheet to add/remove a tip to/from collections, and create new ones.
Future<void> showCollectionPicker(BuildContext context, String tipId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _CollectionPickerSheet(tipId: tipId),
  );
}

class _CollectionPickerSheet extends ConsumerStatefulWidget {
  const _CollectionPickerSheet({required this.tipId});
  final String tipId;

  @override
  ConsumerState<_CollectionPickerSheet> createState() => _SheetState();
}

class _SheetState extends ConsumerState<_CollectionPickerSheet> {
  final _newName = TextEditingController();

  @override
  void dispose() {
    _newName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final collections = ref.watch(collectionsProvider);
    final ctrl = ref.read(collectionsProvider.notifier);
    final inIds = ctrl.idsFor(widget.tipId);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.addToCollection,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final c in collections)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(c.name),
                    value: inIds.contains(c.id),
                    onChanged: (checked) {
                      if (checked ?? false) {
                        ctrl.addTip(c.id, widget.tipId);
                      } else {
                        ctrl.removeTip(c.id, widget.tipId);
                      }
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newName,
                  decoration: InputDecoration(hintText: l.newCollection),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () async {
                  final name = _newName.text.trim();
                  if (name.isEmpty) return;
                  final id = await ctrl.create(name);
                  await ctrl.addTip(id, widget.tipId);
                  _newName.clear();
                },
                child: Text(l.createAction),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
