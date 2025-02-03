import 'dart:math';
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'package:morrowind_alchemy/attribute_slider.dart';
import 'package:morrowind_alchemy/autocomplete_text_fields.dart';
import 'package:morrowind_alchemy/data/ingredients.dart';
import 'package:morrowind_alchemy/data/effects.dart';
import 'package:scaled_app/scaled_app.dart';

import 'dart:convert' as convert;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

var data = ingredients;
var url = ((js.context['currentLocation'])).toString();
double scaleFactorCallback(Size deviceSize) {
  // screen width used in your UI design
  var currentScale = js.context['devicePixelRatio'] as num?; // or as double?
  currentScale = currentScale ?? 1.0;
  const double widthOfDesign = 1024;

  return (deviceSize.width / widthOfDesign) * currentScale;
}

void main() {
  // 1st way to use this package
  runAppScaled(const MyApp(), scaleFactor: scaleFactorCallback);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<StatefulWidget> createState() {
    return _MyAppState();
  }
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _getSystemThemeMode();
  }

  void _getSystemThemeMode() {
    _darkMode = ThemeData.dark().copyWith(
      textTheme:
          ThemeData.dark().textTheme.apply(fontFamily: 'MagicCardsNormal'),
    );
    _lightMode = ThemeData.light().copyWith(
      textTheme:
          ThemeData.light().textTheme.apply(fontFamily: 'MagicCardsNormal'),
    );

    // Check if the browser supports the `prefers-color-scheme` media query
    final window = html.window;
    final mediaQueryList = window.matchMedia('(prefers-color-scheme: dark)');

    // Listener for changes in user's color scheme preference
    mediaQueryList.addListener((event) {
      setState(() {
        _themeMode = mediaQueryList.matches ? ThemeMode.dark : ThemeMode.light;
      });
    });

    // Set the initial theme based on the current preference
    setState(() {
      _themeMode =
          mediaQueryList.matches == true ? ThemeMode.dark : ThemeMode.light;
    });
  }

  final _title = 'TES Morrowind another alchemy simulator';

  late ThemeData _darkMode;

  late ThemeData _lightMode;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constrainst) {
      TextScaler.linear(1.1);
      return MaterialApp(
        title: _title,
        theme: _lightMode, // Default light theme
        darkTheme: _darkMode, // Default dark theme
        themeMode: _themeMode,
        home: MyHomePage(title: _title),
        debugShowCheckedModeBanner: false,
      );
    });
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late double _currentAlchemySliderValue = 16.0;
  var _currentIntSliderValue = 23.0;
  var _currentLuckSliderValue = 11.0;

  var _numEffects = 0;

  final Set<String> _effects = {};
  final Set<String> _selectedEffects = {};
  final Map<String, dynamic> _ingredientsByEffect = {};

  var _sortedEffects = [];
  List<Widget> _effectsWidgets = [
    Container(),
  ];

  final Map<int, List<Widget>> _cachedEffectWidgets = {};

  final Set<String> _selectedIngredients = {};
  final Set<String> _activeEffects = {};
  final Map<String, String> _effectsDescriptions = {};

  @override
  void initState() {
    _loadStateData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          widget.title,
        ),
      ),
      body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: LayoutBuilder(builder: (context, constrainst) {
            var columnWidth = 1024.0 / 3.0 + 17;
            return Column(
              children: <Widget>[
                Card(
                  child: SizedBox(
                    width: 1024,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        AttributeSlider(
                          onSliderValueChanged: onAlchemySliderValueChanged,
                          value: _currentAlchemySliderValue,
                          caption: "Alchemy",
                          description:
                              "Alchemy skill level. Determines how many effects can you identify\n on ingredients. Improves potion quality, strength and success chance.",
                        ),
                        AttributeSlider(
                          onSliderValueChanged: onIntSliderValueChanged,
                          value: _currentIntSliderValue,
                          caption: "Intelligence",
                        ),
                        AttributeSlider(
                          onSliderValueChanged: onLuckSliderValueChanged,
                          value: _currentLuckSliderValue,
                          caption: "Luck",
                        ),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: SizedBox(
                    width: 1024,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Card(
                              child: SizedBox(
                                width: 280,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Center(
                                      child: _activeEffects.isEmpty
                                          ? const Text('No active effect(s)')
                                          : const Text('Active effects',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                    ),
                                    Center(
                                      //

                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Text(
                                              'chance: ${min(100.0, _currentAlchemySliderValue + (_currentIntSliderValue / 10) + (_currentLuckSliderValue / 10)).toStringAsFixed(2)}%',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          Tooltip(
                                            message:
                                                "success chance of creating a potion",
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
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            _renderEffectTextsInRow(
                                _activeEffects.toList(), 0, 1),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Center(
                          child: Card(
                            child: SizedBox(
                              width: 280,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(
                                      top: 20,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Center(
                                            child: _numEffects == 0
                                                ? const Text('No known effects')
                                                : const Text('Known effects',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold)),
                                          ),
                                          for (var i = 0;
                                              i < _effectsWidgets.length;
                                              ++i)
                                            (_effectsWidgets[i])
                                        ],
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Card(
                          child: SizedBox(
                            width: columnWidth,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Center(
                                      child: _selectedEffects.isEmpty
                                          ? const Text('No selected effect(s)')
                                          : const Text('Selected effects',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                    ),
                                    AutocompleteTextField(
                                        caption: 'Enter effect name',
                                        list: _effects,
                                        onSelected: (selection) {
                                          _addOrRemoveEffect(selection);
                                        }),
                                  ]),
                            ),
                          ),
                        ),
                        for (var selectedEffect in _selectedEffects)
                          (Card(
                            child: SizedBox(
                              width: columnWidth,
                              child: Center(
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Image(
                                          image: AssetImage(
                                              'assets/images/${effectsData[(selectedEffect)]}'),
                                        ),
                                        SizedBox(
                                          width: 4,
                                        ),
                                        Text(
                                          selectedEffect,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        IconButton(
                                            onPressed: () {
                                              _addOrRemoveEffect(
                                                  selectedEffect);
                                            },
                                            icon: Icon(
                                              Icons.close,
                                              color: Colors.red,
                                              size: 12,
                                            ))
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _renderIngredientTextsInColumn(
                                                _ingredientsByEffect[
                                                    selectedEffect],
                                                0,
                                                1),
                                            SizedBox(
                                              width: 2,
                                            ),
                                            SizedBox(
                                              width: 2,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ))
                      ],
                    ),
                    Column(
                      children: [
                        Card(
                          child: SizedBox(
                            width: columnWidth,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _selectedIngredients.isEmpty
                                        ? const Text('No selected ingredient')
                                        : const Text('Selected ingredients:',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                    AutocompleteTextField(
                                        caption: 'Enter ingredient name',
                                        list: data.values
                                            .toList()
                                            .map((v) => v['name'] as String)
                                            .toSet(),
                                        onSelected: (selection) {
                                          var ingredient = data.values
                                              .firstWhere((e) =>
                                                  e['name'] == selection);
                                          _addOrRemovieIngerdient(ingredient);
                                        }),
                                    SizedBox(width: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: Card(
                            child: SizedBox(
                              width: columnWidth,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      for (var ingredientId
                                          in _selectedIngredients)
                                        (_renderIngredientsWithEffects(
                                            ingredientId))
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          })),
    );
  }

  void onAlchemySliderValueChanged(double value) async {
    var oldNumEffects = _numEffects;
    final SharedPreferencesAsync prefs = SharedPreferencesAsync();
    await prefs.setInt('skill_alchemy', value.round());

    _currentAlchemySliderValue = value;
    if (_currentAlchemySliderValue <= 14) {
      _numEffects = 0;
    } else if (_currentAlchemySliderValue <= 29) {
      _numEffects = 1;
    } else if (_currentAlchemySliderValue < 44) {
      _numEffects = 2;
    } else if (_currentAlchemySliderValue < 59) {
      _numEffects = 3;
    } else {
      _numEffects = 4;
    }
    _effects.clear();
    for (var effect in data.values) {
      for (var i = 0;
          i < _numEffects && i < (effect['effects'] as List).length;
          ++i) {
        _effects.add((effect['effects'] as List)[i]);
      }
    }

    if (oldNumEffects != _numEffects) {
      for (var arrLabel in _ingredientsByEffect.keys) {
        _ingredientsByEffect[arrLabel] = data.values
            .where((e) => (e['effects'] as List)
                .getRange(0, min((e['effects'] as List).length, _numEffects))
                .contains(arrLabel))
            .toList();
      }

      if (_cachedEffectWidgets.containsKey(_numEffects)) {
        _effectsWidgets = _cachedEffectWidgets[_numEffects]!;
      } else {
        _sortedEffects = _effects.toList();
        _sortedEffects.sort();
        _effectsWidgets = List.filled(1, Container());
        for (var i = 0; i < _effectsWidgets.length; ++i) {
          _effectsWidgets[i] = _renderEffectTextsInColumn(
              _sortedEffects, i, _effectsWidgets.length);
        }
        _cachedEffectWidgets[_numEffects] = _effectsWidgets;
      }
    }
    updateBrowserURL();
    setState(() {});
  }

  List<Widget> _prepareEffectsWidgets(List arrLabels, int start, int step) {
    return [
      for (var i = start; i < arrLabels.length; i += step)
        (MouseRegion(
          onEnter: (event) => _fetchDescription(arrLabels[i]),
          child: Tooltip(
            message: _effectsDescriptions[arrLabels[i]] ??
                "click to download description...",
            triggerMode: TooltipTriggerMode.tap,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  var arrLabel = arrLabels[i];
                  _addOrRemoveEffect(arrLabel);
                  updateBrowserURL();
                });
              },
              child: Row(
                children: [
                  Image(
                    image: AssetImage(
                        'assets/images/${effectsData[(arrLabels[i])]}'),
                  ),
                  SizedBox(
                    width: 2,
                  ),
                  Text(arrLabels[i]),
                ],
              ),
            ),
          ),
        ))
    ];
  }

  Widget _renderEffectTextsInColumn(List arrLabels, int start, int step) {
    return Column(
      key: ValueKey(
          start < arrLabels.length ? arrLabels[start] : "empty_$start"),
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [..._prepareEffectsWidgets(arrLabels, start, step)],
    );
  }

  Widget _renderEffectTextsInRow(List arrLabels, int start, int step) {
    return Row(
      key: ValueKey(
          start < arrLabels.length ? arrLabels[start] : "empty_$start"),
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [..._prepareEffectsWidgets(arrLabels, start, step)],
    );
  }

  Widget _renderIngredientTextsInColumn(
      List arrIngredients, int start, int step) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        for (var i = start; i < arrIngredients.length; i += step)
          (SizedBox(
            width: 242,
            child: _ingredientButton(arrIngredients[i], true),
          ))
      ],
    );
  }

  Widget _renderIngredientsWithEffects(String ingredientId) {
    return Padding(
      padding: EdgeInsets.only(top: 20),
      child: Column(children: [
        _ingredientButton(data[ingredientId]),
        SizedBox(
          height: 10,
        ),
        _renderEffectTextsInColumn(
            (data[ingredientId]!['effects'] as List)
                .getRange(
                    0,
                    min(_numEffects,
                        (data[ingredientId]!['effects'] as List).length))
                .toList(),
            0,
            1),
      ]),
    );
  }

  Widget _ingredientButton(ingredient, [bool greyoutifselected = false]) {
    return AnimatedOpacity(
      opacity: greyoutifselected == true &&
              _selectedIngredients.contains(ingredient['id'])
          ? 0.3
          : 1,
      duration: Duration(milliseconds: 300),
      child: Tooltip(
        message: ingredient['description'],
        preferBelow: true,
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _addOrRemovieIngerdient(ingredient);
            });
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Image(
                image: AssetImage(
                    'assets/images/${ingredient['img'].toString().replaceAll('%27', "'")}'),
                width: 18,
                height: 18,
              ),
              SizedBox(
                width: 2,
              ),
              Text(ingredient['name']),
              SizedBox(
                width: 4,
              ),
              Text(
                '${ingredient['price']} x ',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Image(
                image: AssetImage('assets/images/value.png'),
                width: 18,
                height: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSelectedIngredientChange() {
    updateBrowserURL();
    setState(() {
      _activeEffects.clear();
      Map<String, int> effectsCount = {};
      for (var ingredientId in _selectedIngredients) {
        for (var effect in (data[ingredientId]!['effects'] as List)) {
          if (!effectsCount.containsKey(effect)) {
            effectsCount[effect] = 1;
          } else {
            effectsCount[effect] = effectsCount[effect]! + 1;
          }
        }
      }
      for (var entry in effectsCount.entries) {
        if (entry.value > 1) {
          _activeEffects.add(entry.key);
        }
      }
    });
  }

  void _fetchDescription(effectName) async {
    return;
    //print("!");

    try {
      //https://en.uesp.net/w/api.php?action=query&format=json&prop=info%7Cextracts%7Cpageimages%7Crevisions%7Cinfo&formatversion=2&redirects=true&exintro=true&exchars=525&explaintext=true&piprop=thumbnail&pithumbsize=300&pilicense=any&rvprop=timestamp&inprop=url&titles=Morrowind%3AWater_Walking&smaxage=300&maxage=300&uselang=content
      var url = Uri.https('en.uesp.net', '/w/api.php', {
        "action": "query",
        "format": "json",
        "prop": "info|extracts|pageimages|revisions|info",
        "formatversion": "2",
        "redirects": "true",
        "exintro": "true",
        "exchars": "525",
        "explaintext": "true",
        "piprop": "thumbnail",
        "pithumbsize": "300",
        "pilicense": "any",
        "rvprop": "timestamp",
        "inprop": "url",
        "titles": "Morrowind:" + effectName.replaceAll(" ", "_"),
        "smaxage": "300",
        "maxage": "300",
        "uselang": "content"
      });
      // Await the http get response, then decode the json-formatted response.
      var response = await http.get(url);
      if (response.statusCode == 200) {
        var jsonResponse =
            convert.jsonDecode(response.body) as Map<String, dynamic>;
        var itemCount = jsonResponse['totalItems'];
        print('Number of books about http: $itemCount.');
      } else {
        print('Request failed with status: ${response.statusCode}.');
      }
    } finally {}
  }

  void onIntSliderValueChanged(double p) async {
    final SharedPreferencesAsync prefs = SharedPreferencesAsync();
    await prefs.setInt('attr_int', p.round());
    updateBrowserURL();
    setState(() {
      _currentIntSliderValue = p;
    });
  }

  void onLuckSliderValueChanged(double p) async {
    final SharedPreferencesAsync prefs = SharedPreferencesAsync();
    await prefs.setInt('attr_luck', p.round());
    updateBrowserURL();
    setState(() {
      _currentLuckSliderValue = p;
    });
  }

  void _loadStateData() async {
    final SharedPreferencesAsync prefs = SharedPreferencesAsync();
    var intelligence = max(min(100, (await prefs.getInt('attr_int')) ?? 25), 0);
    var luck = max(min(100, (await prefs.getInt('attr_luck')) ?? 25), 0);
    var alchemy = max(min(100, (await prefs.getInt('skill_alchemy')) ?? 25), 0);

    setState(() {
      if (url.contains("#stats/")) {
        url = url.substring(url.indexOf("#stats/"));
        url = url.replaceAll("#stats/", "");
        List<String> parts = url.split("/");

        try {
          intelligence = max(min(100, int.parse(parts[0])), 0);
          luck = max(min(100, int.parse(parts[1])), 0);
          alchemy = max(min(100, int.parse(parts[2])), 0);
          if (parts.length > 4) {
            var teffects = parts[4].split(":");
            for (var effect in teffects) {
              effect = Uri.decodeComponent(effect);
              if (effectsData.containsKey(effect)) {
                _selectedEffects.add(Uri.decodeComponent(effect));
                _ingredientsByEffect[effect] = data.values
                    .where((e) => (e['effects'] as List)
                        .getRange(
                            0, min((e['effects'] as List).length, _numEffects))
                        .contains(effect))
                    .toList();
              }
            }
          }
          if (parts.length >= 5) {
            var tingredients = parts[5].split(":");
            for (var ingredient in tingredients) {
              ingredient = Uri.decodeComponent(ingredient);
              if (data.containsKey(ingredient)) {
                _selectedIngredients.add(ingredient);
              }
            }
            _onSelectedIngredientChange();
          }
        } catch (_) {}
      }
      _currentIntSliderValue = intelligence.toDouble();
      _currentAlchemySliderValue = alchemy.toDouble();
      _currentLuckSliderValue = luck.toDouble();

      onAlchemySliderValueChanged(alchemy.toDouble());
      if (_currentAlchemySliderValue <= 14) {
        _numEffects = 0;
      } else if (_currentAlchemySliderValue <= 29) {
        _numEffects = 1;
      } else if (_currentAlchemySliderValue < 44) {
        _numEffects = 2;
      } else if (_currentAlchemySliderValue < 59) {
        _numEffects = 3;
      } else {
        _numEffects = 4;
      }
      _effects.clear();
      for (var effect in data.values) {
        for (var i = 0;
            i < _numEffects && i < (effect['effects'] as List).length;
            ++i) {
          _effects.add((effect['effects'] as List)[i]);
        }
      }
      print(_effects.length);
    });
  }

  void updateBrowserURL() {
    html.window.history.pushState(null, ".",
        '#stats/${_currentIntSliderValue.round()}/${_currentLuckSliderValue.round()}/${_currentAlchemySliderValue.round()}/potion/${_selectedEffects.toList().join(":")}/${_selectedIngredients.toList().join(":")}');
  }

  void _addOrRemoveEffect(arrLabel) {
    if (_selectedEffects.contains(arrLabel)) {
      _selectedEffects.remove(arrLabel);
    } else {
      _selectedEffects.add(arrLabel);

      _ingredientsByEffect[arrLabel] = data.values
          .where((e) => (e['effects'] as List)
              .getRange(0, min((e['effects'] as List).length, _numEffects))
              .contains(arrLabel))
          .toList();
    }
    updateBrowserURL();
    setState(() {});
  }

  void _addOrRemovieIngerdient(ingredient) {
    _selectedIngredients.contains(ingredient['id'])
        ? _selectedIngredients.remove(ingredient['id']!)
        : (_selectedIngredients.length < 4
            ? _selectedIngredients.add(ingredient['id']!)
            : false);
    _onSelectedIngredientChange();
  }
}
