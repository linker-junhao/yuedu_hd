import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:reader_parser2/h_parser/h_parser.dart';
import 'package:worker_manager/worker_manager.dart';
import 'package:yuedu_hd/db/BookInfoBean.dart';
import 'package:yuedu_hd/db/BookSourceBean.dart';
import 'package:yuedu_hd/db/databaseHelper.dart';
import 'package:yuedu_hd/db/utils.dart';

typedef void OnBookListLoad(BookInfoBean data);
typedef void UpdateList(); //批量更新列表，怕太卡了

class ExploreHelper {
  static ExploreHelper? _instance;
  static ExploreHelper getInstance() {
    if (_instance == null) {
      _instance = ExploreHelper._init();
    }
    return _instance!;
  }

  late Dio dio;
  ExploreHelper._init() {
    dio = Utils.createDioClient();
  }
  Future<List<BookSourceBean>> getExplorableSource() async {
    var bookSources = await DatabaseHelper().queryAllBookSourceEnabled();
    return bookSources;
  }

  Future<dynamic> requestExploreSection(
      BookExploreUrlBean options,
      OnBookListLoad? onBookListLoad,
      UpdateList? updateList,
      BookSourceBean sourceBean) async {
    options.url = Utils.checkLink(sourceBean.bookSourceUrl, options.url);
    var headers = Utils.buildHeaders(
        options.url!, ContentType.html.toString(), options.headers);
    Options requestOptions = Options(
        method: options.method,
        headers: headers,
        sendTimeout: 5000,
        receiveTimeout: 5000,
        followRedirects: true);
    if (options.charset == 'gbk') {
      options.url = UrlGBKEncode().encode(options.url);
      options.body = UrlGBKEncode().encode(options.body);
    }
    requestOptions.responseDecoder = Utils.gbkDecoder;
    try {
      dio.options.connectTimeout = 10000;
      print('探索书籍:$options,$headers');
      var response = await dio
          .request(options.url!, options: requestOptions, data: options.body)
          .timeout(Duration(seconds: 8));
      if (response.statusCode == 200) {
        print('请求成功[${options.url}]');
        await _parseResponse(response.data, sourceBean, onBookListLoad);
        if (updateList != null) {
          updateList(); //更新列表UI
        }
      } else {
        print('错误:书源错误${response.statusCode}');
      }
    } catch (e) {
      //POST导致的302重新处理
      if (e is DioError) {
        var rsp = (e).response;
        if (rsp?.statusCode == 302) {
          var location = rsp?.headers["location"];
          var linkRegexp = RegExp(r'http:.*\/');
          var sep = linkRegexp.stringMatch(options.url!);
          var nUrl = Utils.checkLink(sep ?? "", location?[0]);
          print("302 error 重构请求->$nUrl");
          options.url = nUrl;
          options.method = "GET";
          options.body = "";
          return requestExploreSection(
              options, onBookListLoad, updateList, sourceBean);
        }
      }
      print('搜索错误[${options.url}]:$e');
    }

    return Future.value(0);
  }

