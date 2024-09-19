import 'dart:ui';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:waterfall_flow/waterfall_flow.dart';
import 'package:yuedu_hd/db/BookInfoBean.dart';
import 'package:yuedu_hd/db/BookSourceBean.dart';
import 'package:yuedu_hd/db/explore_helper.dart';
import 'package:yuedu_hd/ui/bookshelf/widget_book_detail.dart';
import 'package:yuedu_hd/ui/style/ycolors.dart';
import 'package:yuedu_hd/ui/widget/WheelScroll4Desktop.dart';
import 'package:yuedu_hd/ui/widget/space.dart';

class PageExplore extends StatefulWidget {
  @override
  _PageExploreState createState() => _PageExploreState();
}

class _PageExploreState extends State<PageExplore>
    with TickerProviderStateMixin {
  var sourceList = <BookSourceBean>[];
  TabController? _tabController;
  BookSourceBean? activeSource = null;
  List<List<String>>? tabs;
  List<List<BookInfoBean>> bookListOfTabs = [];
  var _selectBookId = -1;

  @override
  void initState() {
    this.initLoadSourceList();
    super.initState();
    _tabController = 
      TabController(length: 0, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void useSourceItem(int itemIdx) {
    var activeItem = sourceList[itemIdx];
    var theSourceTabs = activeItem.exploreUrl?.split('\n').map((e) {
      return e.split('::');
    }).toList();
    activeSource = activeItem;
    tabs = theSourceTabs;
    bookListOfTabs = tabs!.map((e) {
      return <BookInfoBean>[];
    }).toList();
    _tabController?.dispose();
    _tabController =
        TabController(length: theSourceTabs?.length ?? 0, vsync: this);
    _tabController?.addListener(() {
      if(_tabController!.index != _tabController!.previousIndex) {
        this.loadTabBookList(_tabController!.index, false);
        if (_selectBookId != -1) {
          _selectBookId = -1;
          setState(() {});
        }
      }
    });
    this.loadTabBookList(0, false);
    setState(() {});
  }

  void initLoadSourceList() {
    ExploreHelper.getInstance().getExplorableSource().then((value) {
      if (value.length > 0) {
        sourceList = value;
        setState(() {
          if (activeSource == null) {
            this.useSourceItem(0);
          }
        });
      }
    });
  }

  loadTabBookList(int tabIdx, bool refreshList) {
    var reqOptions = BookExploreUrlBean();
    reqOptions.method = 'get';
    reqOptions.url = tabs!.toList()[tabIdx][1];
    if(bookListOfTabs[tabIdx].isEmpty || refreshList == true) {
      bookListOfTabs[tabIdx] = [];
      ExploreHelper.getInstance().requestExploreSection(reqOptions, (data) {
        bookListOfTabs[tabIdx].add(data);
      }, () {
        setState(() {});
      }, activeSource!);
    }
  }

  TabBar theTopTabBar() {
    return TabBar(
      tabAlignment: TabAlignment.start,
      tabs: tabs?.map((e) {
            return Tab(
              text: e[0],
            );
          }).toList() ??
          [],
      controller: _tabController,
      indicatorColor: Colors.transparent,
      indicatorSize: TabBarIndicatorSize.label,
      isScrollable: true,
      labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
      unselectedLabelStyle:
          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
    );
  }

  Widget _buildList(List<BookInfoBean> books, context, bool isPortrait) {
    var _scrollController = ScrollController();
    return RefreshIndicator(
        color: YColors.primary,
        onRefresh: () async {
          this.loadTabBookList(_tabController?.index ?? 0, true);
        },
        child: ListView.builder(
          // Add a key to the ListView. This makes it possible to
          // find the list and scroll through it in the tests.
          itemCount: books.length,
          itemBuilder: (ctx, index) => _buildItem(ctx, books[index]),
        ));
        // child: WheelScroll4Desktop(
        //   scrollController: _scrollController,
        //   child: MediaQuery.removePadding(
        //     context: context,
        //     removeTop: true,
        //     child: ScrollConfiguration(
        //       behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {
        //         PointerDeviceKind.touch,
        //         PointerDeviceKind.mouse
        //       }),
        //       child: WaterfallFlow.builder(
        //         physics: AlwaysScrollableScrollPhysics(),
        //         controller: _scrollController,
        //         gridDelegate:
        //             SliverWaterfallFlowDelegateWithFixedCrossAxisCount(
        //                 crossAxisCount: isPortrait ? 1 : 2),
        //         itemBuilder: (ctx, index) => _buildItem(ctx, books[index]),
        //         itemCount: books.length,
        //       ),
        //     ),
        //   ),
        // ));
  }

  Widget _buildItem(BuildContext ctx, BookInfoBean infoBean) {
    var theme = Theme.of(ctx);
    return GestureDetector(
      onTap: () {
        _selectBookId = infoBean.id;
        setState(() {});
      },
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
            // color: theme.cardColor,
            ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: Colors.grey,
              child: SizedBox(
                height: 100,
                width: 80,
                child: ExtendedImage.network(
                  infoBean.coverUrl!,
                  width: 80,
                  height: 100,
                  fit: BoxFit.fill,
                  cache: true,
                  borderRadius: BorderRadius.all(Radius.circular(4.0)),
                ),
              ),
            ),
            HSpace(8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    infoBean.name!,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: theme.textTheme.titleMedium!.fontSize),
                  ),
                  Text(infoBean.author!),
                  Text(
                    infoBean.intro ?? '没有简介内容',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  )
                ],
              )
            ),
          ],
        ),
      ),
    );
  }

  TabBarView theExploreTabView(context) {
    ThemeData theme = Theme.of(context);
    bool isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    return TabBarView(
        controller: _tabController,
        children: bookListOfTabs.map((books) {
          return Container(
              decoration: BoxDecoration(
                border: Border.all(color: YColors.border_color, width: 5),
                color: theme.cardColor,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              margin: EdgeInsets.all(8),
              child: Stack(children: [
                _buildList(books, context, isPortrait),
                Visibility(
                    visible: books.isEmpty,
                    child: Center(
                        child: Text(
                      '此列表暂时没有书籍',
                      textAlign: TextAlign.center,
                    )))
              ]));
        }).toList());
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Scaffold(
      body: Container(
        margin: EdgeInsets.only(left: 8, right: 8, top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text(activeSource?.bookSourceName ?? '没有源', style: themeData.textTheme.bodySmall),
            Row(
              children: [
                Expanded(
                  child: theTopTabBar(),
                ),
                sourceList.length > 1 ? IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.toc_outlined),
                ) : Row(),
              ],
            ),
            Expanded(
                child: Stack(
              children: [
                theExploreTabView(context),
                Visibility(
                    visible: _selectBookId != -1,
                    child: Container(
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: YColors.border_color, width: 5),
                          color: theme.colorScheme.background,
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                        child: BookDetailWidget(
                          _selectBookId,
                          backClick: () {
                            _selectBookId = -1;
                            setState(() {});
                          },
                        )))
              ],
            ))
          ],
        ),
      ),
    );
  }
}
