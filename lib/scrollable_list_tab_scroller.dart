library scrollable_list_tab_scroller;

import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:uuid/uuid.dart';

typedef IndexedActiveStatusWidgetBuilder = Widget Function(
    BuildContext context, int index, bool active);
typedef IndexedVoidCallback = void Function(int index);

typedef HeaderContainerBuilder = Widget Function(
    BuildContext context, Widget child);
typedef HeaderWidgetBuilder = Widget Function(
  BuildContext context,
  ValueNotifier<int> selectedTabIndex,
  IndexedVoidCallback onTapTab,
  IndexedActiveStatusWidgetBuilder tabBuilder,
  int itemCount,
);
typedef BodyContainerBuilder = Widget Function(
    BuildContext context, Widget child);

class ScrollableListTabScroller extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final IndexedActiveStatusWidgetBuilder tabBuilder;
  final HeaderContainerBuilder? headerContainerBuilder;
  final HeaderWidgetBuilder? headerWidgetBuilder;
  final BodyContainerBuilder? bodyContainerBuilder;
  final ItemScrollController? itemScrollController;
  final PageController? tabPageController;
  final ItemPositionsListener? itemPositionsListener;
  final void Function(int)? tabChanged;
  final double earlyChangePositionOffset;
  final Duration animationDuration;

  ScrollableListTabScroller({
    required this.itemCount,
    required this.itemBuilder,
    required this.tabBuilder,
    HeaderContainerBuilder? headerContainerBuilder,
    @Deprecated("use 'headerContainerBuilder' instead")
        HeaderContainerBuilder? headerBuilder,
    this.headerWidgetBuilder,
    BodyContainerBuilder? bodyContainerBuilder,
    @Deprecated("use 'bodyContainerBuilder' instead")
        BodyContainerBuilder? bodyBuilder,
    this.itemScrollController,
    this.tabPageController,
    this.itemPositionsListener,
    this.tabChanged,
    @Deprecated("use 'earlyChangePositionOffset' instead")
        double? minEdgeBeforeChangeTab,
    double? earlyChangePositionOffset,
    this.animationDuration = const Duration(milliseconds: 300),
  })  : assert(headerContainerBuilder == null || headerBuilder == null,
            "You must use just 'headerContainerBuilder'"),
        assert(bodyContainerBuilder == null || bodyBuilder == null,
            "You must use just 'bodyContainerBuilder'"),
        assert(
            earlyChangePositionOffset == null || minEdgeBeforeChangeTab == null,
            "You must use just 'earlyChangePositionOffset'"),
        headerContainerBuilder = headerContainerBuilder ?? headerBuilder,
        bodyContainerBuilder = bodyContainerBuilder ?? bodyBuilder,
        this.earlyChangePositionOffset =
            earlyChangePositionOffset ?? minEdgeBeforeChangeTab ?? 0;

  @override
  ScrollableListTabScrollerState createState() =>
      ScrollableListTabScrollerState();
}

class ScrollableListTabScrollerState extends State<ScrollableListTabScroller> {
  late final ItemScrollController itemScrollController;
  late final PageController tabPageController;
  late final ItemPositionsListener itemPositionsListener;
  bool disableItemPositionListener = false;
  final _selectedTabIndex = ValueNotifier(0);
  final _debounceId = "scrollable_list_tab_scroller_" + Uuid().v1();
  Size _currentPositionedListSize = Size.zero;

  @override
  void initState() {
    super.initState();
    // try to use user controllers or create them
    itemScrollController =
        widget.itemScrollController ?? ItemScrollController();
    itemPositionsListener =
        widget.itemPositionsListener ?? ItemPositionsListener.create();

    itemPositionsListener.itemPositions.addListener(_itemPositionListener);

    _selectedTabIndex.addListener(() {
      EasyDebounce.debounce(_debounceId, widget.animationDuration, () {
        widget.tabChanged?.call(_selectedTabIndex.value);
      });
    });
  }

  void _triggerScrollInPositionedListIfNeeded(int index) {
    if (getDisplayedPositionFromList() != index &&
        // Prevent operation when length == 0 (Component was rendered outside screen)
        itemPositionsListener.itemPositions.value.length != 0) {
      // disableItemPositionListener = true;
      if (itemScrollController.isAttached) {
        itemScrollController.scrollTo(
            index: index, duration: widget.animationDuration);
      }
    }
  }

  void setCurrentActiveIfDifferent(int currentActive) {
    if (_selectedTabIndex.value != currentActive)
      _selectedTabIndex.value = currentActive;
  }

  void _itemPositionListener() {
    // Prevent operation when length == 0 (Component was rendered outside screen)
    if (itemPositionsListener.itemPositions.value.length == 0) {
      return;
    }
    final displayedIdx = getDisplayedPositionFromList();
    if (displayedIdx != null) {
      setCurrentActiveIfDifferent(displayedIdx);
    }
  }