  dynamic _parseResponse(String response, BookSourceBean sourceBean,
      OnBookListLoad? onBookListLoad) async {
    var source = sourceBean;
    var sourceId = sourceBean.id;
    var tempTime = DateTime.now();
    print('解析探索页内容：$sourceId|$tempTime');
    var ruleBean = source.mapExploreRuleBean();
    try {
      //填充需要传输的数据
      var kv = {
        'response': response,
        'rule_bookList': ruleBean.bookList,
        'rule_name': ruleBean.name,
        'rule_author': ruleBean.author,
        'rule_kind': ruleBean.kind,
        'rule_intro': ruleBean.intro,
        'rule_lastChapter': ruleBean.lastChapter,
        'rule_wordCount': ruleBean.wordCount,
        'rule_bookUrl': ruleBean.bookUrl,
        'rule_tocUrl': ruleBean.tocUrl,
        'rule_coverUrl': ruleBean.coverUrl,
      };
      print(
          '解析返回内容开始：$sourceId|${DateTime.now().difference(tempTime).inMilliseconds}');
      //用线程池执行解析，大概需要400ms
      var tmp = await Executor().execute(arg1: kv, fun1: _parse);
      print(
          '解析返回内容结束：$sourceId|${DateTime.now().difference(tempTime).inMilliseconds}');
      List<BookInfoBean> bookInfoList = [];
      for (var t in tmp) {
        bookInfoList.add(BookInfoBean.fromMap(t));
      }
      print(
          '解析探索返回内容完成：$sourceId|${DateTime.now().difference(tempTime).inMilliseconds}');
      for (var bookInfo in bookInfoList) {
        //链接修正
        bookInfo.bookUrl =
            Utils.checkLink(sourceBean.bookSourceUrl, bookInfo.bookUrl);
        bookInfo.coverUrl =
            Utils.checkLink(sourceBean.bookSourceUrl, bookInfo.coverUrl);
        //-------关联到书源-------------
        bookInfo.source_id = source.id;
        bookInfo.sourceBean = source;
        if (bookInfo.name == null || bookInfo.author == null) {
          continue;
        }
        if (bookInfo.bookUrl == null || bookInfo.bookUrl!.isEmpty) {
          continue;
        }
        bookInfo.name = bookInfo.name!.trim();
        bookInfo.author = bookInfo.author!.trim();
        var bookId = await DatabaseHelper().insertBookToDB(bookInfo);
        bookInfo.id = bookId;
        onBookListLoad!(bookInfo);
      }
    } catch (e) {
      print('解析错误[${source.bookSourceName},${source.bookSourceUrl}]:$e');
    }
    return Future.value(0);
  }
}

