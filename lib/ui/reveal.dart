import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../animals/animal.dart';
import '../data/model.dart';
import '../world/world_painter.dart';
import 'pixel_icon.dart';

const _parchment = Color(0xFFF3ECDC);
const _fern = Color(0xFF8FAE74);
const _ember = Color(0xFFC8672B);
const _forest = Color(0xFF1F3A2E);
const _bark = Color(0xFF5B4636);
const _ink = Color(0xFF2A2A22);
const _outline = Color(0xFF2E2218);
const _dimColor = Color(0xFF0B1510);
const _dimMax = 0.62;
const _silhouette = Color(0xE6000000);

const _shakeMs = 700;
const _hopAt = 750;
const _hopMs = 900;
const _colorAt = 1750;
const _wipeMs = 800;
const _textAt = 2650;
const _typeMs = 140;
const _leaveMs = 1400;
const _blinkMs = 600;
const _blinks = 2;
const _holdMs = 1200;

const _shake = [
  (0, 0),
  (84, 1),
  (175, -1),
  (259, 1),
  (350, -1),
  (434, 1),
  (525, -1),
];

const _heroScale = 2.1;
const _midScale = 1.5;
const _walkStop = Offset(40 / 3, 0);
const _walkEnd = Offset(190 / 3, 0);
const _walkTurn = 400;

TextStyle _text(
  double size,
  Color color, {
  FontWeight weight = FontWeight.w500,
  FontStyle? style,
}) => TextStyle(
  fontFamily: 'Tiny5',
  fontSize: size,
  fontWeight: weight,
  fontStyle: style,
  color: color,
  decoration: TextDecoration.none,
  height: 1.2,
);

TextStyle _bodyText(double size, Color color, {bool italic = false}) =>
    TextStyle(
      fontFamily: 'Roboto',
      fontSize: size,
      fontWeight: FontWeight.w400,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      color: color,
      decoration: TextDecoration.none,
      height: 1.2,
    );

TextStyle _numText(double size, Color color) => TextStyle(
  fontFamily: 'Roboto',
  fontSize: size,
  fontWeight: FontWeight.w600,
  color: color,
  decoration: TextDecoration.none,
  height: 1.2,
);

String _whenLabel(DateTime start, DateTime now) {
  final day = DateTime(start.year, start.month, start.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) {
    if (start.hour < 12) return 'this morning';
    if (start.hour < 18) return 'this afternoon';
    return 'this evening';
  }
  if (diff == 1) return 'yesterday';
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
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
  return '${days[start.weekday - 1]} ${start.day} ${months[start.month - 1]}';
}

class _FeetUp extends CustomClipper<Rect> {
  const _FeetUp(this.fraction);

  final double fraction;

  @override
  Rect getClip(Size s) =>
      Rect.fromLTWH(0, s.height * (1 - fraction), s.width, s.height * fraction);

  @override
  bool shouldReclip(_FeetUp old) => old.fraction != fraction;
}

class _Notch extends CustomClipper<Path> {
  const _Notch();

  @override
  Path getClip(Size s) => Path()
    ..moveTo(0, 3)
    ..lineTo(3, 3)
    ..lineTo(3, 0)
    ..lineTo(s.width - 3, 0)
    ..lineTo(s.width - 3, 3)
    ..lineTo(s.width, 3)
    ..lineTo(s.width, s.height - 3)
    ..lineTo(s.width - 3, s.height - 3)
    ..lineTo(s.width - 3, s.height)
    ..lineTo(3, s.height)
    ..lineTo(3, s.height - 3)
    ..lineTo(0, s.height - 3)
    ..close();

  @override
  bool shouldReclip(_Notch old) => false;
}

class RevealOverlay extends StatefulWidget {
  const RevealOverlay({
    super.key,
    required this.outing,
    required this.animal,
    required this.first,
    required this.timesMet,
    required this.miles,
    required this.bushTopLeft,
    required this.scale,
    required this.layout,
    required this.animate,
    required this.onClose,
    required this.onFinished,
    this.now,
  });

  final Outing outing;
  final Animal animal;
  final bool first;
  final int timesMet;
  final bool miles;
  final Offset bushTopLeft;
  final double scale;
  final Layout layout;
  final bool animate;
  final VoidCallback onClose;
  final VoidCallback onFinished;
  final DateTime? now;

