import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spam_blocker/api/firestore_service.dart';
import 'package:spam_blocker/api/local_storage_service.dart';

void foo1(){
  final f = FirestoreService();
  f.fetchNumbers();
}
void foo2(){
  LocalBlockedNumbersStorage.instance.addNumbers("8284811887");
}
void foo3(){
  LocalBlockedNumbersStorage.instance.delNumber("8284811887");
}
void foo4()async {
  Set<String> ms = await LocalBlockedNumbersStorage.instance.getNumbers();
  print("$ms");
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _platform = MethodChannel('com.example.spam_blocker/channel');

  @override
  void initState() {
    super.initState();
    _platform.setMethodCallHandler(_handleNumberFetch);
  }

  Future<dynamic> _handleNumberFetch(MethodCall call) async {
    switch(call.method){
      case "checkNumber":
        final String num = call.arguments['text'] as String;
        print("number checked");
        return LocalBlockedNumbersStorage.instance.numberPresent(num);

      default:
        throw MissingPluginException('Not implemented: ${call.method}');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      // body: const Center(
      //   child: Text(
      //    'Home Screen',
      //    style: TextStyle(fontSize: 24),
      //   ),
      // ),
      body: const Column(
        children: <Widget>[
          TextButton(onPressed: foo1, child: Text("Create")),
          TextButton(onPressed: foo2, child: Text("add")),
          TextButton(onPressed: foo3, child: Text("remove")),
          TextButton(onPressed: foo4, child: Text("read"))
        ],
      ),
    );
  }
}