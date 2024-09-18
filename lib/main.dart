import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:worker_manager/worker_manager.dart';
import 'package:yuedu_hd/db/book_source_helper.dart';
import 'package:yuedu_hd/ui/YDRouter.dart';
import 'package:yuedu_hd/ui/home_page.dart';
import 'package:yuedu_hd/ui/reading/page_reading.dart';
import 'package:yuedu_hd/ui/style/ycolors.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:developer' as developer;


void main() async {
  if (Platform.isWindows || Platform.isLinux) {
    // Initialize FFI
    sqfliteFfiInit();
    // Change the default factory
    databaseFactory = databaseFactoryFfi;
  }
  WidgetsFlutterBinding.ensureInitialized();
  // SystemChrome.setPreferredOrientations([ 	 //强制横屏
  //   DeviceOrientation.landscapeLeft,
  //   DeviceOrientation.landscapeRight
  // ]);
  // SystemChrome.setEnabledSystemUIOverlays([]);
  await Executor().warmUp(log: true);
  loadBookRules();
  runApp(MyApp());
}

var loadRetryCount = 0;

dynamic loadBookRules() async {
  loadRetryCount += 1;
  try {
    var bookRuleUrl = 'https://www.pudaworld.com/ebook/ajax/reader-rules';
    if (!kReleaseMode) {
      bookRuleUrl = 'http://localhost:8083/ajax/reader-rules';
    }
    var req = await Dio(BaseOptions(responseType: ResponseType.plain))
        .get(bookRuleUrl);
    var jsonStr = req.data;

    var helper = BookSourceHelper.getInstance();
    var list = await helper.parseSourceString(jsonStr);
    await helper.updateDataBases(list);
  } catch (e) {
    developer.log(e.toString());
    if (loadRetryCount < 5) {
      Timer(Duration(seconds: 3), () => loadBookRules());
    } else {
    }
  } finally {

  }
}

Widget transitionBuilderInit(ctx, Widget? child) {
  return Row(children: [
    BotToastInit()(ctx, child),
  ],) ;
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scrollBehavior: MyCustomScrollBehavior(),
      builder: BotToastInit(), //1. call BotToastInit
      navigatorObservers: [BotToastNavigatorObserver()],
      navigatorKey: YDRouter.mainRouter,
      title: '扑哒小说',
      theme: ThemeData(
        // This is the theme of your application.
        primaryColor: YColors.primary,
        primaryColorDark: YColors.primary_dark,
        primaryColorLight: YColors.primary_light,
        cardColor: YColors.background_card,
        hintColor: YColors.text_hint,
        scaffoldBackgroundColor: YColors.background,
        canvasColor: YColors.background_input,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity, colorScheme: ColorScheme.fromSwatch()
            .copyWith(secondary: YColors.text_btn_color).copyWith(background: YColors.background),
      ),
      routes: <String, WidgetBuilder>{
        YDRouter.READING_PAGE: (context) => PageReading(),
      },
      home: HomePage(),
    );
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        // etc.
      };
}
