import 'dart:convert';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/page1.dart';
import 'package:weather_app/page2.dart';
import 'package:weather_app/page3.dart';
import 'package:fluttertoast/fluttertoast.dart';


Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  PageController _controller = PageController(
    initialPage: 0
  );
  int _currentPage = 0;
  List<Map<String,dynamic>> weatherInfos = [];
  Map<String,dynamic> weatherInfo = {
    'name':null,
    'longitude': 0.0,
    'latitude': 0.0,
    'temperature': 0.0,
    'icon': null,
  };
  Map<String,dynamic> tappedLocation = {
    'name':null,
    'longitude': 0.0,
    'latitude': 0.0,
  };

  @override
  void initState(){
    super.initState();
    LoadLocalWeatherInfos();
  }

  Future<void> LoadLocalWeatherInfos() async{
    final prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('weatherInfos');
    if(jsonString==null) return;
    List<dynamic> jsonList = jsonDecode(jsonString);
    List<Map<String,dynamic>> jsonInfos = jsonList.map((json)=>
      Map<String,dynamic>.from(json)).toList();
    setState(() {
      weatherInfos = jsonInfos;
    });
  }
  void showToast(String message){
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        fontSize: 16);
  }
  bool weatherInfoExists(){
    return weatherInfo['name']!=null && weatherInfos.any((location)=> location['name']==weatherInfo['name']);
  }
  void updateStoredInfo(){
    for(var info in weatherInfos){
      if(info['name']==weatherInfo['name']){
        setState(() {
          info['temperature']=weatherInfo['temperature'];
          info['icon']=weatherInfo['icon'];
        });
        weatherInfo['name']=null;
        print("updated!");
        break;
      }
    }
    storeLocalWeatherInfos();
  }

  void _pageTransition() async{
    await analytics.logEvent(name: 'page_transition');
    setState((){
      _currentPage=1-_currentPage;
      _controller.animateToPage(_currentPage, duration: Duration(milliseconds: 100), curve: Curves.easeInOut);
      print(_currentPage);
      if(_currentPage==1){

      }else{
        if(weatherInfo['name']==null) return;
        if(weatherInfoExists()) {
          updateStoredInfo();
          showToast("Already added");
          return;
        }
        weatherInfos.add(Map<String,dynamic>.from(weatherInfo));
        storeLocalWeatherInfos();
          showToast("Location added");
          weatherInfo['name']=null;
        }
      }
    );
  }

  void storeLocalWeatherInfos()async{
    final prefs = await SharedPreferences.getInstance();
    String? jsonString = jsonEncode(weatherInfos);
    prefs.setString('weatherInfos', jsonString);
    print('stored in local storage');
  }
  void storeTappedLocation(Map<String,dynamic> location){
    tappedLocation = location;
  }
  void storeLocation(Map<String,dynamic> curr_weatherInfo){
    //setState(() {
      weatherInfo = curr_weatherInfo;
    //});
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black
        )
      ),
      home: SafeArea(child: Scaffold(
        appBar: AppBar(
          leading: Container(),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset("images/appbarLogo.png",
              height: 50,),
              SizedBox(width: 5,),
              Text("Weather-Tap",style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 28,
                color: Colors.blue[200]
              ),),
            ],
          ),
          centerTitle: true,
        ),
        floatingActionButton:
        FloatingActionButton(onPressed: _pageTransition,child: Icon(_currentPage==0? Icons.search:(_currentPage==1?Icons.add:Icons.cloud)),) ,
        body: SafeArea(
            child: PageView(
          controller: _controller,
          onPageChanged: (index){
            setState(() {
              _currentPage=index;
              print(_currentPage);
              if(weatherInfoExists())updateStoredInfo();
            });
          },
          children: [
            page1(storedInfos: weatherInfos, selectedLocation: storeTappedLocation ,controller: _controller),
            page2(selectedLocation: storeLocation),
            page3(selectedLocation: storeLocation,tappedLocation: tappedLocation),
          ],
        ))
      ),
    ));
  }
}

























