import 'package:flutter/material.dart';

import '../animals/lookup.dart';
import '../data/model.dart';
import 'theme.dart';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String meetingWhen(DateTime t) {
  final minute = t.minute.toString().padLeft(2, '0');
  return '${_weekdays[t.weekday - 1]} ${t.day} ${_months[t.month - 1]}, ${t.hour}:$minute';
}

class AnimalPage extends StatefulWidget {
  const AnimalPage({
    super.key,
    required this.entry,
    required this.meetings,
    required this.miles,
    required this.onClose,
  });

  final AnimalEntry entry;
  final List<Sighting> meetings;
  final bool miles;
  final VoidCallback onClose;

  @override
  State<AnimalPage> createState() => _AnimalPageState();
}

class _AnimalPageState extends State<AnimalPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _walk = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _walk.stop();
    } else if (!_walk.isAnimating) {
      _walk.repeat();
    }
  }

  @override
  void dispose() {
    _walk.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frames = widget.entry.frames;
    final meetings = [...widget.meetings]
      ..sort((a, b) => b.outing.start.compareTo(a.outing.start));
    final count = meetings.length;
    return Material(
      color: Wild.parchment,
      child: SafeArea(
        child: Column(
          children: [
            PageTopBar(onClose: widget.onClose),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: SizedBox(
                        width: 192,
                        height: 192,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 21,
                              bottom: 0,
                              width: 150,
                              height: 14,
                              child: ColoredBox(
                                color: Wild.outline.withValues(alpha: 0.16),
                              ),
                            ),
                            AnimatedBuilder(
                              animation: _walk,
                              builder: (context, _) => Image.asset(
                                'assets/sprites/${frames[(_walk.value * frames.length).floor() % frames.length]}.png',
                                width: 192,
                                height: 192,
                                fit: BoxFit.fill,
                                filterQuality: FilterQuality.none,
                                gaplessPlayback: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 14, bottom: 6),
                      child: Text(
                        widget.entry.name,
                        style: pixelText(
                          32,
                          color: Wild.forest,
                        ).copyWith(height: 1),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: Text(
                        entryNote(widget.entry),
                        textAlign: TextAlign.center,
                        style: bodyText(15, italic: true),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              count == 1 ? 'Met once' : 'Met $count times',
                              style: numberText(14, color: Wild.bark),
                            ),
                          ),
                          for (var i = 0; i < count; i++)
                            _Meeting(
                              meetings[i],
                              widget.miles,
                              first: i == count - 1,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Meeting extends StatelessWidget {
  const _Meeting(this.sighting, this.miles, {required this.first});

  final Sighting sighting;
  final bool miles;
  final bool first;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DottedRule(color: Wild.bark.withValues(alpha: 0.35)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: meetingWhen(sighting.outing.start)),
                      if (first)
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Text(
                              'first met',
                              style: pixelText(11, color: Wild.ember),
                            ),
                          ),
                        ),
                    ],
                  ),
                  style: numberText(13),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                outingMeta(sighting.outing, miles: miles),
                style: bodyText(13, color: Wild.bark),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
