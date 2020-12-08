
import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:yuedu_hd/db/BookInfoBean.dart';
import 'package:yuedu_hd/db/bookChapterBean.dart';
import 'package:yuedu_hd/db/book_content_helper.dart';
import 'package:yuedu_hd/db/book_toc_helper.dart';
import 'package:yuedu_hd/db/databaseHelper.dart';
import 'package:yuedu_hd/ui/reading/DisplayConfig.dart';
import 'package:yuedu_hd/ui/reading/DisplayPage.dart';
import 'package:yuedu_hd/ui/reading/DisplayCache.dart';
import 'package:yuedu_hd/ui/reading/PageBreaker.dart';

class ReadingWidget extends StatefulWidget{
  final int bookId;
  final String initChapterName;


  ReadingWidget(this.bookId, this.initChapterName);

  @override
  _ReadingWidgetState createState() => _ReadingWidgetState();
}

class _ReadingWidgetState extends State<ReadingWidget> {
  static const MAX_PAGE = 1999999999;
  static final INIT_PAGE = (MAX_PAGE/2).ceil();


  var tocHelper = BookTocHelper.getInstance();
  var contentHelper = BookContentHelper.getInstance();
  var chaptersList = List<BookChapterBean>();
  var currChapterIndex = 0;
  var initChapterId = -1;
  var initChapterName;
  var displayPageList = LinkedHashMap<int,DisplayPage>();//页码对应显示页面

  var sizeKey = GlobalKey();
  var size = Size(-1, -1);

  PageController _controller;
  var firstPage = INIT_PAGE;

  BookInfoBean bookInfoBean;

  @override
  void initState() {
    _controller = PageController(initialPage: INIT_PAGE);
    Future.delayed(Duration.zero,(){_setupData();});
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: sizeKey,
      child: SizedBox(
        width: double.maxFinite,
        height: double.maxFinite,
        child: PageView.builder(itemBuilder: (ctx,index){
          if(index < firstPage){
            return _buildErrorIndex();
          }
          return DisplayCache.getInstance().get(index);
        },controller: _controller,
          itemCount: MAX_PAGE,onPageChanged: (i){
            Future.delayed(Duration(milliseconds: 500),(){
              notifyPageChanged(i);
            });
          },
        ),
      ),
    );
  }


  @override
  void dispose() {
    super.dispose();
    DisplayCache.getInstance().clear();
  }

  Widget _buildErrorIndex(){
    return Center(
      child: Text('没有了啦'),
    );
  }


  void _setupData() async{
    size = Size.copy(sizeKey.currentContext.size);
    print(size);
    bookInfoBean = await _fetchBookInfo();
    if(widget.initChapterName == null){
      initChapterName = bookInfoBean.lastReadChapter;
    }else{
      initChapterName = widget.initChapterName;
    }
    await _fetchChapters();
  }

  dynamic _fetchBookInfo() async{
    return DatabaseHelper().queryBookById(widget.bookId);
  }

  dynamic _fetchChapters() async{
    //只从数据库获取目录
    var chapters = await tocHelper.getChapterListOnlyDB(widget.bookId);
    chaptersList.clear();
    chaptersList.addAll(chapters);
    _onChaptersLoad();
  }

  ///目录加载完成
  void _onChaptersLoad() async{
    if(chaptersList.isEmpty){
      return;
    }
    //当前阅读的章节，找到章节id
    for(var i =0;i<chaptersList.length;i++){
      var value = chaptersList[i];
      if(value.name == initChapterName){
        initChapterId = value.id;
        currChapterIndex =i;
        break;
      }
    }

    if(initChapterId == -1){
      initChapterId = chaptersList[0].id;
      currChapterIndex = 0;
    }
    //获取当前章节内容
    await _loadChapter(currChapterIndex,INIT_PAGE,false);
    notifyPageChanged(INIT_PAGE);

  }
  ///[fromEnd]为true,[initIndex]为最后一页，需要从后往前填充内容
  dynamic _loadChapter(int chapterIndex,int pageIndex,bool fromEnd) async{
    if(chapterIndex < 0 || chapterIndex >= chaptersList.length){
      return;
    }
    //先占位加载中页面
    DisplayCache.getInstance().put(pageIndex, DisplayPage(DisplayPage.STATUS_LOADING, null));
    setState(() {
      if(chapterIndex == 0){
        firstPage = pageIndex;
      }
    });
    //获取正文
    String chapterContent = await contentHelper.getChapterContent(chaptersList[chapterIndex].id).catchError((e){
      DisplayCache.getInstance().put(pageIndex, DisplayPage(DisplayPage.STATUS_ERROR, null,chapterIndex: chapterIndex,));
    });
    //失败?

    //成功开始分页,制造显示页面
    DisplayConfig config = DisplayConfig.getDefault();
    //内容中每个段落开头的空格
    chapterContent = chapterContent.replaceAll('\n', '\n${' ' * config.spaceParagraph}');

    //标题，正文
    final textStyle = TextStyle(
      color: Color(config.textColor),
      fontSize: config.textSize,
    );

    final textSpan = TextSpan(
      text: chapterContent,
      style: textStyle,
    );
    final titleStyle = TextStyle(
      color: Color(config.titleColor),
      fontSize: config.titleSize,
      fontWeight: FontWeight.bold,
    );
    final titleSpan = TextSpan(
      text: chaptersList[chapterIndex].name.trim(),
      style: titleStyle,
    );
    var textPageSize = Size(size.width- config.margin * 2, size.height - config.margin * 2);
    var pageBreaker = PageBreaker(textSpan, titleSpan, textPageSize);
    var pagesList = pageBreaker.splitPage();
    //分页完成填充数据
    for(var i = 0;i< pagesList.length;i++){
      DisplayCache.getInstance().put(pageIndex + (fromEnd?(i+1-pagesList.length):i), DisplayPage(DisplayPage.STATUS_SUCCESS, pagesList[i],chapterIndex: chapterIndex,currPage: i+1,maxPage: pagesList.length,));
    }

    setState(() {
      print('done!');
      if(fromEnd){
        firstPage = pageIndex - pagesList.length + 1;
      }
    });
    //通知该章节加载完成


  }

  //滚动到了当前页码
  void notifyPageChanged(int index){
    print(index);
    var displayPage = DisplayCache.getInstance().get(index);
    if(displayPage == null) {
      return;
    }
    //更新阅读记录
    if(displayPage.currPage == 1){
      DatabaseHelper().updateLastReadChapter(widget.bookId, chaptersList[displayPage.chapterIndex].name);
    }

    //如果是章节第一页，加载前一章
    if(displayPage!=null && displayPage.currPage == 1){//第一页,加载上一章节
      var tempPage = DisplayCache.getInstance().get(index-1);
      if(tempPage!=null){
        //有缓存不加载
        return;
      }
      print('加载上一章节');
      _loadChapter(displayPage.chapterIndex-1, index-1, true);
    }
    //如果是章节最后一页，加载后一章
    if(displayPage!=null && displayPage.currPage == displayPage.maxPage){//最后一页,加载下一章节
      var tempPage = DisplayCache.getInstance().get(index+1);
      if(tempPage!=null){
        //有缓存不加载
        return;
      }
      print('加载下一章节');
      _loadChapter(displayPage.chapterIndex+1, index+1, false);
    }

  }




}