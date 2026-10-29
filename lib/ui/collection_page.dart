import 'package:flutter/material.dart';

import '../animals/lookup.dart';
import '../data/model.dart';
import 'theme.dart';

class CollectionPage extends StatelessWidget {
  const CollectionPage({
    super.key,
    required this.sightings,
    required this.opened,
    required this.onSettings,
    required this.onClose,
    required this.onOpen,
  });

  final List<Sighting> sightings;
  final Set<String> opened;
  final VoidCallback onSettings;
  final VoidCallback onClose;
  final void Function(String entryId) onOpen;

  @override
  Widget build(BuildContext context) {
    final met = {for (final s in sightings) s.animal};
    final cells = <Widget>[
      for (final entry in animalEntries)
        _Cell(
          entry: entry,
          found: met.contains(entry.id),
          isNew: met.contains(entry.id) && !opened.contains(entry.id),
          onTap: () => onOpen(entry.id),
        ),
    ];
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Material(
      color: Wild.parchment,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageTopBar(onSettings: onSettings, onClose: onClose),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 0,
                childAspectRatio: 109.33 / 113,
                padding: EdgeInsets.fromLTRB(16, 0, 16, 24 + bottom),
                children: cells,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.entry,
    required this.found,
    required this.isNew,
    this.onTap,
  });

  final AnimalEntry entry;
  final bool found;
  final bool isNew;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final name = found ? entry.name : '???';
    final sprite = found
        ? Image.asset(
            'assets/sprites/${entry.base.frames[0]}.png',
            width: 96,
            height: 96,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.none,
          )
        : SizedBox(
            width: 96,
            height: 96,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  '?',
                  style: pixelText(26, color: Wild.bark.withValues(alpha: 0.3)),
                ),
              ),
            ),
          );
    final cell = Stack(
      fit: StackFit.expand,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            sprite,
            Text(
              name,
              textAlign: TextAlign.center,
              style: pixelText(
                14,
                color: found ? Wild.ink : Wild.bark.withValues(alpha: 0.45),
              ).copyWith(height: 17 / 14),
            ),
          ],
        ),
        if (isNew)
          Positioned(
            top: 6,
            right: 14,
            child: Container(
              key: const ValueKey('new-dot'),
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Wild.ember,
                border: Border.all(color: Wild.outline, width: 3),
              ),
            ),
          ),
      ],
    );
    return Semantics(
      button: found,
      label: found ? (isNew ? '$name, new' : name) : 'Not met yet',
      excludeSemantics: true,
      child: found
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: cell,
            )
          : cell,
    );
  }
}
