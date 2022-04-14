library scrollable_list_tab_scroller;

import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:uuid/uuid.dart';

typedef IndexedActiveStatusWidgetBuilder = Widget Function(
    BuildContext context, int index, bool active);

typedef HeaderBuilder = Widget Function(BuildContext context, Widget child);
typedef BodyBuilder = Widget Function(BuildContext context, Widget child);

class ScrollableListTabScroller extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final IndexedActiveStatusWidgetBuilder tabBuilder;
  final HeaderBuilder? headerBuilder;
  final BodyBuilder? bodyBuilder;
  final ItemScrollController? itemScrollController;
  final PageController? tabPageController;
  final ItemPositionsListener? itemPositionsListener;
  final void Function(int)? tabChanged;
  final double minEdgeBeforeChangeTab;

  ScrollableListTabScroller({
    required this.itemCount,
    required this.itemBuilder,
    required this.tabBuilder,
    this.headerBuilder,
    this.bodyBuilder,
    this.itemScrollController,
    this.tabPageController,
    this.itemPositionsListener,
    this.tabChanged,
    this.minEdgeBeforeChangeTab = 0,
  });

  @override
  ScrollableListTabScrollerState createState() =>
      ScrollableListTabScrollerState();
}

class ScrollableListTabScrollerState
    extends State<ScrollableListTabScroller> {
  late final ItemScrollController itemScrollController;
  late final PageController tabPageController;
  late final ItemPositionsListener itemPositionsListener;
  bool disableItemPositionListener = false;
  final _currentActive = ValueNotifier(0);
  final _debouceId = "scrollable_list_tab_scroller_" + Uuid().v1();

  @override
  void initState() {
    super.initState();
    // try to use user controllers or create them
    itemScrollController =
        widget.itemScrollController ?? ItemScrollController();
    tabPageController =
        widget.tabPageController ?? PageController(viewportFraction: 0.5);
    itemPositionsListener =
        widget.itemPositionsListener ?? ItemPositionsListener.create();

    itemPositionsListener.itemPositions.addListener(_itemPositionListener);
  }

  void setCurrentActiveIfDifferent(int currentActive) {
    if (this._currentActive.value != currentActive)
      this._currentActive.value = currentActive;
  }

  void _onTabsPageChanged(int index) {
    if (_currentActive.value != index &&
        // Prevent operation when length == 0 (Component was rendered outside screen)
        itemPositionsListener.itemPositions.value.length != 0) {
      disableItemPositionListener = true;
      if(itemScrollController.isAttached){
        itemScrollController
            .scrollTo(index: index, duration: Duration(milliseconds: 300))
            .whenComplete(() => disableItemPositionListener = false);
      }
      setCurrentActiveIfDifferent(index);
    }
    widget.tabChanged?.call(index);
  }

  void _onPressedTab(int index) {
    tabPageController.animateToPage(index,
        duration: Duration(milliseconds: 500), curve: Curves.ease);
  }

  void _itemPositionListener() {
    // Prevent operation when length == 0 (Component was rendered outside screen)
    if (itemPositionsListener.itemPositions.value.length == 0) {
      return;
    }
    final value = itemPositionsListener.itemPositions.value;
    final lastItem = value.last;
    if (disableItemPositionListener || lastItem.itemTrailingEdge <= 1) {
      return;
    }
    final firstItem = value.first;
    final secondItem = value.length > 1 ? value.elementAt(1) : null;
    if (secondItem != null) {
      if (secondItem.itemLeadingEdge <= widget.minEdgeBeforeChangeTab) {
        EasyDebounce.debounce(_debouceId, Duration(milliseconds: 100), () {
          setCurrentActiveIfDifferent(secondItem.index);
          tabPageController.animateToPage(secondItem.index,
              duration: Duration(milliseconds: 300), curve: Curves.ease);
        });
        return;
      }
    }
    EasyDebounce.debounce(_debouceId, Duration(milliseconds: 100), () {
      setCurrentActiveIfDifferent(firstItem.index);
      tabPageController.animateToPage(firstItem.index,
          duration: Duration(milliseconds: 300), curve: Curves.ease);
    });
  }

  Widget buildHeader({required BuildContext context, required Widget child}) {
    return widget.headerBuilder?.call(context, child) ??
        SizedBox(
          height: 30,
          child: child,
        );
  }
  Widget buildBody({required BuildContext context, required Widget child}) {
    return widget.bodyBuilder?.call(context, child) ??
        Expanded(
          child: child,
        );
  }

  @override
  void dispose() {
    EasyDebounce.cancel(_debouceId);
    itemPositionsListener.itemPositions.removeListener(_itemPositionListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        buildHeader(
          context: context,
          child: PageView.builder(
            physics: AlwaysScrollableScrollPhysics(),
            itemBuilder: (_, index) {
              return RawMaterialButton(
                onPressed: () => _onPressedTab(index),
                child: Center(
                  child: ValueListenableBuilder(
                      valueListenable: _currentActive,
                      builder: (context, int value, _) {
                        final isActive = value == index;
                        return widget.tabBuilder(context, index, isActive);
                      }),
                ),
              );
            },
            itemCount: widget.itemCount,
            scrollDirection: Axis.horizontal,
            controller: tabPageController,
            onPageChanged: _onTabsPageChanged,
          ),
        ),
        buildBody(context: context, child: ScrollablePositionedList.builder(
          itemBuilder: (a, b) {
            return widget.itemBuilder(a, b);
          },
          itemCount: widget.itemCount,
          itemScrollController: itemScrollController,
          itemPositionsListener: itemPositionsListener,
        ))
      ],
    );
  }
}