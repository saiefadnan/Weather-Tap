import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class page1 extends StatefulWidget {
  final List<Map<String,dynamic>> storedInfos;
  final Function(Map<String,dynamic>) selectedLocation;
  final PageController controller;
  const page1({Key? key, required this.storedInfos, required this.selectedLocation,required this.controller}):super(key:key);
  @override
  State<page1> createState() => _page1State();
}

class _page1State extends State<page1> {
  final weatherApiKey = dotenv.env['WEATHER_API_KEY'];
  Map<String,dynamic> tappedLocation = {
    'name':null,
    'longitude': 0.0,
    'latitude': 0.0,
  };
  Timer? pollingTimer;
  bool isPolling = false;

  Future<void> updateWeatherInfo(Map<String,dynamic> info) async{
    print("fetching weather...1");
    print("fetching weather...2");
    print("fetching weather...3");
    print("fetching weather...4");
    print("fetching weather...5");
    try{
      final lon = info['longitude'];
      final lat = info['latitude'];
      final url = Uri.parse('https://api.weatherapi.com/v1/forecast.json?key=$weatherApiKey&q=$lat,$lon&days=1&aqi=yes&alerts=yes',);
      final response = await http.get(url).timeout(Duration(minutes: 10));
      if(response.statusCode == 200){
        final data = jsonDecode(response.body);
        //final location = data['location'];
        // print("Location: " + location['name']+", "+location['country']);
        final forecastDay = data['forecast']['forecastday'][0];
          final day = forecastDay['day'];
          final condition = day['condition'];
          setState(() {
            info['temperature'] = day['avgtemp_c'];
            info['icon'] = condition['icon'];
          });
          print(day['avgtemp_c']);
          print(condition['text']);
          print(condition['icon']);
      }else{
        print("request failed...trying again after 10 minutes...");
        print( response.statusCode);
      }
    }catch(e){
      print("Connection failed: $e");
    }
  }

  void startLoop() async{
    for(var info in widget.storedInfos){
      await updateWeatherInfo(info);
      print('initing weather info');
    }
  }

  @override
  void initState(){
    print("initing page...");
    super.initState();
    widget.controller.addListener(restartTimer);
    startLoop();
    startPolling();
  }
  void restartTimer(){
    if(widget.controller.page?.round()==0){
      startPolling();
    }
  }
  @override
  void dispose(){
    super.dispose();
    print("disposing timer& listener...1");
    pollingTimer?.cancel();
    isPolling = false;
    widget.controller.removeListener(restartTimer);
  }
  void startPolling(){
      if(isPolling) return;
      print("Restarting timer...");
      isPolling = true;
      pollingTimer?.cancel();
      pollingTimer = Timer.periodic(Duration(minutes: 10), (timer) {
        startLoop();
      });
  }


  void onLongPress(Map<String,dynamic> info){
    showDialog(context: context, builder: (BuildContext context){
      return AlertDialog(
        title: Text("Confirm"),
        content: Text("Are you sure want to delete this record?"),
        actions: [
          TextButton(onPressed:()async{
            setState((){
              widget.storedInfos.remove(info);
            });
            final prefs = await SharedPreferences.getInstance();
            String? jsonString = jsonEncode(widget.storedInfos);
            prefs.setString('weatherInfos', jsonString);
            Navigator.of(context).pop();
          }, child: Text("Delete")),
          TextButton(onPressed:(){
            Navigator.of(context).pop();
          }, child: Text("Cancel")
          )
        ],
      );
    });
  }

  Future<void> refreshInfos() async{
    startLoop();
  }

  Widget build(BuildContext context) {
    return RefreshIndicator(
      child: Scaffold(
      backgroundColor: Colors.white,
      body:
        SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
        child: Column(
            children:
            widget.storedInfos.isNotEmpty?
            [SizedBox(height: 10,),
        ...widget.storedInfos.map((info)=>
                GestureDetector(
                onLongPress: ()=>onLongPress(info),
                child: InkWell(
                onTap: (){
                  tappedLocation['name'] = info['name'];
                  tappedLocation['longitude'] = info['longitude'];
                  tappedLocation['latitude'] = info['latitude'];
                  widget.selectedLocation(tappedLocation);
                  widget.controller.jumpToPage(2);
                },
                child: Card(
                  color: Colors.blue[200],
                  child: Column(
                    children: [
                      Text(info['name']),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text("🌡${info['temperature']}°C",style: TextStyle(
                            fontSize: 40
                          ),),
                          Image.network("https:${info['icon']}",width: 80,height: 80,fit: BoxFit.contain,),
                        ],
                      )
                    ],
                  ),
                )
              ))).toList()]
            :[Container(
                height: MediaQuery.of(context).size.height*.8,
                child:Center(
                    child:Text("No locations are added",
                style: TextStyle(
                  fontSize: 20
                ),)
            ))],
        ),
      ),),onRefresh: refreshInfos,);
  }
}
