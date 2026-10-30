import 'package:flutter/material.dart';

import '../update/update_service.dart';
import 'theme.dart';

class UpdateBanner extends StatelessWidget {
  const UpdateBanner({
    super.key,
    required this.info,
    required this.onLater,
    required this.onUpdate,
  });

  final UpdateInfo info;
  final VoidCallback onLater;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: Wild.parchment,
        border: Border.all(color: Wild.outline, width: 3),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Version ${info.version} is ready',
              style: pixelText(15, color: Wild.forest),
            ),
          ),
          _Action('Later', Wild.bark, onLater),
          _Action('Update', Wild.ember, onUpdate),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action(this.label, this.color, this.onTap);

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Text(label, style: pixelText(15, color: color)),
        ),
      ),
    );
  }
}
