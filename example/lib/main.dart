import 'package:flutter/material.dart';
import 'package:scrollable_list_tab_scroller/scrollable_list_tab_scroller.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scrollable List Tab Scroller',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Scrollable List Tab Scroller'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final data = {
    "Category A": [
      "Item 1 (A)",
      "Item 2 (A)",
      "Item 3 (A)",
      "Item 4 (A)",
    ],
    "Category B": [
      "Item 1 (B)",
      "Item 2 (B)",
    ],
    "Category C": [
      "Item 1 (C)",
      "Item 2 (C)",
      "Item 3 (C)",
      "Item 4 (C)",
      "Item 5 (C)",
    ],
    "Category D": [
      "Item 1 (D)",
      "Item 2 (D)",
      "Item 3 (D)",
      "Item 4 (D)",
      "Item 5 (D)",
    ],
    "Category E": [
      "Item 1 (E)",
      "Item 2 (E)",
      "Item 3 (E)",
      "Item 4 (E)",
      "Item 5 (E)",
    ],
    "Category F": [
      "Item 1 (F)",
      "Item 2 (F)",
      "Item 3 (F)",
      "Item 4 (F)",
      "Item 5 (F)",
    ],
    "Category G": [
      "Item 1 (G)",
      "Item 2 (G)",
      "Item 3 (G)",
      "Item 4 (G)",
      "Item 5 (G)",
    ],
    "Category H": [
      "Item 1 (H)",
      "Item 2 (H)",
      "Item 3 (H)",
      "Item 4 (H)",
      "Item 5 (H)",
    ],
    "Category I": [
      "Item 1 (I)",
      "Item 2 (I)",
      "Item 3 (I)",
      "Item 4 (I)",
      "Item 5 (I)",
      "Item 6 (I)",
      "Item 7 (I)",
      "Item 8 (I)",
      "Item 9 (I)",
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ScrollableListTabScroller(
        itemCount: data.length,
        tabBuilder: (BuildContext context, int index, bool active) => Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            data.keys.elementAt(index),
            style: !active
                ? null
                : TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
          ),
        ),
        itemBuilder: (BuildContext context, int index) => Column(
          children: [
            Text(
              data.keys.elementAt(index),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            ...data.values
                .elementAt(index)
                .asMap()
                .map(
                  (index, value) => MapEntry(
                    index,
                    ListTile(
                      leading: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: Colors.grey),
                        alignment: Alignment.center,
                        child: Text(index.toString()),
                      ),
                      title: Text(value),
                    ),
                  ),
                )
                .values
          ],
        ),
      ),
    );
  }
}
