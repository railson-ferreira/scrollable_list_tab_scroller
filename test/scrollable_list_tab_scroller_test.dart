import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scrollable_list_tab_scroller/scrollable_list_tab_scroller.dart';

void main() {
  final data = {
    "category A": [
      "Item 1 (A)",
      "Item 1 (A)",
      "Item 1 (A)",
    ],
    "category B": [
      "Item 1 (B)",
      "Item 2 (B)",
    ],
    "category C": [
      "Item 1 (C)",
      "Item 2 (C)",
      "Item 3 (C)",
      "Item 4 (C)",
      "Item 5 (C)",
    ],
    "category D": [
      "Item 1 (D)",
    ],
  };
  testWidgets('test', (tester) async {
    var widget = ScrollableListTabScroller(
      tabBuilder: (BuildContext context, int index, bool active) =>
          Text(data.keys.elementAt(index)),
      itemCount: data.length,
      itemBuilder: (BuildContext context, int index) => Wrap(
        children: [
          Text(data.keys.elementAt(index)),
          ...data.values.elementAt(index).map((e) => Text(e))
        ],
      ),
    );
    var mainWidget = MaterialApp(
      home: Material(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: widget,
        ),
      ),
    );
    await tester.pumpWidget(mainWidget);
    // Test our main widget.
    expect(find.byWidget(mainWidget), findsOneWidget);
  });
}
