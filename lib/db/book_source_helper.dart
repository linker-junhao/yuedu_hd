

import 'dart:collection';
import 'dart:convert';

import 'package:yuedu_hd/db/BookSourceBean.dart';
import 'package:yuedu_hd/db/databaseHelper.dart';

class BookSourceHelper{
  static BookSourceHelper? _instance;
  static BookSourceHelper getInstance(){
    if(_instance == null){
      _instance = BookSourceHelper._init();
    }
    return _instance!;
  }

  BookSourceHelper._init(){
    //
  }

  StringBuffer _log = StringBuffer();

  ///过滤不兼容的书源
  bool _checkCompatible(Map item){

    var itemStr = item.toString();
    if(itemStr.contains('@get:')){
      return false;
    }
    if(itemStr.contains('@js')){
      return false;
    }
    if(itemStr.contains('<js>')){
      return false;
    }
    if(itemStr.contains('java.ajax')){
      return false;
    }
    if(itemStr.contains('Jsoup.connect')){
      return false;
    }
    if(item['bookSourceType'] !=null && item['bookSourceType'].toString() != "0"){//只兼容文字源
      return false;
    }
    item['bookSourceType'] = int.tryParse(item['bookSourceType'].toString());
    return true;
  }

  Future<List<BookSourceBean>> parseSourceString(String jsonStr) async{
    _log.clear();
    _log.write('---解析---\n');
    List<BookSourceBean> result = [];
    var sourceList;
    try{
      jsonStr = jsonStr.replaceAll(r",{webView:“true”}'", '');
      jsonStr = jsonStr.replaceAll(r',{\"webView\":true}', '');
      sourceList = jsonDecode(jsonStr);
    }catch(e){
      _log.writeln('json解析异常:$e');
      return Future.value(result);
    }
    if(jsonStr.startsWith('{')){//single item
      var item = sourceList;
      if(!_checkCompatible(sourceList)){
        _log.writeln('[x不兼容过滤]->${item['bookSourceUrl']}');
        return Future.value(result);
      }
      result.add(BookSourceBean.fromJson(item));
      _log.writeln('[兼容]->【${item['bookSourceName']} 】${item['bookSourceUrl']}');
    }else{
      for(var item in sourceList){
        if(!_checkCompatible(item)){
          _log.writeln('[x不兼容过滤]->${item['bookSourceUrl']}');
          continue;
        }
        result.add(BookSourceBean.fromJson(item));
        _log.writeln('[兼容]->【${item['bookSourceName']} 】${item['bookSourceUrl']}');
      }
    }

    _log.writeln('---解析结束---');
    return Future.value(result);
  }


  Future<int> updateDataBases(List<BookSourceBean> beanList) async{
    _log.writeln("准备更新数据库:数量${beanList.length}");
    var result = 0;
    await DatabaseHelper().withDB().then((value) => value.transaction((txn) async{
      for(var i in beanList){
        try{
          await DatabaseHelper().insertOrUpdateBookSource(i,txn);
          result += 1;
          _log.writeln("更新数据:${i.bookSourceUrl}");
        }catch(e){
          _log.writeln(e.toString());
          break;
        }
      }
    }));
    _log.writeln("更新数据库结束:更新数量$result");
    return Future.value(result);
  }


  String getLog(){
    return _log.toString();
  }

}