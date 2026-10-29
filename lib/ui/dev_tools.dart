import 'package:flutter/widgets.dart';

import '../weather/weather_state.dart';
import 'theme.dart' show PageTopBar;

const _parchment = Color(0xFFF3ECDC);
const _forest = Color(0xFF1F3A2E);
const _ink = Color(0xFF2A2A22);
const _outline = Color(0xFF2E2218);
const _fern = Color(0xFF8FAE74);

TextStyle _text(
  double size,
  Color color, {
  FontWeight weight = FontWeight.w500,
}) => TextStyle(
  fontFamily: 'Tiny5',
  fontSize: size,
  fontWeight: weight,
  color: color,
  decoration: TextDecoration.none,
);

class DevToolsPage extends StatefulWidget {
  const DevToolsPage({
    super.key,
    required this.weather,
    required this.onBack,
    required this.onFakeRun,
    required this.onFakeSleep,
  });

  final WeatherState weather;
  final VoidCallback onBack;
  final Future<String> Function() onFakeRun;
  final Future<String> Function() onFakeSleep;

  @override
  State<DevToolsPage> createState() => _DevToolsPageState();
}

class _DevToolsPageState extends State<DevToolsPage> {
  String? _busy;
  String? _result;

  Future<void> _write(String label, Future<String> Function() action) async {
    if (_busy != null) return;
    setState(() => _busy = label);
    String message;
    try {
      message = await action();
    } catch (e) {
      message = 'failed: $e';
    }
    if (!mounted) return;
    setState(() {
      _busy = null;
      _result = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _parchment,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageTopBar(onClose: widget.onBack),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Developer tools',
                      style: _text(28, _ink, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 20),
                    _ActionButton(
                      label: 'Write a fake run',
                      busy: _busy == 'run',
                      onTap: () => _write('run', widget.onFakeRun),
                    ),
                    const SizedBox(height: 12),
                    _ActionButton(
                      label: 'Write a fake sleep',
                      busy: _busy == 'sleep',
                      onTap: () => _write('sleep', widget.onFakeSleep),
                    ),
                    if (_result != null) ...[
                      const SizedBox(height: 16),
                      Text(_result!, style: _text(14, _ink)),
                    ],
                    const SizedBox(height: 28),
                    Text(
                      'Weather',
                      style: _text(22, _ink, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    ListenableBuilder(
                      listenable: widget.weather,
                      builder: (context, _) => _WeatherButtons(widget.weather),
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.busy,
    required this.onTap,
  });

  final String label;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _fern,
          border: Border.all(color: _outline, width: 2),
        ),
        child: Text(
          busy ? 'Writing...' : label,
          style: _text(16, _forest, weight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _WeatherButtons extends StatelessWidget {
  const _WeatherButtons(this.weather);

  final WeatherState weather;

  @override
  Widget build(BuildContext context) {
    final picked = weather.override;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'live: ${weather.live.name}, showing: ${weather.value.name}',
          style: _text(14, _ink),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ChoiceButton(
              label: 'Auto',
              selected: picked == null,
              onTap: () => weather.override = null,
            ),
            for (final w in Weather.values)
              _ChoiceButton(
                label: '${w.name[0].toUpperCase()}${w.name.substring(1)}',
                selected: picked == w,
                onTap: () => weather.override = w,
              ),
          ],
        ),
      ],
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _forest : _fern,
          border: Border.all(color: _outline, width: 2),
        ),
        child: Text(
          label,
          style: _text(
            16,
            selected ? _parchment : _forest,
            weight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
