import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:worker_manager/worker_manager.dart';
import 'package:yuedu_hd/db/BookInfoBean.dart';
import 'package:yuedu_hd/db/BookSourceBean.dart';
import 'package:yuedu_hd/db/bookChapterBean.dart';
import 'package:yuedu_hd/db/databaseHelper.dart';
import 'dart:developer' as developer;

import 'utils.dart';

typedef void OnChaptersLoad(List<BookChapterBean> chapters);
typedef void OnCancelToken(String cancelToken);

///目录更新!
class BookTocHelper {
  static BookTocHelper? _instance;
  static BookTocHelper getInstance() {
    if (_instance == null) {
      _instance = BookTocHelper._init();
    }
    return _instance!;
  }

  var cancelToken = [];
  BookTocHelper._init() {
    //
  }

  void cancel(String? token) {
    if (token != null && token.isNotEmpty) {
      cancelToken.add(token);
    }
  }

  Future<List<BookChapterBean>> updateChapterList(int bookId, int sourceId,
      {BookInfoBean? bookBean,
      bool notUpdateDB = false,
      onlyLast = false,
      OnCancelToken? onCancelToken}) async {
    var myCancelToken = '${DateTime.now()}';
    if (onCancelToken == null) {
      onCancelToken = (s) {};
    }
    onCancelToken(myCancelToken);
    //warmup
    List<BookChapterBean> result = [];
    //1.拿到书源
    //2.书链接
    BookInfoBean book;
    if (bookBean != null) {
      //使用外面给的数据
      book = bookBean;
    } else {
      book = await DatabaseHelper()
          .queryBookInfoFromBookIdCombSourceId(bookId, sourceId);
    }
    BookSourceBean sourceBean = book.sourceBean!;
    BookTocRuleBean ruleBean = book.sourceBean!.mapTocRuleBean();
    BookInfoRuleBean? infoRuleBean;
    if (book.sourceBean?.ruleBookInfo != null &&
        book.sourceBean!.ruleBookInfo!.isNotEmpty) {
      infoRuleBean = book.sourceBean?.mapInfoRuleBean();
    }
    var charset = sourceBean.mapSearchUrlBean()?.charset;
    Options requestOptions = Options(
        sendTimeout: Duration(milliseconds: 10000),
        receiveTimeout: Duration(milliseconds: 10000));
    // if(charset == 'gbk'){
    requestOptions.responseDecoder = Utils.gbkDecoder;
    // }
    var headers =
        Utils.buildHeaders(book.bookUrl!, ContentType.html.toString(), null);
    requestOptions.headers = headers;
    //3.请求网络
    var bookUrl = book.bookUrl!;

    try {
      var dio = Utils.createDioClient();
      dio.options.connectTimeout = Duration(milliseconds: 15000);
      //解析真正的目录页
      if (infoRuleBean != null &&
          infoRuleBean.tocUrl != null &&
          infoRuleBean.tocUrl!.isNotEmpty) {
        if (cancelToken.contains(myCancelToken)) {
          cancelToken.remove(myCancelToken);
          throw Exception('用户取消');
        }

        var response = await dio.get(book.bookUrl!, options: requestOptions);
        if (response.statusCode == 200) {
          var tocUrl = await workerManager.execute(() async {
            return await _parseTocUrl(
                response.data as String, infoRuleBean!, bookUrl);
          }, priority: WorkPriority.immediately);
          developer.log(
              '解析真正的目录请求[$bookUrl] 结果[$tocUrl] 规则[${infoRuleBean.tocUrl}]');
          bookUrl = Utils.checkLink(bookUrl, tocUrl);
          if (bookUrl.isEmpty) {
            bookUrl = book.bookUrl!;
          }
        } else {
          developer.log('解析真正的目录请求失败 $bookUrl');
        }
      }
      //剩余的目录分页
      var tocUrlList = [];
      tocUrlList.add(bookUrl);
      //所有的目录分页，为了去重
      var allTocUrlList = [];
      allTocUrlList.add(bookUrl);

      while (tocUrlList.isNotEmpty) {
        var curUrl = tocUrlList.removeAt(0);
        developer.log('目录请求 $curUrl');
        if (cancelToken.contains(myCancelToken)) {
          cancelToken.remove(myCancelToken);
          throw Exception('用户取消');
        }
        var response = await dio.get(curUrl, options: requestOptions);
        if (cancelToken.contains(myCancelToken)) {
          cancelToken.remove(myCancelToken);
          throw Exception('用户取消');
        }
        if (response.statusCode == 200) {
          developer.log('目录解析 $curUrl');
          var chapters = await workerManager.execute(() async {
            // Your CPU-intensive function here
            return await _parseResponse(response.data, ruleBean, curUrl);
          }, priority: WorkPriority.immediately);
          if (ruleBean.nextTocUrl != null &&
              ruleBean.nextTocUrl!.trim().isNotEmpty) {
            var nextUrl = await workerManager.execute(() async {
            return await _parseNextUrl(
                response.data as String, ruleBean, curUrl);
          }, priority: WorkPriority.immediately);
            if (nextUrl != null ||
                nextUrl.trim().isNotEmpty && nextUrl != "null") {
              //可能是数组，采用逗号分割
              var urls = nextUrl.split(',');
              urls.forEach((element) {
                var next = Utils.checkLink(curUrl, element).trim();
                if (element != "null" &&
                    next != "null" &&
                    next.isNotEmpty &&
                    !allTocUrlList.contains(next)) {
                  tocUrlList.add(next);
                  allTocUrlList.add(next);
                }
              });
            }
          }
          for (var chapter in chapters) {
            chapter.url = Utils.checkLink(curUrl, chapter.url!);
            chapter.bookId = book.id;
            chapter.sourceId = book.source_id!;
          }
          if (chapters.isEmpty) {
            break;
          }
          if (onlyLast) {
            result.add(chapters.last);
          } else {
            result.addAll(chapters);
          }
          if (result.isEmpty) {
            throw Exception('目录为空');
          }
          chapters.clear();
        } else if (response.statusCode == 404) {
          //可能是分页的问题,没有后续了
          //pass
        } else {
          developer.log('目录解析错误:$bookUrl,网络错误${response.statusCode}');
          throw Exception('网络错误${response.statusCode}');
        }
      }
      developer.log('目录解析完成,目录数量:${result.length}');
    } catch (e) {
      if (cancelToken.contains(myCancelToken)) {
        cancelToken.remove(myCancelToken);
      }
      developer.log('$bookUrl 目录解析错误[使用规则${ruleBean.toString()}]:$e');
      return Future.error(e);
    }
    if (result.isNotEmpty && !notUpdateDB) {
      developer.log('目录插入开始 ${DateTime.now()}');
      await insertChapterToDB(result);
      developer.log('目录插入结束 ${DateTime.now()}');
      result = await DatabaseHelper().queryBookChapters(bookId);
      developer.log('目录二查结束 ${DateTime.now()}');
    }
    if (cancelToken.contains(myCancelToken)) {
      cancelToken.remove(myCancelToken);
    }
    return Future.value(result);
  }

