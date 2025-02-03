import 'package:flutter/material.dart';

class AutocompleteTextField extends StatefulWidget {
  final String caption;
  final Set<String> list;
  final void Function(String selection) onSelected;

  const AutocompleteTextField(
      {super.key,
      required this.caption,
      required this.list,
      required this.onSelected});

  @override
  State<AutocompleteTextField> createState() => _AutocompleteTextFieldState();
}

class _AutocompleteTextFieldState extends State<AutocompleteTextField> {
  List<String> get _suggestions => widget.list.toList();
  late TextEditingController _controller;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 220,
          height: 50,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              RawAutocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') {
                    return const Iterable<String>.empty();
                  }
                  return _suggestions.where((String option) {
                    return option
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String selection) {
                  _controller.clear();
                  setState(() {});

                  widget.onSelected(selection);
                },
                fieldViewBuilder: (BuildContext context,
                    TextEditingController fieldTextEditingController,
                    FocusNode fieldFocusNode,
                    VoidCallback onFieldSubmitted) {
                  _controller = fieldTextEditingController;

                  return TextField(
                    controller: fieldTextEditingController,
                    focusNode: fieldFocusNode,
                    decoration: InputDecoration(
                      hintText: widget.caption,
                    ),
                  );
                },
                optionsViewBuilder: (BuildContext context,
                    void Function(String) onSelected,
                    Iterable<String> options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      child: SizedBox(
                        height: 200.0,
                        child: ListView(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          children: options.map((String option) {
                            return ListTile(
                              onTap: () {
                                onSelected(option);
                              },
                              title: Text(option),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              _controller.clear();
            });
          },
          icon: Icon(Icons.close_outlined),
          iconSize: 12,
        )
      ],
    );
  }
}
