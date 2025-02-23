import 'package:flutter/material.dart';
import 'package:morrowind_alchemy/responsive_layout_fn.dart';

class AttributeSlider extends StatefulWidget {
  double value = 20;
  String caption = "Slider ...";
  String description;
  final void Function(double p) onSliderValueChanged;
  final ResponsiveLayoutBreakPoints breakPoint;
  final double width;
  AttributeSlider(
      {super.key,
      required this.onSliderValueChanged,
      required this.value,
      required this.caption,
      required this.breakPoint,
      this.description = "",
      required this.width});
  @override
  State<StatefulWidget> createState() => _AttributeSliderState(
      value: value,
      onSliderValueChanged: onSliderValueChanged,
      caption: caption,
      description: description);
}

class _AttributeSliderState extends State<AttributeSlider> {
  double value = 20;
  final void Function(double p) onSliderValueChanged;
  String description;
  String caption = "Slider...";
  var textContainerWidth = 120.0;

  _AttributeSliderState({
    required this.onSliderValueChanged,
    required this.value,
    required this.caption,
    required this.description,
  });

  @override
  void initState() {
    switch (widget.breakPoint) {
      case ResponsiveLayoutBreakPoints.xxLarge:
        textContainerWidth = 75;
        break;
      case ResponsiveLayoutBreakPoints.xLarge:
        textContainerWidth = 75;
        break;
      case ResponsiveLayoutBreakPoints.large:
        textContainerWidth = 75;
        break;
      case ResponsiveLayoutBreakPoints.medium:
        textContainerWidth = 70;
        break;
      case ResponsiveLayoutBreakPoints.small:
        textContainerWidth = 120;
        break;
      case ResponsiveLayoutBreakPoints.xSmall:
        textContainerWidth = 120;
        break;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: textContainerWidth,
          child: Text(
            caption,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        description.isNotEmpty
            ? Tooltip(
                message: description,
                child: CircleAvatar(
                  radius: 8,
                  child: Text(
                    'i',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 6,
                    ),
                  ),
                ),
              )
            : SizedBox(width: 18),
        SizedBox(
          width: 20,
        ),
        CircleAvatar(
          radius: 16,
          child: Text(
            '${widget.value.toInt()}',
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(
          width: widget.width,
          child: Slider(
            value: widget.value,
            max: 100,
            divisions: 100,
            label: widget.value.round().toString(),
            onChanged: (double v) {
              onSliderValueChanged(v);
              setState(() {
                value = v;
              });
            },
          ),
        ),
      ],
    );
  }
}