  ///从数据库读取数据,再从网络更新
  dynamic getChapterList(int bookId, OnChaptersLoad onChaptersLoad) async {
    List<BookChapterBean> chaptersFromDB =
        await DatabaseHelper().queryBookChapters(bookId);
    onChaptersLoad(chaptersFromDB);
    var chaptersFromNetWork =
        await updateChapterList(bookId, -1, notUpdateDB: false);
    onChaptersLoad(chaptersFromNetWork);
  }

  ///仅从数据库读取数据
  dynamic getChapterListOnlyDB(int bookId,
      {int from = -1, int limit = 99999}) async {
    return await DatabaseHelper()
        .queryBookChapters(bookId, from: from, limit: limit);
  }

  dynamic insertChapterToDB(List<BookChapterBean> list) async {
    return await DatabaseHelper().updateToc(list);
  }
}

FutureOr<dynamic> _parseResponse(
    String data, BookTocRuleBean ruleBean, String url) {
  var trimedResStr = data.trim();
  if (trimedResStr.isEmpty) {
    return '';
  }
  List<BookChapterBean> result = [];
  // handle json type content

  if (RegExp(r'^(\{|\[)').hasMatch(trimedResStr) &&
      RegExp(r'(\}|\])$').hasMatch(trimedResStr)) {
    var chapterList =
        Utils.parseFromJsonPath(ruleBean.chapterList, trimedResStr);
    chapterList.forEach((element) {
      if (element.value == null) {
        return null;
      }
      var chapterBean = BookChapterBean();
      chapterBean.name =
          Utils.parseObjByJsonPath(ruleBean.chapterName, element.value!)
                  .first
                  .value
                  .toString()
                  ?.replaceAll('\n', '') ??
              "";
      chapterBean.url = RegExp(r'^\$\.').hasMatch(ruleBean.chapterUrl ?? "")
          ? Utils.parseObjByJsonPath(ruleBean.chapterUrl, element.value!)
              .first
              .value
              .toString()
          : ruleBean.chapterUrl?.replaceAllMapped(RegExp(r"\{[^\{\}]*\}"),
                  (match) {
                var path = match[0]?.substring(1, match[0]!.length - 1) ?? "";
                return Utils.parseObjByJsonPath(path, element.value!)
                    .first
                    .value
                    .toString();
              }) ??
              "";
      result.add(chapterBean);
    });
  }

  developer.log('目录解析结束 ${DateTime.now()}');
  if (result.isNotEmpty) {
    if (result.lastIndexOf(result[0]) > 0) {
      var subIndex = 0;
      for (var i = 1; i < result.length; i++) {
        var t = result[i];
        if (result.lastIndexOf(t) == i) {
          subIndex = i;
          break;
        }
      }
      result = result.sublist(subIndex);
    }
  }
  // for(var t in result){
  //   developer.log(t.toString());
  // }
  // cache.destroy();
  developer.log('解析的总目录${result.length}');
  return result;
}

