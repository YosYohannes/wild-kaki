import 'package:flutter/material.dart';

import '../data/model.dart';
import 'theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.prefs,
    required this.onPrefs,
    required this.onBack,
    required this.onManage,
    required this.onStartOver,
    this.onDevTools,
  });

  final Prefs prefs;
  final ValueChanged<Prefs> onPrefs;
  final VoidCallback onBack;
  final VoidCallback onManage;
  final VoidCallback onStartOver;
  final VoidCallback? onDevTools;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _sure = false;

  Prefs get _prefs => widget.prefs;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Wild.parchment,
      child: SafeArea(
        child: Column(
          children: [
            PageTopBar(onClose: widget.onBack),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 10),
                    child: Text(
                      'Settings',
                      style: pixelText(26, color: Wild.forest),
                    ),
                  ),
                  const _Heading('Health Connect'),
                  _Row(
                    title: 'Permissions',
                    trailing: _Link('Manage', widget.onManage),
                  ),
                  const _Heading('Display'),
                  _Row(
                    title: 'Distance',
                    trailing: _Segmented(
                      miles: _prefs.miles,
                      onChanged: (miles) =>
                          widget.onPrefs(_prefs.copyWith(miles: miles)),
                    ),
                  ),
                  _Row(
                    title: 'Animate the scene',
                    note: "Follows your phone's setting until you change it",
                    trailing: _Toggle(
                      label: 'Animate the scene',
                      on: _prefs.animate,
                      onChanged: (on) =>
                          widget.onPrefs(_prefs.copyWith(animate: on)),
                    ),
                  ),
                  _Row(
                    title: 'Sound',
                    note: 'Animals make a little noise when you tap them',
                    trailing: _Toggle(
                      label: 'Sound',
                      on: _prefs.sound,
                      onChanged: (on) =>
                          widget.onPrefs(_prefs.copyWith(sound: on)),
                    ),
                  ),
                  const _Heading('Updates'),
                  _Row(
                    title: 'Check for updates',
                    note: 'Asks GitHub for a newer version when the app opens',
                    trailing: _Toggle(
                      label: 'Check for updates',
                      on: _prefs.checkUpdates,
                      onChanged: (on) =>
                          widget.onPrefs(_prefs.copyWith(checkUpdates: on)),
                    ),
                  ),
                  const _Heading('Your animals'),
                  if (_sure)
                    _confirm()
                  else
                    _Row(
                      title: 'Start over',
                      note: 'Forget every animal and begin again',
                      trailing: _Link(
                        'Start over',
                        () => setState(() => _sure = true),
                      ),
                    ),
                  if (widget.onDevTools != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: widget.onDevTools,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            'Developer tools',
                            style: pixelText(14, color: Wild.ember),
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Everything stays on this phone.',
                          style: bodyText(12, color: Wild.bark),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'WildKaki 0.1 · Tiny5, OFL',
                          style: bodyText(12, color: Wild.bark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _confirm() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Forget every animal?', style: bodyText(16)),
              Text(
                'This clears your collection and any activities waiting in the bushes. Health Connect is not touched.',
                style: bodyText(12, color: Wild.bark),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _NotchButton(
                    key: const ValueKey('confirm-start-over'),
                    label: 'Start over',
                    background: Wild.danger,
                    color: Wild.parchment,
                    onTap: () {
                      setState(() => _sure = false);
                      widget.onStartOver();
                    },
                  ),
                  const SizedBox(width: 8),
                  _NotchButton(
                    key: const ValueKey('keep-animals'),
                    label: 'Keep them',
                    background: Wild.paper,
                    color: Wild.bark,
                    onTap: () => setState(() => _sure = false),
                  ),
                ],
              ),
            ],
          ),
        ),
        DottedRule(color: Wild.bark.withValues(alpha: 0.3)),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 22, bottom: 2),
      child: Text(
        text.toUpperCase(),
        style: pixelText(13, color: Wild.bark, letterSpacing: 13 * 0.06),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.title, this.note, required this.trailing});

  final String title;
  final String? note;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 50),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: bodyText(16)),
                      if (note != null)
                        Text(note!, style: bodyText(12, color: Wild.bark)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                trailing,
              ],
            ),
          ),
          DottedRule(color: Wild.bark.withValues(alpha: 0.3)),
        ],
      ),
    );
  }
}

class _Link extends StatelessWidget {
  const _Link(this.label, this.onTap);

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(label, style: pixelText(14, color: Wild.ember)),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.on,
    required this.onChanged,
  });

  final String label;
  final bool on;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: on,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!on),
        child: Container(
          key: ValueKey('toggle-$label'),
          width: 46,
          height: 24,
          decoration: BoxDecoration(
            color: on ? Wild.ember : Wild.paper,
            border: Border.all(color: Wild.outline, width: 3),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 3,
                left: on ? 23 : 3,
                width: 12,
                height: 12,
                child: ColoredBox(color: on ? Wild.parchment : Wild.outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({required this.miles, required this.onChanged});

  final bool miles;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget seg(String text, bool value) {
      final pressed = miles == value;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(value),
        child: Container(
          color: pressed ? Wild.ember : Wild.paper,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Text(
            text,
            style: pixelText(14, color: pressed ? Wild.parchment : Wild.bark),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Wild.outline, width: 3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [seg('km', false), seg('mi', true)],
      ),
    );
  }
}

class _NotchButton extends StatelessWidget {
  const _NotchButton({
    super.key,
    required this.label,
    required this.background,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ClipPath(
        clipper: const NotchClipper(),
        child: Container(
          color: background,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(label, style: pixelText(14, color: color)),
        ),
      ),
    );
  }
}
