
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yuedu_hd/db/book_source_helper.dart';
import 'package:yuedu_hd/ui/widget/space.dart';
import 'dart:developer' as developer;

class PageSourceAdd extends StatefulWidget{
  @override
  _PageSourceAddState createState() => _PageSourceAddState();
}

class _PageSourceAddState extends State<PageSourceAdd> {
  bool showLoading = false;
  String _log='';
  late TextEditingController _textEditingController;
  var isLandscape = false;


  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
    if(!kReleaseMode){
      _textEditingController.text = 'http://dev.linker.lkr:8083/ajax/reader-rules';
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        child: Container(
          padding: EdgeInsets.all(isLandscape?20:4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(icon: Icon(CupertinoIcons.back,color: theme.primaryColor,),padding: EdgeInsets.all(0), onPressed: (){
                    Navigator.of(context).pop();
                  }),
                  Expanded(child: _buildSearch(theme),),
                  HSpace(8),
                  GestureDetector(onTap: (){
                    _showHelpDialog(context);
                  },child: Container(margin: EdgeInsets.all(4),child: Icon(Icons.help_outline),),),
                  if(isLandscape)
                    _buildBtnLayout(theme,context),

                ],
              ),
              if(!isLandscape)
                Center(child: _buildBtnLayout(theme,context)),
              Expanded(
                child: CupertinoScrollbar(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Text('''
书源的导入：
方式一：在上方输入书源链接，点击按钮开始导入。
方式二：复制配置文件内容到粘贴板，点击【粘贴板导入】按钮。
暂不支持编辑和修改，同网址书源每次导入均覆盖内容。
规则参考:https://alanskycn.gitee.io/teachme
推荐微信小程序[PUPU文学]获取书源
                          ''',style: isLandscape?theme.textTheme.headline6:theme.textTheme.subtitle2,),
                        ),
                        VSpace(10),
                        Text('调试日志:',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 12),),
                        VSpace(10),
                        Text(_log),

                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBtnLayout(ThemeData theme,context){
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(onPressed: (){
          if(_textEditingController.text.trim().isEmpty){
            _showHelpDialog(context);
          }else{
            _fromNetWork();
          }
        },
          child: Text('导入',style: TextStyle(color: theme.colorScheme.secondary),),
          style: ButtonStyle(shape: MaterialStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0))), backgroundColor: MaterialStatePropertyAll(theme.primaryColorDark)),
        ),
        HSpace(8),
        TextButton(onPressed: (){
          _fromClipboard();
        },
          child: Text('粘贴板导入',style: TextStyle(color: theme.colorScheme.secondary),),
          style: ButtonStyle(
            shape: MaterialStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),),
            backgroundColor: MaterialStatePropertyAll(theme.primaryColorDark))
        ),
      ],
    );
  }

  Container _buildSearch(ThemeData theme) {
    return Container(
      height: 40,
      padding: EdgeInsets.only(left: 8,right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(5)),
        color: theme.canvasColor,
      ),
      child: TextField(
        controller: _textEditingController,
        maxLines: 1,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.all(0),
          hintText: '输入网址，从网络导入',
          prefixIconConstraints: BoxConstraints(minWidth: 30, maxHeight: 30),
          prefixIcon: Icon(Icons.link_outlined,color: theme.hintColor,size: 24,),
          suffixIcon: showLoading?CupertinoActivityIndicator():null,
          border: InputBorder.none,
        ),
      ),
    );
  }

  void _showHelpDialog(context) async{
     var result= await showDialog(context: context,builder: (context){
      return AlertDialog(
        title: Text('书源帮助'),
        content: Text('''
本APP不提供内容，只提供浏览服务，按照用户自定义的规则加载特定网站的网页。
使用[阅读3.0]书源规则,不完全兼容[阅读2.0]规则
仅支持JSOUP格式和CSS格式的书源，导入自动过滤
参考:https://alanskycn.gitee.io/teachme/
你可以从搜索引擎，gitee,github，酷安等社区获取别人分享的书源。
推荐微信小程序[PUPU文学小仓库]获取书源。
新手上路？点击使用热门书源,导入开始搜索!
'''),
        actions: [
          TextButton(onPressed: (){
            Navigator.of(context).pop('use');
          }, child: Text('使用推荐书源')),
          TextButton(onPressed: (){
            Navigator.of(context).pop('done');
          }, child: Text('关闭')),
        ],
      );
    });
     if(result!=null){
       if(result == "use"){
         _textEditingController.text = 'https://yuedu-hd.netlify.app/sy.json';
       }
       setState(() {

       });
     }
  }


  dynamic _fromClipboard() async{
    _log = '';
    setState(() {
      showLoading = true;
    });
    try{
      var jsonStr = await Clipboard.getData(Clipboard.kTextPlain);
      if(jsonStr!.text!.startsWith('http')){
        _textEditingController.text = jsonStr.text!;
        await _fromNetWork();
      }else{
        await _parserData(jsonStr.text!);
      }
    }catch(e){
      _log += '剪切板解析异常->\n$e\n';
    }finally{
      setState(() {
        showLoading = false;
      });
    }

  }

  dynamic _fromNetWork() async{
    _log = '';
    setState(() {
      showLoading = true;
    });
    try{
      var req = await Dio(BaseOptions(responseType: ResponseType.plain)).get(_textEditingController.text.trim());
      var jsonStr = req.data;
      setState(() {
        _log += '网络请求成功->${_textEditingController.text}\n';
      });
      await _parserData(jsonStr);
    }catch(e){
      _log += '网络请求异常->${_textEditingController.text}\n$e\n';
    }finally{
      setState(() {
        showLoading = false;
      });
    }

  }


  dynamic _parserData(String json) async{
    var helper = BookSourceHelper.getInstance();
    var list = await helper.parseSourceString(json);
    await helper.updateDataBases(list);
    developer.log(helper.getLog());
    _log += helper.getLog();
    setState(() {

    });
  }

}