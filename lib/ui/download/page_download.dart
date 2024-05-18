
import 'package:flutter/material.dart';
import 'package:yuedu_hd/ui/download/BookDownloader.dart';

class PageDownLoad extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(20),
        height: double.maxFinite,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('下载队列',style: Theme.of(context).textTheme.titleMedium,),
            Divider(),
            Container(child: DownloadInfoWidget()),
          ],
        ),
      ),
    );
  }

}

class DownloadInfoWidget extends StatefulWidget{

  const DownloadInfoWidget({Key? key}) : super(key: key);

  @override
  _DownloadInfoWidgetState createState() => _DownloadInfoWidgetState();
}

class _DownloadInfoWidgetState extends State<DownloadInfoWidget> {
  late BookDownloader downloader;
  @override
  void initState() {
    downloader = BookDownloader.getInstance();
    downloader.downLoadCallBack = (){
      setState(() {
        print('download!');
      });
    };
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    if(downloader.chapters.isEmpty){
      return Container(child: Center(child: Text('没有下载任务...',style: Theme.of(context).textTheme.headlineMedium,)));
    }
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isLandscape?16:4),
          child: Row(
            children: [
              Expanded(child: Text('${downloader.bookInfoBean!.name} 待缓存章节: ${downloader.chapters.length}',style: isLandscape?Theme.of(context).textTheme.headlineSmall:null,)),
              IconButton(icon: Icon(Icons.stop), onPressed: (){
                downloader.stop();
              })
            ],
          ),
        ),
        Divider(),
      ],
    );
  }

  @override
  void dispose() {
    downloader.downLoadCallBack = (){};
    super.dispose();
  }
}