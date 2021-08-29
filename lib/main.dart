import 'dart:async';

import 'package:flutter/material.dart';

// 使用 window.defaultRouteName 必须导入当前 UI 库
import 'dart:ui';

import 'package:flutter/services.dart';

void main() => runApp(
    /// 该构造方法中传入从 Android 中传递来的参数
    MyApp(initParams: window.defaultRouteName,)
);

class MyApp extends StatelessWidget {
  /// 这是从 Android 中传递来的参数
  final String initParams;
  /// 构造方法 , 获取从 Android 中传递来的参数
  const MyApp({Key? key, required this.initParams}):super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: "初始参数 : $initParams"),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  /// 展示从 Native 获取的消息
  String showMessage = "";

  static const BasicMessageChannel _basicMessageChannel =
    const BasicMessageChannel('BasicMessageChannel', StringCodec());

  static const MethodChannel _methodChannel =
    const MethodChannel('MethodChannel');

  static const EventChannel _eventChannel =
    EventChannel('EventChannel');

  /// 监听 EventChannel 数据的句柄
  late StreamSubscription _streamSubscription;

  /// 当前使用的消息通道是否是 MethodChannel
  bool _isMethodChannel = false;

  @override
  void initState() {
    /// 从 BasicMessageChannel 通道获取消息
    _basicMessageChannel.setMessageHandler((message) => Future<String>((){
      setState(() {
        showMessage = "BasicMessageChannel : $message";
      });
      return "BasicMessageChannel : $message";
    }));

    // 注册 EventChannel 监听
    _streamSubscription = _eventChannel
        .receiveBroadcastStream()
        /// StreamSubscription<T> listen(void onData(T event)?,
        ///   {Function? onError, void onDone()?, bool? cancelOnError});
        .listen(
          /// EventChannel 接收到 Native 信息后 , 回调的方法
          (message) {
            setState(() {
            /// 接收到消息 , 显示在界面中
            showMessage = message;
            });
          },
          onError: (error){
            print(error);
          }
        );
    super.initState();
  }

  @override
  void dispose() {
    // 取消监听
    _streamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        alignment: Alignment.topCenter,
        decoration: BoxDecoration(color: Colors.amber),
        margin: EdgeInsets.only(top: 0),
        child: Column(
          children: [

            SwitchListTile(
                value: _isMethodChannel,
                onChanged: (bool value){
                  _isMethodChannel = value;
                },
                title: Text(
                    _isMethodChannel?"MethodChannel":"BasicMessageChannel",
                ),
            ),

            TextField(
              /// 通过输入框动态变化 , 向 Native 发送消息
              onChanged: (value) async{
                String response;
                if(_isMethodChannel){
                  response = await _methodChannel.invokeMethod("send", value);
                } else {
                  response = await _basicMessageChannel.send(value);
                }
              },
            ),

            Text("Native 传输的消息 : $showMessage"),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
