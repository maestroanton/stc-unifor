import 'package:flutter/material.dart';

class AnimatedExpandableTile extends StatefulWidget {
  final String title;
  final List<String> subItems;
  final bool initiallyExpanded;
  final ValueChanged<bool> onExpansionChanged;
  final void Function(String subItem) onSubItemTap;

  const AnimatedExpandableTile({
    super.key,
    required this.title,
    required this.subItems,
    required this.initiallyExpanded,
    required this.onExpansionChanged,
    required this.onSubItemTap,
  });

  @override
  State<AnimatedExpandableTile> createState() => _AnimatedExpandableTileState();
}

class _AnimatedExpandableTileState extends State<AnimatedExpandableTile>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
    widget.onExpansionChanged(_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            dense: true,
            title: Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
            trailing: Icon(
              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            ),
            onTap: _toggleExpanded,
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children:
                  widget.subItems.map((sub) {
                    return ListTile(
                      dense: true,
                      title: Text(sub, style: const TextStyle(fontSize: 12)),
                      onTap: () => widget.onSubItemTap(sub),
                    );
                  }).toList(),
            ),
            crossFadeState:
                _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            firstCurve: Curves.easeInOut,
            secondCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }
}