FutureOr<dynamic> _parse(
    Map<String, String?> map, TypeSendPort<dynamic> sendPort) {
  String response = map['response']!;
  BookExploreRuleBean ruleBean = BookExploreRuleBean();
  ruleBean.bookList = map['rule_bookList'];
  ruleBean.name = map['rule_name'];
  ruleBean.author = map['rule_author'];
  ruleBean.kind = map['rule_kind'];
  ruleBean.intro = map['rule_intro'];
  ruleBean.lastChapter = map['rule_lastChapter'];
  ruleBean.wordCount = map['rule_wordCount'];
  ruleBean.bookUrl = map['rule_bookUrl'];
  ruleBean.tocUrl = map['rule_tocUrl'];
  ruleBean.coverUrl = map['rule_coverUrl'];

  print("搜索解析规则->[$ruleBean]");

  List<BookInfoBean> result = [];

  var trimedRes = response.trim();
  if (RegExp(r'^(\{|\[)').hasMatch(trimedRes) &&
      RegExp(r'(\}|\])$').hasMatch(trimedRes)) {
    var bookList = Utils.parseFromJsonPath(ruleBean.bookList, trimedRes);
    bookList.forEach((book) {
      if (book.value == null) {
        return;
      }
      var bookInfo = BookInfoBean();
      bookInfo.name = Utils.parseObjByJsonPath(ruleBean.name, book.value!)
          .first
          .value
          .toString();
      bookInfo.author = Utils.parseObjByJsonPath(ruleBean.author, book.value!)
          .first
          .value
          .toString();
      var kinds = Utils.parseObjByJsonPath(ruleBean.kind, book.value!).map((m) {
        return m.value;
      }).join('\n');
      bookInfo.kind = kinds.replaceAll('\n', '|');
      bookInfo.intro = Utils.parseObjByJsonPath(ruleBean.intro!, book.value!)
          .first
          .value
          .toString();
      bookInfo.lastChapter =
          Utils.parseObjByJsonPath(ruleBean.lastChapter, book.value!)
              .first
              .value
              .toString();
      bookInfo.wordCount =
          Utils.parseObjByJsonPath(ruleBean.wordCount, book.value!)
              .first
              .value
              .toString();
      bookInfo.bookUrl = RegExp(r'^\$\.').hasMatch(ruleBean.bookUrl ?? "")
          ? Utils.parseObjByJsonPath(ruleBean.bookUrl, book.value!)
              .first
              .value
              .toString()
          : ruleBean.bookUrl?.replaceAllMapped(RegExp(r"\{[^\{\}]*\}"),
                  (match) {
                var path = match[0]?.substring(1, match[0]!.length - 1) ?? "";
                return Utils.parseObjByJsonPath(path, book.value!)
                    .first
                    .value
                    .toString();
              }) ??
              "";
      if (bookInfo.bookUrl == '') {
        bookInfo.bookUrl = RegExp(r'^\$\.').hasMatch(ruleBean.tocUrl ?? "")
            ? Utils.parseObjByJsonPath(ruleBean.tocUrl, book.value!)
                .first
                .value
                .toString()
            : ruleBean.tocUrl?.replaceAllMapped(RegExp(r"\{[^\{\}]*\}"),
                    (match) {
                  var path = match[0]?.substring(1, match[0]!.length - 1) ?? "";
                  return Utils.parseObjByJsonPath(path, book.value!)
                      .first
                      .value
                      .toString();
                }) ??
                "";
      }
      var coverUrl = RegExp(r'^\$\.').hasMatch(ruleBean.coverUrl ?? "")
          ? Utils.parseObjByJsonPath(ruleBean.coverUrl, book.value!)
              .first
              .value
              .toString()
          : ruleBean.coverUrl?.replaceAllMapped(RegExp(r"\{[^\{\}]*\}"),
                  (match) {
                var path = match[0]?.substring(1, match[0]!.length - 1) ?? "";
                return Utils.parseObjByJsonPath(path, book.value!)
                    .first
                    .value
                    .toString();
              }) ??
              "";
      bookInfo.coverUrl = coverUrl;
      if (bookInfo.name == null ||
          bookInfo.author == null ||
          bookInfo.bookUrl == null) {
        return;
      }
      bookInfo.name = bookInfo.name!.trim();
      bookInfo.author = bookInfo.author!.trim();
      if (bookInfo.name!.isEmpty ||
          bookInfo.author!.isEmpty ||
          bookInfo.bookUrl!.isEmpty) {
        return;
      }
      result.add(bookInfo);
    });
  } else {
    try {
      var hparser = HParser(response);

      var bId = hparser.parseRuleRaw(ruleBean.bookList!);
      var batchSize = hparser.queryBatchSize(bId);
      for (var i = 0; i < batchSize; i++) {
        var bookInfo = BookInfoBean();

        bookInfo.name = hparser.parseRuleStringForParent(bId, ruleBean.name, i);
        bookInfo.author =
            hparser.parseRuleStringForParent(bId, ruleBean.author, i);
        var kinds = hparser.parseRuleStringForParent(bId, ruleBean.kind, i);
        bookInfo.kind = kinds == null ? '' : kinds.replaceAll('\n', '|');
        bookInfo.intro =
            hparser.parseRuleStringForParent(bId, ruleBean.intro, i);
        bookInfo.lastChapter =
            hparser.parseRuleStringForParent(bId, ruleBean.lastChapter, i);
        bookInfo.wordCount =
            hparser.parseRuleStringForParent(bId, ruleBean.wordCount, i);
        var url = hparser.parseRuleStringsForParent(bId, ruleBean.bookUrl, i);
        bookInfo.bookUrl = url.isNotEmpty ? url[0] : null;
        if (bookInfo.bookUrl == null) {
          bookInfo.bookUrl =
              hparser.parseRuleStringForParent(bId, ruleBean.tocUrl, i);
        }
        var coverUrl =
            hparser.parseRuleStringsForParent(bId, ruleBean.coverUrl, i);
        bookInfo.coverUrl = coverUrl.isNotEmpty ? coverUrl[0] : null;
        if (bookInfo.name == null ||
            bookInfo.author == null ||
            bookInfo.bookUrl == null) {
          continue;
        }
        bookInfo.name = bookInfo.name!.trim();
        bookInfo.author = bookInfo.author!.trim();
        if (bookInfo.name!.isEmpty ||
            bookInfo.author!.isEmpty ||
            bookInfo.bookUrl!.isEmpty) {
          continue;
        }
        result.add(bookInfo);
      }

      hparser.destoryBatch(bId);
      hparser.destory();
    } catch (e) {
      print('搜索解析错误:$e');
    }
  }

  // jsCore.destroy();
  // objectCache.destroy();
  List<Map<String, dynamic>> temp = [];
  for (var value in result) {
    temp.add(value.toMap());
  }
  return temp;
}
