import 'package:flutter/material.dart';

import '../animals/hints.dart';
import '../animals/lookup.dart';
import '../data/model.dart';
import 'pixel_icon.dart';
import 'theme.dart';

const _lockedHint = 'Not met yet. Anything can turn up on any outing.';

class CollectionPage extends StatefulWidget {
  const CollectionPage({
    super.key,
    required this.sightings,
    required this.opened,
    required this.onSettings,
    required this.onClose,
    required this.onOpen,
    this.timeZone,
  });

  final List<Sighting> sightings;
  final Set<String> opened;
  final VoidCallback onSettings;
  final VoidCallback onClose;
  final void Function(String entryId) onOpen;
  final String? timeZone;

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  AnimalEntry? _card;

  bool _shown(AnimalEntry entry, Set<String> met) {
    final legend = entry.legend;
    if (legend == null || !legend.isRegional) return true;
    return met.contains(entry.id) || legend.matchesZone(widget.timeZone);
  }

  @override
  Widget build(BuildContext context) {
    final met = {for (final s in widget.sightings) s.animal};
    final cells = <Widget>[
      for (final entry in animalEntries)
        if (_shown(entry, met))
          _Cell(
            entry: entry,
            found: met.contains(entry.id),
            isNew: met.contains(entry.id) && !widget.opened.contains(entry.id),
            hinted: hintUnlocked(entry, met: met, timeZone: widget.timeZone),
            onTap: met.contains(entry.id)
                ? () => widget.onOpen(entry.id)
                : () => setState(() => _card = entry),
          ),
    ];
    final card = _card;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Material(
      color: Wild.parchment,
      child: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                PageTopBar(
                  onSettings: widget.onSettings,
                  onClose: widget.onClose,
                ),
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
          if (card != null)
            _HintCard(
              entry: card,
              hint: hintFor(card, met: met, timeZone: widget.timeZone),
              onClose: () => setState(() => _card = null),
            ),
        ],
      ),
    );
  }
}

class _Silhouette extends StatelessWidget {
  const _Silhouette(this.entry);

  final AnimalEntry entry;

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      key: ValueKey('silhouette-${entry.id}'),
      colorFilter: ColorFilter.mode(
        Wild.ink.withValues(alpha: 0.75),
        BlendMode.srcIn,
      ),
      child: Image.asset(
        'assets/sprites/${entry.frames[0]}.png',
        width: 96,
        height: 96,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.none,
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({
    required this.entry,
    required this.hint,
    required this.onClose,
  });

  final AnimalEntry entry;
  final String? hint;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            key: const ValueKey('hint-scrim'),
            behavior: HitTestBehavior.opaque,
            onTap: onClose,
            child: ColoredBox(color: Wild.night.withValues(alpha: 0.6)),
          ),
        ),
        Center(
          child: Container(
            key: const ValueKey('hint-card'),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Wild.parchment,
              border: Border.all(color: Wild.outline, width: 3),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 24, 18, 22),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hint != null) _Silhouette(entry),
                        const SizedBox(height: 6),
                        Text('???', style: pixelText(30, color: Wild.forest)),
                        const SizedBox(height: 10),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 232),
                          child: Text(
                            hint ?? _lockedHint,
                            textAlign: TextAlign.center,
                            style: bodyText(15, italic: true),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Semantics(
                    button: true,
                    label: 'Close',
                    child: GestureDetector(
                      key: const ValueKey('hint-close'),
                      behavior: HitTestBehavior.opaque,
                      onTap: onClose,
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: PixelIcon('close', color: Wild.bark),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.entry,
    required this.found,
    required this.isNew,
    required this.hinted,
    required this.onTap,
  });

  final AnimalEntry entry;
  final bool found;
  final bool isNew;
  final bool hinted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = found ? entry.name : '???';
    final sprite = found
        ? Image.asset(
            'assets/sprites/${entry.frames[0]}.png',
            width: 96,
            height: 96,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.none,
          )
        : hinted
        ? _Silhouette(entry)
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
      button: true,
      label: found
          ? (isNew ? '$name, new' : name)
          : (hinted ? 'Not met yet, hint available' : 'Not met yet'),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: cell,
      ),
    );
  }
}
