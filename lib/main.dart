import 'dart:math';
//import 'dart:html' as html;
//import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:morrowind_alchemy/accordion.dart';
import 'package:morrowind_alchemy/attribute_slider.dart';
import 'package:morrowind_alchemy/autocomplete_text_fields.dart';
import 'package:morrowind_alchemy/data/ingredients.dart';
import 'package:morrowind_alchemy/data/effects.dart';
import 'package:morrowind_alchemy/responsive_layout.dart';
import 'package:morrowind_alchemy/responsive_layout_fn.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class Hoverable extends StatefulWidget {
  final Widget child;

  const Hoverable({
    super.key,
    required this.child,
  });

  @override
  _HoverableState createState() => _HoverableState();
}

class _HoverableState extends State<Hoverable> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: _isHovering ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (event) => _onEntered(true),
      onExit: (event) => _onEntered(false),
      child: widget.child,
    );
  }

  void _onEntered(bool isHovering) {
    setState(() {
      _isHovering = isHovering;
    });
  }
}

var data = ingredients;
//var url = ((js.context['currentLocation'])).toString();
double scaleFactorCallback(Size deviceSize) {
  // screen width used in your UI design
  //var currentScale = js.context['devicePixelRatio'] as num?; // or as double?
  //currentScale = currentScale ?? 1.0;
  //const double widthOfDesign = 1024;
  return 1.0;
  //return (deviceSize.width / widthOfDesign) * currentScale;
}

