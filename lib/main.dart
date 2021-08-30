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

    /// 这里延迟 6 秒在注册该事件
    ///   一定要先在 Android 中设置好 EventChannel
    ///   然后 , 才能在 Flutter 中设置监听
    ///   否则 , 无法成功
    Future.delayed(const Duration(milliseconds: 6000), () {
      // Here you can write your code

      // 注册 EventChannel 监听
      _streamSubscription = _eventChannel
          .receiveBroadcastStream()
      /// StreamSubscription<T> listen(void onData(T event)?,
      ///   {Function? onError, void onDone()?, bool? cancelOnError});
          .listen(
        /// EventChannel 接收到 Native 信息后 , 回调的方法
            (message) {
              print("Flutter _eventChannel listen 回调");
              setState(() {
                /// 接收到消息 , 显示在界面中
                showMessage = message;
              });
          },
          onError: (error){
            print("Flutter _eventChannel listen 出错");
            print(error);
          }
      );

      setState(() {
      });

    });

    // Future<dynamic> Function(MethodCall call)? handler
    _methodChannel.setMethodCallHandler((call) {
      var method = call.method;
      var arguments = call.arguments;
      setState(() {
        showMessage = "Android 端通过 MethodChannel 调用 Flutter 端 $method 方法, 参数为 $arguments";
      });
      return Future.value();
    });


    /*// 注册 EventChannel 监听
    _streamSubscription = _eventChannel
        .receiveBroadcastStream()
        /// StreamSubscription<T> listen(void onData(T event)?,
        ///   {Function? onError, void onDone()?, bool? cancelOnError});
        .listen(
          /// EventChannel 接收到 Native 信息后 , 回调的方法
          (message) {
            print("Flutter _eventChannel listen 回调");
            setState(() {
              /// 接收到消息 , 显示在界面中
              showMessage = message;
            });
          },
          onError: (error){
            print("Flutter _eventChannel listen 出错");
            print(error);
          }
        );*/

    print("Flutter _eventChannel 注册完毕");

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

            ElevatedButton(
            onPressed: (){
              _basicMessageChannel.send("Dart 端通过 BasicMessageChannel 向 Android 端发送消息 Hello !");
            },
              child: Text("BasicMessageChannel 向 Android 发送消息"),
            ),

            ElevatedButton(
              onPressed: (){
                _methodChannel.invokeMethod("method", "arguments");
              },
              child: Text("MethodChannel 调用 Android 方法"),
            ),

            Container(
              color: Colors.black,
              child: Text(
                "Native 传输的消息 : $showMessage",
                style: TextStyle(color: Colors.green),),
            ),

          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
