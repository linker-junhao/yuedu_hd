
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:yuedu_hd/ui/reading/DisplayConfig.dart';
import 'package:yuedu_hd/ui/reading/PageBreaker.dart';
import 'package:yuedu_hd/ui/reading/TextPage.dart';


//单双页，页眉页脚，左右中间间距
class DisplayPage extends StatelessWidget{
  static const STATUS_LOADING = 11;
  static const STATUS_ERROR = 12;
  static const STATUS_SUCCESS = 13;


  final int status;
  final YDPage text;
  final YDPage text2;
  final int chapterIndex;
  final int currPage;
  final int maxPage;

  DisplayPage(this.status, this.text,{this.text2, this.chapterIndex, this.currPage, this.maxPage}):super(key: ValueKey(text));

  @override
  Widget build(BuildContext context) {

    var config = DisplayConfig.getDefault();
    return Container(
      color: Color(config.backgroundColor),
      child: Stack(
        children: [
          if(status == STATUS_SUCCESS)
            _buildContent(),
          if(status == STATUS_LOADING)
            Container(
              child: Center(//占位内容
                child: Text('加载中'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(){
    var config = DisplayConfig.getDefault();
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.all(config.margin),
          child:TextPage(ydPage: text,),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: Text('$currPage/$maxPage'),
        )

      ],
    );

  }

}