  int? getDisplayedPositionFromList() {
    final value = itemPositionsListener.itemPositions.value;
    if (value.length < 1) {
      return null;
    }
    final orderedListByPositionIndex = value.toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    final renderedMostTopItem = orderedListByPositionIndex.first;
    if (renderedMostTopItem.getBottomOffset(_currentPositionedListSize) <
        widget.earlyChangePositionOffset) {
      if (orderedListByPositionIndex.length > 1) {
        return orderedListByPositionIndex[1].index;
      }
    }
    return renderedMostTopItem.index;
  }

  void onTapTab(int index) => _triggerScrollInPositionedListIfNeeded(index);

  Widget buildCustomHeaderContainerOrDefault(
      {required BuildContext context, required Widget child}) {
    return widget.headerContainerBuilder?.call(context, child) ??
        SizedBox(
          height: 30,
          child: child,
        );
  }

  Widget buildCustomBodyContainerOrDefault(
      {required BuildContext context, required Widget child}) {
    return widget.bodyContainerBuilder?.call(context, child) ??
        Expanded(
          child: child,
        );
  }

  Widget buildCustomHeaderWidgetBuilderOrDefault(
    BuildContext context,
    ValueNotifier<int> selectedTabIndex,
    IndexedVoidCallback onTapTab,
    IndexedActiveStatusWidgetBuilder tabBuilder,
    int itemCount,
  ) {
    return widget.headerWidgetBuilder?.call(
            context, selectedTabIndex, onTapTab, tabBuilder, itemCount) ??
        DefaultHeaderWidget(
          selectedTabIndex: selectedTabIndex,
          tabBuilder: tabBuilder,
          onTapTab: onTapTab,
          itemCount: itemCount,
          animationDuration: widget.animationDuration,
          tabPageController: widget.tabPageController,
        );
  }

  @override
  void dispose() {
    EasyDebounce.cancel(_debounceId);
    itemPositionsListener.itemPositions.removeListener(_itemPositionListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        buildCustomHeaderContainerOrDefault(
          context: context,
          child: buildCustomHeaderWidgetBuilderOrDefault(
            context,
            _selectedTabIndex,
            onTapTab,
            widget.tabBuilder,
            widget.itemCount,
          ),
        ),
        buildCustomBodyContainerOrDefault(
            context: context,
            child: Builder(builder: (context) {
              // Keep using '?', must be removed later
              WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
                final size = context.size;
                if (size != null) {
                  _currentPositionedListSize = size;
                }
              });
              return ScrollablePositionedList.builder(
                itemBuilder: (a, b) {
                  return widget.itemBuilder(a, b);
                },
                itemCount: widget.itemCount,
                itemScrollController: itemScrollController,
                itemPositionsListener: itemPositionsListener,
              );
            }))
      ],
    );
  }
}

class DefaultHeaderWidget extends StatefulWidget {
  final ValueNotifier<int> selectedTabIndex;
  final IndexedActiveStatusWidgetBuilder tabBuilder;
  final IndexedVoidCallback onTapTab;
  final int itemCount;
  final PageController? tabPageController;
  final Duration animationDuration;

  DefaultHeaderWidget({
    Key? key,
    required this.selectedTabIndex,
    required this.tabBuilder,
    required this.onTapTab,
    required this.itemCount,
    this.animationDuration = const Duration(milliseconds: 300),
    this.tabPageController,
  }) : super(key: key);

  @override
  State<DefaultHeaderWidget> createState() => _DefaultHeaderWidgetState();
}

class _DefaultHeaderWidgetState extends State<DefaultHeaderWidget> {
  late final PageController tabPageController;
  bool isNotifyPageChangedEnabled = true;
  final _debounceId =
      "scrollable_list_tab_scroller_default_header" + Uuid().v1();

  @override
  void initState() {
    super.initState();
    tabPageController =
        widget.tabPageController ?? PageController(viewportFraction: 0.5);
    widget.selectedTabIndex.addListener(externalTabChangeListener);
  }

  void externalTabChangeListener() {
    isNotifyPageChangedEnabled = false;
    tabPageController
        .animateToPage(widget.selectedTabIndex.value,
            duration: widget.animationDuration, curve: Curves.ease)
        .whenComplete(() {
      EasyDebounce.debounce(_debounceId, widget.animationDuration, () {
        isNotifyPageChangedEnabled = true;
      });
    });
  }

  void _onTabsPageChanged(int index) {
    if (isNotifyPageChangedEnabled) {
      widget.onTapTab(index);
    }
    tabPageController.jumpToPage(widget.selectedTabIndex.value);
  }

  @override
  void dispose() {
    if (widget.tabPageController == null) {
      tabPageController.dispose();
    }
    widget.selectedTabIndex.removeListener(externalTabChangeListener);
    EasyDebounce.cancel(_debounceId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      physics: AlwaysScrollableScrollPhysics(),
      itemBuilder: (_, index) {
        return RawMaterialButton(
          onPressed: () => widget.onTapTab(index),
          child: Center(
            child: ValueListenableBuilder(
                valueListenable: widget.selectedTabIndex,
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
    );
  }
}

// Utils

extension _ItemPositionUtilsExtension on ItemPosition {
  double getBottomOffset(Size size) {
    return itemTrailingEdge * size.height;
  }
}
