import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class page2 extends StatefulWidget {
  final Function(Map<String,dynamic>) selectedLocation;
  const page2({Key?key, required this.selectedLocation}): super(key: key);
  @override
  State<page2> createState() => _page2State();
}

class _page2State extends State<page2> {
  Timer? _debouncer;
  String query="";
  List<Map<String,dynamic>> suggestions = [];
  List<Widget> weatherForecasts = [];
  final weatherApiKey = dotenv.env['WEATHER_API_KEY'];
  final locationApiKey = dotenv.env['LOCATION_API_KEY'];
  double lon=0.0,lat=0.0;
  Map<String,dynamic> curr_weatherInfo = {
    'name': null,
    'longitude': 0.0,
    'latitude': 0.0,
    'temperature': 0.0,
    'icon': null,
  };
  final TextEditingController _searchController = TextEditingController();
  bool isLoading=false, hasError=false;

  Future<void> fetchWeather() async{
    try{
      setState(() {
        isLoading=true;
        hasError=false;
      });
      final url = Uri.parse('https://api.weatherapi.com/v1/forecast.json?key=$weatherApiKey&q=$lat,$lon&days=7&aqi=yes&alerts=yes',);
      final response = await http.get(url).timeout(Duration(seconds: 10));
      setState(() {
        weatherForecasts = [];
        print('empty');
      });
      if(response.statusCode == 200){
        final data = jsonDecode(response.body);
        final location = data['location'];

        print("Location: " + location['name']+", "+location['country']);
        final forecastDays = data['forecast']['forecastday'] as List<dynamic>;
        DateTime today = DateTime.now();

        DateTime todayOnly = DateTime(today.year,today.month,today.day);
        for (var forecastDay in forecastDays) {
          print("Date: "+ forecastDay['date']);
          final date = forecastDay['date'];
          final day = forecastDay['day'];
          final maxTemp = day['maxtemp_c'];
          final minTemp = day['mintemp_c'];
          final avgTemp = day['avgtemp_c'];
          final avgHumd = day['avghumidity'];
          final maxWind = day['maxwind_mph'];
          final chanceRain = day['daily_chance_of_rain'];
          final chanceSnow = day['daily_chance_of_snow'];
          // print("Max Temp: ${day['maxtemp_c']}°C" );
          // print("Min Temp: ${day['mintemp_c']}°C" );
          // print("Avg Temp: ${day['avgtemp_c']}°C" );
          // print("Max Wind: ${day['maxwind_mph']}MPH");
          // print("Avg Humadity: ${day['avghumidity']}");
          // print("Chance of Rain: ${day['daily_chance_of_rain']}MPH");
          // print("Chance of Snow: ${day['daily_chance_of_snow']}");
          final condition = day['condition'];
          // print("Text: ${condition['text']}");
          // print("Icon: ${condition['icon']}");
          final cond_text = condition['text'];
          final cond_icon = condition['icon'];
          //print("UV: ${day['uv']}");
          final astro = forecastDay['astro'];
          final sunSet = astro['sunset'];
          final sunRise = astro['sunrise'];
          // final moonSet = astro['moonset'];
          // final moonRise = astro['moonrise'];
          // print("Sunrise: ${astro['sunrise']}");
          // print("Sunset: ${astro['sunset']}");
          // print("Moonrise: ${astro['moonrise']}");
          // print("Moonset: ${astro[',moonset']}");
          DateTime forecastDate = DateTime.parse(date);
          if(todayOnly==forecastDate){
            curr_weatherInfo['name']= "${location['name']}, ${location['country']}";
            curr_weatherInfo['longitude']= lon;
            curr_weatherInfo['latitude']= lat;
            curr_weatherInfo['temperature']= avgTemp;
            curr_weatherInfo['icon']= "${cond_icon}";
          }
          setState(() {
            weatherForecasts.add(
                Card(
                    color: Colors.blue[200],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Text(todayOnly==forecastDate?"Today":"$date"),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Text("🌡 $avgTemp°C", style: TextStyle(
                                      fontSize: 50
                                  ),),
                                  Column(
                                    children: [
                                      Image.network("https:$cond_icon",width: 100,height: 100,fit: BoxFit.contain,),
                                      Container(width:100,child: Text("$cond_text",textAlign: TextAlign.center,),),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 25,),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Text("🌡 Max Temp: ${maxTemp}°C"),
                                  Text("🌡 Min Temp: ${minTemp}°C"),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Text("🌬 Max Wind: ${maxWind} MPH"),
                                  Text("💧 Humidity: ${avgHumd}%"),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Text("☔️ Chance of Rain: ${chanceRain}%"),
                                  Text("❄️ Chance of Snow: ${chanceSnow}%"),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Text("☀️ Sunrise: ${sunRise}"),
                                  Text("🌙 Sunset: ${sunSet}"),
                                ],
                              )
                            ],
                          )),
                    ))
            );
          });
        }
        setState(() {
          isLoading=false;
          hasError=false;
        });
      }else{
        print("request failed...try again");
        print( response.statusCode);
        setState(() {
          isLoading=false;
          hasError=true;
        });
      }
    }catch(e){
      print("Connection failed: $e");
      setState(() {
        isLoading=false;
        hasError=true;
      });
    }
  }

  Future<void> fetchSuggestions(String query) async{
    if(query.isEmpty) {
      setState(() {
        suggestions=[];
      });
      return;
    }
      final url = Uri.parse('https://wft-geo-db.p.rapidapi.com/v1/geo/cities?namePrefix=$query&limit=5');
      final response = await http.get(url,headers:{
        'X-RapidAPI-Key': locationApiKey!,
        'X-RapidAPI-Host': 'wft-geo-db.p.rapidapi.com',
      });
      if(response.statusCode == 200){
        final data = jsonDecode(response.body);
        final cities = data['data'] as List<dynamic>;
        setState(() {
          suggestions=[];
          if (cities.isNotEmpty) {
            suggestions = cities
                .map((city) => {
                  'name': "${city['city']}, ${city['country']}",
                  'longitude': city['longitude'],
                  'latitude': city['latitude'],
            }).toList();
          }
        else {
          suggestions.add({
            'name': 'Not a valid city'
          });
        }
        });
      }else{
        setState(() {
          suggestions=[];
        });
        print("operation failed...");
        print(response.statusCode);
      }
    }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body:
      SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20,),
            SearchBar(
              controller: _searchController,
              hintText: "Search your city...",
              onChanged: (value){
                value = value.split(",")[0];
                setState(() {
                  query=value;
                });
                if(_debouncer?.isActive?? false) _debouncer!.cancel();
                _debouncer = Timer(const Duration(milliseconds: 1000), (){
                  fetchSuggestions(query);
                });

              },
            ),
            const SizedBox(height: 10,),
            if(suggestions.isNotEmpty)
              ...suggestions.map((suggestion)=> ListTile(
                tileColor: Colors.white,
                titleTextStyle: TextStyle(
                  fontSize: 20,
                  color: Colors.black
                ),
                title: Text(suggestion['name']),
                onTap: (){
                  final name = suggestion['name'];
                  lon = suggestion['longitude'];
                  lat = suggestion['latitude'];
                  print("selected: "+ name);
                  widget.selectedLocation(curr_weatherInfo);
                  setState(() {
                    _searchController.text = name;
                    suggestions = [];
                    weatherForecasts = [];
                  });
                  fetchWeather();
                },
              ))
            else
              weatherForecasts.isNotEmpty?
            Column(
                children: weatherForecasts,
              )
            :Container(
                height: MediaQuery.of(context).size.height*0.7,
                  child:
              Center(
                child: isLoading && !hasError?CircularProgressIndicator():(
                    hasError?ElevatedButton(onPressed: fetchWeather, child: Text("Retry"))
                        :null),
              ))
      ])
    ));
    }
  }