  @override
  State<RevealOverlay> createState() => _RevealOverlayState();
}

class _RevealOverlayState extends State<RevealOverlay>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  int _ms = 0;
  final _cardKey = GlobalKey();
  int? _leaveAt;
  bool _finished = false;

  bool get _leaving => _leaveAt != null;
  int get _intro => widget.animate ? _ms : 1 << 30;
  int get _since => _ms - (_leaveAt ?? _ms);
  int get _leaveTotal =>
      widget.animate ? _leaveMs + _blinkMs * 2 * _blinks : _holdMs;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    _ms = elapsed.inMilliseconds;
    if (_leaving && !_finished && _since >= _leaveTotal) {
      _finished = true;
      _ticker.stop();
      setState(() {});
      widget.onFinished();
      return;
    }
    setState(() {});
  }

  void _close() {
    if (_leaving) return;
    _leaveAt = _ms;
    widget.onClose();
  }

  double _dim() {
    if (!widget.animate) return _leaving ? 0 : 1;
    if (_leaving) return math.max(0, 1 - (_since ~/ 100) / 5);
    return math.min(_intro ~/ 100, 5) / 5;
  }

  int _shakeX() {
    if (!widget.animate || _leaving || _intro >= _shakeMs) return 0;
    var x = 0;
    for (final (at, dx) in _shake) {
      if (_intro >= at) x = dx;
    }
    return x;
  }

  double _stepped(double f) => (f.clamp(0.0, 0.999999) * 9).floor() / 9;

  int _typed() {
    final n = widget.animal.name.length;
    if (!widget.animate) return n;
    return ((_intro - _textAt) ~/ _typeMs).clamp(0, n);
  }

  bool get _textShown => !_leaving && _intro >= _textAt;

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final bushOrigin = widget.bushTopLeft;
    final foxBase = bushOrigin + Offset(15 * s, 30 * s);
    final intro = _intro;

    final size = MediaQuery.sizeOf(context);
    final cardBox = _cardKey.currentContext?.findRenderObject() as RenderBox?;
    final cardHeight = cardBox != null && cardBox.hasSize
        ? cardBox.size.height
        : 270.0;
    final freeTop = MediaQuery.paddingOf(context).top;
    final freeBottom = size.height - 24 - cardHeight;
    final heroSide = 32 * s * _heroScale;
    final heroFeet = Offset(
      size.width / 2,
      (freeTop + freeBottom) / 2 + heroSide * 17 / 64,
    );
    final heroShift = (heroFeet - foxBase) / s;
    final midShift = Offset(heroShift.dx * 0.5, heroShift.dy * 0.66);

    Offset shift = Offset.zero;
    double k = 1;
    double wipe = 0;
    double opacity = 1;
    bool foxShown = false;
    int frame = 0;

    if (!_leaving) {
      foxShown = intro >= _hopAt;
      if (intro < _hopAt + _hopMs / 2) {
        final f = _stepped((intro - _hopAt) / (_hopMs / 2));
        shift = Offset.lerp(Offset.zero, midShift, f)!;
        k = 1 + (_midScale - 1) * f;
      } else if (intro < _hopAt + _hopMs) {
        final f = _stepped((intro - _hopAt - _hopMs / 2) / (_hopMs / 2));
        shift = Offset.lerp(midShift, heroShift, f)!;
        k = _midScale + (_heroScale - _midScale) * f;
      } else {
        shift = heroShift;
        k = _heroScale;
      }
      if (intro >= _colorAt + _wipeMs) {
        wipe = 1;
      } else if (intro >= _colorAt) {
        wipe = ((intro - _colorAt) ~/ (_wipeMs ~/ 8)) / 8;
      }
    } else if (widget.animate && _since < _leaveMs) {
      foxShown = true;
      wipe = 1;
      final t = _since;
      if (t < _walkTurn) {
        final f = t / _walkTurn;
        shift = Offset.lerp(heroShift, _walkStop, f)!;
        k = _heroScale + (1 - _heroScale) * f;
      } else {
        final f = (t - _walkTurn) / (_leaveMs - _walkTurn);
        shift = Offset.lerp(_walkStop, _walkEnd, f)!;
        k = 1;
        opacity = 1 - f;
      }
      frame = (t ~/ 100) % 2;
    }

    final side = 32 * s * k;
    final foxBottom = foxBase + shift * s;

    final dim = _dim() * _dimMax;
    final emberOn = _leaving && (!widget.animate || _since >= _leaveMs);
    var emberFade = false;
    if (emberOn && widget.animate) {
      emberFade = ((_since - _leaveMs) ~/ _blinkMs).isOdd;
    }

    return SizedBox.expand(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (emberOn)
            Positioned(
              left: Layout.benchX * s + 28 * s / 3,
              top: widget.layout.benchY * s,
              width: 4 * s,
              height: 4 * s,
              child: Opacity(
                opacity: emberFade ? 0.25 : 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _ember,
                    border: Border.all(color: _outline, width: s),
                  ),
                ),
              ),
            ),
          Positioned(
            left: bushOrigin.dx + _shakeX() * s,
            top: bushOrigin.dy,
            width: 32 * s,
            height: 32 * s,
            child: _image('bush', null),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(color: _dimColor.withValues(alpha: dim)),
            ),
          ),
          if (foxShown)
            Positioned(
              left: foxBottom.dx - side / 2,
              top: foxBottom.dy - side,
              width: side,
              height: side,
              child: IgnorePointer(
                child: Opacity(opacity: opacity, child: _fox(frame, wipe)),
              ),
            ),
          if (foxShown && _leaving && widget.animate)
            Positioned(
              left: foxBottom.dx - 60 * s,
              width: 120 * s,
              top: foxBottom.dy - side - 9 * s,
              child: IgnorePointer(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: _bubble(s),
                ),
              ),
            ),
          if (_textShown)
            Positioned(left: 0, right: 0, bottom: 0, child: _block()),
        ],
      ),
    );
  }

  Widget _bubble(double s) {
    return Container(
      padding: EdgeInsets.all(s * 1.5),
      decoration: BoxDecoration(
        color: _parchment,
        border: Border.all(color: _outline, width: s * 0.8),
      ),
      child: Text(
        widget.animal.reaction.bubble,
        style: _text(s * 4.2, _ink, weight: FontWeight.w600),
      ),
    );
  }

  Widget _image(String name, Color? tint) {
    Widget img = Image.asset(
      'assets/sprites/$name.png',
      fit: BoxFit.fill,
      filterQuality: FilterQuality.none,
      isAntiAlias: false,
      gaplessPlayback: true,
    );
    if (tint != null) {
      img = ColorFiltered(
        colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
        child: img,
      );
    }
    return img;
  }

  Widget _fox(int frame, double wipe) {
    final frames = widget.animal.frames;
    final name = frames[frame % frames.length];
    return Stack(
      fit: StackFit.expand,
      children: [
        _image(name, _silhouette),
        if (wipe > 0)
          ClipRect(clipper: _FeetUp(wipe), child: _image(name, null)),
      ],
    );
  }

  Widget _block() {
    final name = widget.animal.name;
    final typed = _typed();
    final when = _whenLabel(widget.outing.start, widget.now ?? DateTime.now());
    final meta = '${outingMeta(widget.outing, miles: widget.miles)} · $when';
    final tag = widget.first
        ? 'New in your collection'
        : 'Met ${widget.timesMet} times';

    return Container(
      key: _cardKey,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      decoration: BoxDecoration(
        color: _parchment,
        border: Border.all(color: _outline, width: 3),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 30,
                    child: Text(
                      name.substring(0, typed),
                      style: _text(30, _forest, weight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    arrivalPhrase(widget.animal, widget.outing.kind),
                    style: _bodyText(16, _bark),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    meta,
                    style: _numText(13, _bark),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 232),
                    child: Text(
                      widget.animal.note,
                      style: _bodyText(15, _ink, italic: true),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipPath(
                    clipper: const _Notch(),
                    child: ColoredBox(
                      color: _fern,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3,
                        ),
                        child: Text(tag, style: _numText(12, _ink)),
                      ),
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
                behavior: HitTestBehavior.opaque,
                onTap: _close,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: PixelIcon('close', color: _bark),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
