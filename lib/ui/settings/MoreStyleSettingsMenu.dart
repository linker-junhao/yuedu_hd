import 'package:flutter/material.dart';
import 'package:yuedu_hd/db/databaseHelper.dart';
import 'package:yuedu_hd/ui/reading/DisplayConfig.dart';
import 'package:yuedu_hd/ui/widget/ColorPickerDialog.dart';
import 'package:yuedu_hd/ui/widget/NumberPicker.dart';

///阅读样式的更多设置
class MoreStyleSettingsMenu extends StatefulWidget {
  @override
  _MoreStyleSettingsMenuState createState() => _MoreStyleSettingsMenuState();
}

class _MoreStyleSettingsMenuState extends State<MoreStyleSettingsMenu> {
  @override
  Widget build(BuildContext context) {
    var config = DisplayConfig.getDefault();
    var theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leadingAndTrailingTextStyle: TextStyle(fontSize: 18),
          title: Text('页边距 左'),
          subtitle: Text('阅读页面和四周的边距'),
          trailing: Text('${config.marginLeft}dp'),
          onTap: () async {
            int result = await showDialog(
                context: context,
                builder: (_) => NumberPicker.integer(
                    minValue: 0,
                    maxValue: 200,
                    initialValue: config.marginLeft));
            config.marginLeft = result.toDouble();
            _saveConfig();
          },
        ),
        ListTile(
          leadingAndTrailingTextStyle: TextStyle(fontSize: 18),
          title: Text('页边距 右'),
          subtitle: Text('阅读页面和四周的边距'),
          trailing: Text('${config.marginRight}dp'),
          onTap: () async {
            int result = await showDialog(
                context: context,
                builder: (_) => NumberPicker.integer(
                    minValue: 0,
                    maxValue: 200,
                    initialValue: config.marginRight));
            config.marginRight = result.toDouble();
            _saveConfig();
          },
        ),
        ListTile(
          leadingAndTrailingTextStyle: TextStyle(fontSize: 18),
          title: Text('页边距 上'),
          subtitle: Text('阅读页面和四周的边距'),
          trailing: Text('${config.marginTop}dp'),
          onTap: () async {
            int result = await showDialog(
                context: context,
                builder: (_) => NumberPicker.integer(
                    minValue: 0,
                    maxValue: 300,
                    initialValue: config.marginTop));
            config.marginTop = result.toDouble();
            _saveConfig();
          },
        ),
        ListTile(
          leadingAndTrailingTextStyle: TextStyle(fontSize: 18),
          title: Text('页边距 下'),
          subtitle: Text('阅读页面和四周的边距'),
          trailing: Text('${config.marginBottom}dp'),
          onTap: () async {
            int result = await showDialog(
                context: context,
                builder: (_) => NumberPicker.integer(
                    minValue: 0,
                    maxValue: 100,
                    initialValue: config.marginBottom));
            config.marginBottom = result.toDouble();
            _saveConfig();
          },
        ),
        ListTile(
          leadingAndTrailingTextStyle: TextStyle(fontSize: 18),
          title: Text('标题和正文间距'),
          subtitle: Text('标题和正文之间的留白'),
          trailing: Text('${config.titleMargin}dp'),
          onTap: () async {
            int result = await showDialog(
                context: context,
                builder: (_) => NumberPicker.integer(
                    minValue: 0,
                    maxValue: 100,
                    initialValue: config.titleMargin));
            config.titleMargin = result.toDouble();
            _saveConfig();
          },
        ),
        ListTile(
          leadingAndTrailingTextStyle: TextStyle(fontSize: 18),
          title: Text('行间距'),
          subtitle: Text('正文行距，缩放倍数1为基准'),
          trailing: Text('${config.lineSpace}'),
          onTap: () async {
            var result = await showDialog(
                context: context,
                builder: (_) => NumberPicker.decimal(
                    minValue: 0.8,
                    maxValue: 3,
                    initialValue: config.lineSpace));
            if (result != null) {
              config.lineSpace = result;
              _saveConfig();
            }
          },
        ),
        ListTile(
          leadingAndTrailingTextStyle: TextStyle(fontSize: 18),
          title: Text('段落留白'),
          subtitle: Text('段落开头的空格数'),
          trailing: Text('${config.spaceParagraph}'),
          onTap: () async {
            var result = await showDialog(
                context: context,
                builder: (_) => NumberPicker.integer(
                    minValue: 0,
                    maxValue: 10,
                    initialValue: config.spaceParagraph));
            if (result != null) {
              config.spaceParagraph = result;
              _saveConfig();
            }
          },
        ),
        //段落间空行
        SwitchListTile(
          title: Text('段落间距'),
          subtitle: Text('每个段落之间空一行'),
          activeColor: theme.primaryColor,
          value: config.paragraphSpace,
          onChanged: (b) {
            config.paragraphSpace = b;
            _saveConfig();
          },
        ),
        ListTile(
          title: Text('正文颜色'),
          trailing: ColorCircleWidget(Color(config.textColor)),
          onTap: () {
            showDialog<Color>(
                context: context,
                builder: (_) => ColorPickerDialog(
                      initColor: Color(config.textColor),
                    )).then((value) {
              if (value != null) {
                config.textColor = value.value;
                _saveConfig();
              }
            });
          },
        ),
        ListTile(
          leadingAndTrailingTextStyle: TextStyle(fontSize: 18),
          title: Text('标题颜色'),
          trailing: ColorCircleWidget(Color(config.titleColor)),
          onTap: () {
            showDialog<Color>(
                context: context,
                builder: (_) => ColorPickerDialog(
                      initColor: Color(config.titleColor),
                    )).then((value) {
              if (value != null) {
                config.titleColor = value.value;
                _saveConfig();
              }
            });
          },
        ),
        ListTile(
          leadingAndTrailingTextStyle: TextStyle(fontSize: 18),
          title: Text('背景色'),
          trailing: ColorCircleWidget(Color(config.backgroundColor)),
          onTap: () {
            showDialog<Color>(
                context: context,
                builder: (_) => ColorPickerDialog(
                      initColor: Color(config.backgroundColor),
                    )).then((value) {
              if (value != null) {
                config.backgroundColor = value.value;
                _saveConfig();
              }
            });
          },
        ),
        SwitchListTile(
          title: Text('标题加粗'),
          inactiveThumbColor: theme.secondaryHeaderColor,
          activeColor: theme.primaryColor,
          value: config.isTitleBold == 1,
          onChanged: (b) {
            config.isTitleBold = b ? 1 : 0;
            _saveConfig();
          },
        ),
        SwitchListTile(
          title: Text('正文加粗'),
          inactiveThumbColor: theme.secondaryHeaderColor,
          activeColor: theme.primaryColor,
          value: config.isTextBold == 1,
          onChanged: (b) {
            config.isTextBold = b ? 1 : 0;
            _saveConfig();
          },
        ),
        //翻页动画
        SwitchListTile(
          title: Text('翻页动画'),
          inactiveThumbColor: theme.secondaryHeaderColor,
          activeColor: theme.primaryColor,
          value: config.animPage,
          onChanged: (b) {
            config.animPage = b;
            _saveConfig();
          }
        ),
        ListTile(
          leadingAndTrailingTextStyle: TextStyle(fontSize: 18),
          title: Text('自定义字体'),
          subtitle: Text('选择使用内置的字体'),
          trailing: Text('${config.fontPath}'),
          onTap: () async {
            var result = await showDialog(
                context: context,
                builder: (ctx) => SimpleDialog(
                      title: Text("选择字体"),
                      children: _getFontList(config, ctx),
                    ));

            if (result != null) {
              config.fontPath = result;
              _saveConfig();
            }
          },
        ),
        //方向
        ListTile(
          leadingAndTrailingTextStyle: TextStyle(fontSize: 18),
          title: Text('阅读方向'),
          subtitle: Text('自定义阅读界面的方向'),
          trailing: Text(_mapDirection(config.direction)),
          onTap: () async {
            var result = await showDialog(
                context: context,
                builder: (ctx) => SimpleDialog(
                      title: Text("选择方向"),
                      children: _getDirectionList(config, ctx),
                    ));

            if (result != null) {
              config.direction = result;
              _saveConfig();
            }
          },
        ),
      ],
    );
  }

  List<Widget> _getFontList(DisplayConfig config, BuildContext ctx) {
    var f = config.fontPath;
    var fonts = [
      {"name": "默认字体", "font": ""},
      {"name": "鸿蒙HarmonyOS", "font": "HarmonyOS_Sans"},
      {"name": "方正仿宋简体", "font": "fz_song"},
      {"name": "方正楷体简体", "font": "fz_kai"},
      {"name": "汉字拼音体", "font": "Hanzi-Pinyin"},
      {"name": "站酷快乐体", "font": "zcool_happy"},
      {"name": "清松手写体", "font": "handwrite"},
    ];
    List<Widget> items = [];
    for (var value in fonts) {
      items.add(Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: GestureDetector(
          onTap: () {
            Navigator.of(ctx).pop(value["font"]);
          },
          child: Row(
            children: [
              Expanded(
                  child: Text(
                value["name"]!,
                style: TextStyle(fontSize: 20, fontFamily: value["font"]),
              )),
              if (value["font"] == f) Icon(Icons.done)
            ],
          ),
        ),
      ));
    }
    return items;
  }

  List<Widget> _getDirectionList(DisplayConfig config, BuildContext ctx) {
    var f = config.direction;
    var fonts = [
      {"name": "跟随系统", "value": "0"},
      {"name": "竖直", "value": "1"},
      {"name": "横屏", "value": "2"},
    ];
    List<Widget> items = [];
    for (var value in fonts) {
      items.add(Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: GestureDetector(
          onTap: () {
            Navigator.of(ctx).pop(int.parse(value["value"]!));
          },
          child: Row(
            children: [
              Expanded(
                  child: Text(value["name"]!, style: TextStyle(fontSize: 20))),
              if (value["value"] == (f.toString())) Icon(Icons.done),
            ],
          ),
        ),
      ));
    }
    return items;
  }

  String _mapDirection(int v) {
    return ["跟随系统", "竖直", "横屏"][v];
  }

  void _saveConfig() {
    var config = DisplayConfig.getDefault();
    DatabaseHelper().saveConfig(config);
    setState(() {});
  }
}

class ColorCircleWidget extends StatelessWidget {
  final Color color;

  const ColorCircleWidget(this.color, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(),
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    );
  }
}
