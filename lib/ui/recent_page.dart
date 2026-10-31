import 'package:flutter/material.dart';

import '../data/model.dart';
import '../animals/lookup.dart';
import 'animal_page.dart';
import 'animal_sprite.dart';
import 'theme.dart';

const recentDays = 7;

class RecentPage extends StatelessWidget {
  const RecentPage({
    super.key,
    required this.waiting,
    required this.sightings,
    required this.miles,
    required this.onClose,
    required this.onSettings,
    this.now,
  });

  final List<Outing> waiting;
  final List<Sighting> sightings;
  final bool miles;
  final VoidCallback onClose;
  final VoidCallback onSettings;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final cutoff = (now ?? DateTime.now()).subtract(
      const Duration(days: recentDays),
    );
    final rows = [
      for (final o in waiting)
        (outing: o, animal: null as String?, hat: null as String?),
      for (final s in sightings)
        if (!s.outing.start.isBefore(cutoff))
          (outing: s.outing, animal: s.animal, hat: s.hat),
    ]..sort((a, b) => b.outing.start.compareTo(a.outing.start));
    return Material(
      color: Wild.parchment,
      child: SafeArea(
        child: Column(
          children: [
            PageTopBar(onClose: onClose, onSettings: onSettings),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 10),
                    child: Text(
                      'Recent',
                      style: pixelText(26, color: Wild.forest),
                    ),
                  ),
                  if (rows.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Nothing in the last week. Pull down on the scene to look for new ones.',
                        style: bodyText(15, color: Wild.bark),
                      ),
                    ),
                  for (final r in rows)
                    _OutingRow(r.outing, r.animal, r.hat, miles),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutingRow extends StatelessWidget {
  const _OutingRow(this.outing, this.animal, this.hat, this.miles);

  final Outing outing;
  final String? animal;
  final String? hat;
  final bool miles;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DottedRule(color: Wild.bark.withValues(alpha: 0.35)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meetingWhen(outing.start),
                      style: numberText(13, color: Wild.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      outingMeta(outing, miles: miles),
                      style: bodyText(13, color: Wild.bark),
                    ),
                    if (animal == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'waiting in the bushes',
                          style: pixelText(11, color: Wild.ember),
                        ),
                      ),
                  ],
                ),
              ),
              animal == null
                  ? Image.asset(
                      'assets/sprites/bush.png',
                      width: 64,
                      height: 64,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.none,
                    )
                  : AnimalSprite(
                      entry: entryOrDefault(animal!),
                      size: 64,
                      hatId: hat,
                    ),
            ],
          ),
        ),
      ],
    );
  }
}
