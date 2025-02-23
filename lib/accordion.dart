import 'package:flutter/material.dart';

class Accordion extends StatefulWidget {
  final String title;
  final Widget content;
  final bool initiallyExpanded;
  final EdgeInsets titlePadding;
  final EdgeInsets contentPadding;
  final TextStyle? titleStyle;
  final Color? backgroundColor;
  final Color? titleBackgroundColor;
  final Icon? expandIcon;
  final Icon? collapseIcon;

  const Accordion({
    super.key,
    required this.title,
    required this.content,
    this.initiallyExpanded = false,
    this.titlePadding = const EdgeInsets.all(10.0),
    this.contentPadding = const EdgeInsets.all(10.0),
    this.titleStyle,
    this.backgroundColor,
    this.titleBackgroundColor,
    this.expandIcon,
    this.collapseIcon,
  });

  @override
  _AccordionState createState() => _AccordionState();
}

class _AccordionState extends State<Accordion> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(5.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2), // changes position of shadow
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              padding: widget.titlePadding,
              decoration: BoxDecoration(
                color: widget.titleBackgroundColor,
                borderRadius: _isExpanded
                    ? const BorderRadius.vertical(
                        top: Radius.circular(5.0),
                      )
                    : BorderRadius.circular(5.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: widget.titleStyle ??
                          const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _isExpanded
                      ? widget.collapseIcon ??
                          const Icon(Icons.keyboard_arrow_up)
                      : widget.expandIcon ??
                          const Icon(Icons.keyboard_arrow_down),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isExpanded
                ? Container(
                    padding: widget.contentPadding,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(5.0),
                      ),
                    ),
                    child: widget.content,
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }
}