void main() {
  // 1st way to use this package
  //runAppScaled(const MyApp(), scaleFactor: scaleFactorCallback);
  runApp(const MyApp());
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
    //final window = html.window;
    //final mediaQueryList = window.matchMedia('(prefers-color-scheme: dark)');

    // Listener for changes in user's color scheme preference
    /*mediaQueryList.addListener((event) {
      setState(() {
        _themeMode = mediaQueryList.matches ? ThemeMode.dark : ThemeMode.light;
      });
    });
    */
    // Set the initial theme based on the current preference
    setState(() {
      _themeMode = ThemeMode
          .dark; //mediaQueryList.matches == true ? ThemeMode.dark : ThemeMode.light;
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

class ConditionallyVisible extends StatelessWidget {
  final Widget child;
  final bool isVisible;
  const ConditionallyVisible(
      {super.key, required this.child, required this.isVisible});

  @override
  Widget build(BuildContext context) {
    return isVisible ? child : Container();
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late double _currentAlchemySliderValue = 16.0;
  var _currentIntSliderValue = 23.0;
  var _currentLuckSliderValue = 11.0;

  var _numEffects = 0;

  final Set<String> _effects = {};
  final Set<String> _selectedEffects = {};
  final Map<String, dynamic> _ingredientsByEffect = {};

  final GlobalKey _cartKey1 = GlobalKey();
  final GlobalKey _cartKey2 = GlobalKey();
  final GlobalKey _cartKey4 = GlobalKey();
  final GlobalKey _cartKey5 = GlobalKey();
  final GlobalKey _cartKey3 = GlobalKey();

  var _sortedEffects = [];
  List<Widget> _effectsWidgets = [
    Container(),
    Container(),
  ];

  final Map<int, List<Widget>> _cachedEffectWidgets = {};

  final Set<String> _selectedIngredients = {};
  final Set<String> _activeEffects = {};
  final Map<String, String> _effectsDescriptions = {};
  late TabController _tabController;

  @override
  void initState() {
    _loadStateData();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose(); // Dispose of the controller
    super.dispose();
  }

  bool _visibleOn(
      {required List<ResponsiveLayoutBreakPoints> breakpoints,
      required ResponsiveLayoutBreakPoints currentBreakPoint}) {
    int index = breakpoints.indexOf(currentBreakPoint);
    if (index >= 0) {
      return true;
    }
    return false;
  }

  double _calcWidth(
      {required List<ResponsiveLayoutBreakPoints> breakpoints,
      required List<String> widthsPercentage,
      required double baseWidth,
      required ResponsiveLayoutBreakPoints currentBreakPoint}) {
    int index = breakpoints.indexOf(currentBreakPoint);
    if (index >= 0) {
      return double.parse(widthsPercentage[index].replaceAll("%", "")) /
          100 *
          baseWidth;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    TabBar? appBarBottom;
    FloatingActionButton? floatingActionButton;

    ResponsiveLayoutBreakPoints contextBreakPoint =
        ResponsiveLayoutFn.getBreakPoint(context);
    var layoutWidth =
        min(1024, max(MediaQuery.of(context).size.width, 800)).toDouble();
    var columnWidth = layoutWidth / 3.0 - 6.0;

    ResponsiveLayoutFn(
      medium: (className) {
        return Container();
      },
      xSmall: (className) {
        floatingActionButton = FloatingActionButton(
          onPressed: () {
            if (_tabController.index < _tabController.length - 1) {
              _tabController.animateTo(_tabController.index + 1);
            } else {
              _tabController.animateTo(0); // Wrap
            }
          },
          child: Icon(Icons.arrow_forward),
        );
        appBarBottom = TabBar(
          controller: _tabController, // Assign the controller
          tabs: [
            Tab(
              key: _cartKey1,
              icon: Icon(Icons.home),
              text: 'attributes',
            ),
            TopNavigationTab(
              key: _cartKey2,
              caption: 'known effects',
              count: _effects.length,
              icon: Icon(Icons.thunderstorm_outlined),
            ),
            TopNavigationTab(
              key: _cartKey3,
              caption: 'effects',
              count: _selectedEffects.length,
              icon: Icon(Icons.thunderstorm),
            ),
            TopNavigationTab(
              key: _cartKey4,
              caption: 'ingredients',
              count: _selectedIngredients.length,
              icon: Icon(Icons.local_grocery_store_outlined),
            ),
            TopNavigationTab(
              key: _cartKey5,
              caption: 'potion',
              count: _activeEffects.length,
              icon: Icon(Icons.face),
            ),
          ],
        );
        return Container();
      },
    ).getFn(context)(contextBreakPoint);

    calcWidth(
      List<ResponsiveLayoutBreakPoints> breakpoints,
      List<String> widthsPercentage,
    ) =>
        _calcWidth(
            breakpoints: breakpoints,
            widthsPercentage: widthsPercentage,
            baseWidth: MediaQuery.of(context).size.width,
            currentBreakPoint: contextBreakPoint);
    double attributeSliderWidth = calcWidth([
      ResponsiveLayoutBreakPoints.xSmall,
      ResponsiveLayoutBreakPoints.small,
      ResponsiveLayoutBreakPoints.medium,
      ResponsiveLayoutBreakPoints.large,
      ResponsiveLayoutBreakPoints.xLarge,
      ResponsiveLayoutBreakPoints.xxLarge,
    ], [
      '30%',
      '30%',
      '12%',
      '15%',
      '15%',
      '15%'
    ]);
    Widget? body = ResponsiveLayout(
      medium: SingleChildScrollView(
        child: Column(
          children: [
            //Text(constrainst.maxWidth.toString()),
            Card(
              child: SizedBox(
                width: calcWidth([
                  ResponsiveLayoutBreakPoints.medium,
                  ResponsiveLayoutBreakPoints.large,
                  ResponsiveLayoutBreakPoints.xLarge,
                  ResponsiveLayoutBreakPoints.xxLarge,
                ], [
                  '90%',
                  '90%',
                  '90%',
                  '90%'
                ]),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AttributeSlider(
                      onSliderValueChanged: onAlchemySliderValueChanged,
                      value: _currentAlchemySliderValue,
                      caption: "Alchemy",
                      description:
                          "Alchemy skill level. Determines how many effects can you identify\n on ingredients. Improves potion quality, strength and success chance.",
                      breakPoint: contextBreakPoint,
                      width: attributeSliderWidth,
                    ),
                    AttributeSlider(
                      onSliderValueChanged: onIntSliderValueChanged,
                      value: _currentIntSliderValue,
                      caption: "Intelligence",
                      breakPoint: contextBreakPoint,
                      width: attributeSliderWidth,
                    ),
                    AttributeSlider(
                      onSliderValueChanged: onLuckSliderValueChanged,
                      value: _currentLuckSliderValue,
                      caption: "Luck",
                      breakPoint: contextBreakPoint,
                      width: attributeSliderWidth,
                    ),
                  ],
                ),
              ),
            ),
            ConditionallyVisible(
                isVisible: _visibleOn(breakpoints: [
                  ResponsiveLayoutBreakPoints.medium,
                ], currentBreakPoint: contextBreakPoint),
                child: _ActiveEffectsContent()),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConditionallyVisible(
                    isVisible: _visibleOn(breakpoints: [
                      ResponsiveLayoutBreakPoints.large,
                      ResponsiveLayoutBreakPoints.xLarge,
                      ResponsiveLayoutBreakPoints.xxLarge,
                    ], currentBreakPoint: contextBreakPoint),
                    child: _ActiveEffectsContent()),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Center(
                      child: Card(
                        child: SizedBox(
                          width: calcWidth([
                            ResponsiveLayoutBreakPoints.medium,
                            ResponsiveLayoutBreakPoints.large,
                            ResponsiveLayoutBreakPoints.xLarge,
                            ResponsiveLayoutBreakPoints.xxLarge,
                          ], [
                            '30%',
                            '20%',
                            '20%',
                            '20%'
                          ]),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(
                                  top: 20,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Center(
                                      child: _numEffects == 0
                                          ? const Text('No known effects')
                                          : const Text('Known effects',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                    ),
                                    for (var i = 0;
                                        i < _effectsWidgets.length;
                                        ++i)
                                      (_effectsWidgets[i])
                                  ],
                                ),
                              ),
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
                        width: calcWidth([
                          ResponsiveLayoutBreakPoints.medium,
                          ResponsiveLayoutBreakPoints.large,
                          ResponsiveLayoutBreakPoints.xLarge,
                          ResponsiveLayoutBreakPoints.xxLarge,
                        ], [
                          '30%',
                          '20%',
                          '20%',
                          '20%'
                        ]),
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
                          width: calcWidth([
                            ResponsiveLayoutBreakPoints.medium,
                            ResponsiveLayoutBreakPoints.large,
                            ResponsiveLayoutBreakPoints.xLarge,
                            ResponsiveLayoutBreakPoints.xxLarge,
                          ], [
                            '30%',
                            '20%',
                            '20%',
                            '20%'
                          ]),
                          child: Center(
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                                          _addOrRemoveEffect(selectedEffect);
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
                        width: calcWidth([
                          ResponsiveLayoutBreakPoints.medium,
                          ResponsiveLayoutBreakPoints.large,
                          ResponsiveLayoutBreakPoints.xLarge,
                          ResponsiveLayoutBreakPoints.xxLarge,
                        ], [
                          '30%',
                          '20%',
                          '20%',
                          '20%'
                        ]),
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
                                      var ingredient = data.values.firstWhere(
                                          (e) => e['name'] == selection);
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
                          width: calcWidth([
                            ResponsiveLayoutBreakPoints.medium,
                            ResponsiveLayoutBreakPoints.large,
                            ResponsiveLayoutBreakPoints.xLarge,
                            ResponsiveLayoutBreakPoints.xxLarge,
                          ], [
                            '30%',
                            '20%',
                            '20%',
                            '20%'
                          ]),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (var ingredientId in _selectedIngredients)
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
        ),
      ),
      /**/
      xSmall: TabBarView(
        controller: _tabController,
        children: [
          Column(
            children: [
              AttributeSlider(
                onSliderValueChanged: onAlchemySliderValueChanged,
                value: _currentAlchemySliderValue,
                caption: "Alchemy",
                description:
                    "Alchemy skill level. Determines how many effects can you identify\n on ingredients. Improves potion quality, strength and success chance.",
                breakPoint: contextBreakPoint,
                width: attributeSliderWidth,
              ),
              AttributeSlider(
                onSliderValueChanged: onIntSliderValueChanged,
                value: _currentIntSliderValue,
                caption: "Intelligence",
                breakPoint: contextBreakPoint,
                width: attributeSliderWidth,
              ),
              AttributeSlider(
                onSliderValueChanged: onLuckSliderValueChanged,
                value: _currentLuckSliderValue,
                caption: "Luck",
                breakPoint: contextBreakPoint,
                width: attributeSliderWidth,
              ),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Center(
                child: Card(
                  child: SizedBox(
                    child: Column(children: [
                      Center(
                        child: _numEffects == 0
                            ? const Text('No known effects')
                            : Container() /* const Text('Known effects',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold))*/
                        ,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              top: 20,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                for (var i = 0; i < _effectsWidgets.length; ++i)
                                  (_effectsWidgets[i])
                              ],
                            ),
                          ),
                        ],
                      ),
                    ]),
                  ),
                ),
              ),
            ],
          ),
          Center(
            child: Column(
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
                              mainAxisAlignment: MainAxisAlignment.center,
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
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                    onPressed: () {
                                      _addOrRemoveEffect(selectedEffect);
                                    },
                                    icon: Icon(
                                      Icons.close,
                                      color: Colors.red,
                                      size: 12,
                                    ))
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _renderIngredientTextsInColumn(
                                        _ingredientsByEffect[selectedEffect],
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
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                          AutocompleteTextField(
                              caption: 'Enter ingredient name',
                              list: data.values
                                  .toList()
                                  .map((v) => v['name'] as String)
                                  .toSet(),
                              onSelected: (selection) {
                                var ingredient = data.values
                                    .firstWhere((e) => e['name'] == selection);
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
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var ingredientId in _selectedIngredients)
                              (_renderIngredientsWithEffects(ingredientId))
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          _ActiveEffectsContent(),
        ].map((e) => SingleChildScrollView(child: e)).toList(),
      ),
    ).build(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Hoverable(
          child: Tooltip(
            message: 'reset everything',
            child: GestureDetector(
              onTap: () {
                _selectedEffects.clear();
                _selectedIngredients.clear();
                _onSelectedIngredientChange();
                setState(() {});
              },
              child: Text(
                widget.title,
              ),
            ),
          ),
        ),
        bottom: appBarBottom,
      ),
      extendBody: true,
      resizeToAvoidBottomInset: true,
      primary: true,
      body: body,
      /*Column(children: <Widget>[
        ResponsiveLayoutFn(
          xSmall: (className) => Text('$className'),
        ),
        ResponsiveLayout(
          xSmall: TabBarView(
            controller: _tabController,
            children: [
              Container(),
              Container(),
              Container(),
              Container(),
              Container(),
            ],
          ),
        ),
        false
            ? ResponsiveLayout(
                
                xSmall: TabBarView(
                  controller: _tabController,
                  children: [
                    /*
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AttributeSlider(
                    onSliderValueChanged: onAlchemySliderValueChanged,
                    value: _currentAlchemySliderValue,
                    caption: "Alchemy",
                    description:
                        "Alchemy skill level. Determines how many effects can you identify\n on ingredients. Improves potion quality, strength and success chance.",
                    breakPoint: contextBreakPoint,
                  ),
                  AttributeSlider(
                    onSliderValueChanged: onIntSliderValueChanged,
                    value: _currentIntSliderValue,
                    caption: "Intelligence",
                    breakPoint: contextBreakPoint,
                  ),
                  AttributeSlider(
                    onSliderValueChanged: onLuckSliderValueChanged,
                    value: _currentLuckSliderValue,
                    caption: "Luck",
                    breakPoint: contextBreakPoint,
                  ),
                ],
              */
                    Container(),
                    Container(),
                    Container(),
                    Container(),
                    Container(),

                    /*Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Center(
                      child: Card(
                        child: SizedBox(
                          child: Column(children: [
                            Center(
                              child: _numEffects == 0
                                  ? const Text('No known effects')
                                  : Container() /* const Text('Known effects',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold))*/
                              ,
                            ),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceEvenly,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(
                                    top: 20,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      for (var i = 0;
                                          i < _effectsWidgets.length;
                                          ++i)
                                        (_effectsWidgets[i])
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ],
                ),
                Center(
                  child: Column(
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
                                      var ingredient = data.values.firstWhere(
                                          (e) => e['name'] == selection);
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
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                _ActiveEffectsContent()*/
                  ],
                ),
              )
            : Container(),
      ])*/
      //),
      //)/,
      floatingActionButton: floatingActionButton,
    );
  }

  Widget _ActiveEffectsContent() {
    return Center(
      child: SizedBox(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
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
                              style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Center(
                        //

                        child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                            'chance: ${min(100.0, _currentAlchemySliderValue + (_currentIntSliderValue / 10) + (_currentLuckSliderValue / 10)).toStringAsFixed(2)}%',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Tooltip(
                          message: "success chance of creating a potion",
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
                        ),
                      ],
                    )),
                    _renderEffectTextsInColumn(_activeEffects.toList(), 0, 1),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
        _effectsWidgets = List.filled(2, Container());
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
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 4,
      children: [
        ..._prepareEffectsWidgets(arrLabels, start, step)
            .map((e) => SizedBox(width: 200, child: e))
      ],
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
      /*if (url.contains("#stats/")) {
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
      */
    });
  }

  void updateBrowserURL() {
    /*html.window.history.pushState(null, ".",
        '#stats/${_currentIntSliderValue.round()}/${_currentLuckSliderValue.round()}/${_currentAlchemySliderValue.round()}/potion/${_selectedEffects.toList().join(":")}/${_selectedIngredients.toList().join(":")}');*/
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

class TopNavigationTab extends StatelessWidget {
  final String caption;
  final int count;
  final Icon? icon;

  const TopNavigationTab(
      {required this.caption, required this.count, this.icon, super.key});

  @override
  Widget build(BuildContext context) {
    return Tab(
        icon: SizedBox(
          width: 42,
          child: Stack(
            children: [
              icon ?? Icon(Icons.question_mark),
              Positioned(
                left: 22,
                child: CircleAvatar(
                  radius: 8,
                  child: Text(
                    count.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
        child: Column(
          children: [
            Text(
              caption,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ));
  }
}
