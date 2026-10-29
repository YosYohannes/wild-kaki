import 'package:flutter/material.dart';

import 'pixel_icon.dart';

class Wild {
  static const Color night = Color(0xFF0F2119);
  static const Color forest = Color(0xFF1F3A2E);
  static const Color moss = Color(0xFF4F6F4A);
  static const Color fern = Color(0xFF8FAE74);
  static const Color parchment = Color(0xFFF3ECDC);
  static const Color paper = Color(0xFFE9DFC8);
  static const Color bark = Color(0xFF5B4636);
  static const Color ember = Color(0xFFC8672B);
  static const Color ink = Color(0xFF2A2A22);
  static const Color outline = Color(0xFF2E2218);
  static const Color danger = Color(0xFF9A3B1F);
}

const String pixelFamily = 'Tiny5';

TextStyle pixelText(
  double size, {
  Color? color,
  FontWeight weight = FontWeight.w600,
  double? letterSpacing,
}) {
  return TextStyle(
    fontFamily: pixelFamily,
    fontSize: size,
    fontWeight: weight,
    color: color ?? Wild.ink,
    letterSpacing: letterSpacing,
    decoration: TextDecoration.none,
  );
}

TextStyle numberText(double size, {Color? color}) {
  return TextStyle(
    fontFamily: 'Roboto',
    fontSize: size,
    fontWeight: FontWeight.w600,
    color: color ?? Wild.ink,
    decoration: TextDecoration.none,
  );
}

TextStyle bodyText(double size, {Color? color, bool italic = false}) {
  return TextStyle(
    fontFamily: 'Roboto',
    fontSize: size,
    color: color ?? Wild.ink,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    decoration: TextDecoration.none,
  );
}

ThemeData wildTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: Wild.forest,
      onPrimary: Wild.parchment,
      secondary: Wild.ember,
      surface: Wild.paper,
      onSurface: Wild.ink,
    ),
    scaffoldBackgroundColor: Wild.parchment,
    splashFactory: NoSplash.splashFactory,
  );
}

class DottedRule extends StatelessWidget {
  const DottedRule({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2,
      width: double.infinity,
      child: CustomPaint(painter: _DottedPainter(color)),
    );
  }
}

class _DottedPainter extends CustomPainter {
  _DottedPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..isAntiAlias = false;
    for (double x = 0; x < size.width; x += 4) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 2, 2), paint);
    }
  }

  @override
  bool shouldRepaint(_DottedPainter old) => old.color != color;
}

class NotchClipper extends CustomClipper<Path> {
  const NotchClipper();

  @override
  Path getClip(Size s) {
    const n = 3.0;
    return Path()
      ..moveTo(0, n)
      ..lineTo(n, n)
      ..lineTo(n, 0)
      ..lineTo(s.width - n, 0)
      ..lineTo(s.width - n, n)
      ..lineTo(s.width, n)
      ..lineTo(s.width, s.height - n)
      ..lineTo(s.width - n, s.height - n)
      ..lineTo(s.width - n, s.height)
      ..lineTo(n, s.height)
      ..lineTo(n, s.height - n)
      ..lineTo(0, s.height - n)
      ..close();
  }

  @override
  bool shouldReclip(NotchClipper old) => false;
}

class PageTopBar extends StatelessWidget {
  const PageTopBar({super.key, this.onSettings, required this.onClose});

  final VoidCallback? onSettings;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (onSettings != null)
            Semantics(
              button: true,
              label: 'Settings',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onSettings,
                child: const Padding(
                  padding: EdgeInsets.all(7),
                  child: PixelIcon('settings-cog'),
                ),
              ),
            ),
          Semantics(
            button: true,
            label: 'Close',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onClose,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: PixelIcon('close'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
