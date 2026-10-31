import 'package:flutter/widgets.dart';

import '../animals/lookup.dart';

class AnimalSprite extends StatelessWidget {
  const AnimalSprite({
    super.key,
    required this.entry,
    required this.size,
    this.hatId,
    this.frame = 0,
  });

  final AnimalEntry entry;
  final double size;
  final String? hatId;
  final int frame;

  @override
  Widget build(BuildContext context) {
    final hat = hatById(hatId);
    final head = entry.headPoints[frame % entry.headPoints.length];
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/sprites/${entry.frames[frame % entry.frames.length]}.png',
            fit: BoxFit.fill,
            filterQuality: FilterQuality.none,
            isAntiAlias: false,
            gaplessPlayback: true,
          ),
          if (hat != null)
            FittedBox(
              fit: BoxFit.fill,
              child: SizedBox(
                width: 32,
                height: 32,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: head.x + 0.5,
                      top: head.y + 1.0,
                      child: FractionalTranslation(
                        translation: const Offset(-0.5, -1),
                        child: Image.asset(
                          'assets/sprites/${hat.sprite}.png',
                          fit: BoxFit.none,
                          filterQuality: FilterQuality.none,
                          isAntiAlias: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
