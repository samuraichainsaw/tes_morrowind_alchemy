import 'package:flutter/material.dart';

class AttributeSlider extends StatefulWidget {
  double value = 20;
  String caption = "Slider ...";
  String description;
  final void Function(double p) onSliderValueChanged;
  AttributeSlider(
      {super.key,
      required this.onSliderValueChanged,
      required this.value,
      required this.caption,
      this.description = ""});
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
  _AttributeSliderState({
    required this.onSliderValueChanged,
    required this.value,
    required this.caption,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          caption,
          style: TextStyle(
            fontWeight: FontWeight.bold,
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
            : Container(),
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
        Slider(
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
      ],
    );
  }
}