FutureOr<dynamic> _parseNextUrl(
    String data, BookTocRuleBean ruleBean, String url) {
  var trimedResStr = data.trim();
  if (trimedResStr.isEmpty) {
    return '';
  }
  // handle json type content

  if (RegExp(r'^(\{|\[)').hasMatch(trimedResStr) &&
      RegExp(r'(\}|\])$').hasMatch(trimedResStr)) {
    return RegExp(r'^\$\.').hasMatch(ruleBean.nextTocUrl ?? "")
        ? Utils.parseFromJsonPath(ruleBean.nextTocUrl, trimedResStr)
            .first
            .value
            .toString()
        : ruleBean.nextTocUrl?.replaceAllMapped(RegExp(r"\{[^\{\}]*\}"),
                (match) {
              var path = match[0]?.substring(1, match[0]!.length - 1) ?? "";
              return Utils.parseFromJsonPath(path, trimedResStr)
                  .first
                  .value
                  .toString();
            }) ??
            "";
  }
}

FutureOr<dynamic> _parseTocUrl(
    String data, BookInfoRuleBean ruleBean, String url) {
  var trimedResStr = data.trim();
  if (trimedResStr.isEmpty) {
    return '';
  }
  // handle json type content

  if (RegExp(r'^(\{|\[)').hasMatch(trimedResStr) &&
      RegExp(r'(\}|\])$').hasMatch(trimedResStr)) {
    developer.log('hello');
    return RegExp(r'^\$\.').hasMatch(ruleBean.tocUrl ?? "")
        ? Utils.parseFromJsonPath(ruleBean.tocUrl, trimedResStr)
            .first
            .value
            .toString()
        : ruleBean.tocUrl?.replaceAllMapped(RegExp(r"\{[^\{\}]*\}"), (match) {
              var path = match[0]?.substring(1, match[0]!.length - 1) ?? "";
              return Utils.parseFromJsonPath(path, trimedResStr)
                  .first
                  .value
                  .toString();
            }) ??
            "";
  }
}
