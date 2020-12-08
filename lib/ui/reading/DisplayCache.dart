

import 'package:yuedu_hd/ui/reading/DisplayPage.dart';

///缓存清除的时候，按章节来清除,每次清除都要保证清空了一个章节
class DisplayCache{
  static DisplayCache _instance;
  static const MAX_CACHE_SIZE = 200;
  DisplayCache._init(){
    //
  }
  static DisplayCache getInstance(){
    if(_instance == null){
      _instance = DisplayCache._init();
    }
    return _instance;
  }

  //-----------------限制容量的缓存-----------
  var _cache = Map<int,DisplayPage>();


  /// maybe null
  DisplayPage get(int index){
    return _cache[index];
  }

  ///limit max cache size
  void put(int index,DisplayPage page){
    _cache[index] = page;
  }

  void clear(){
    _cache.clear();
  }

}