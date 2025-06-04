import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class page3 extends StatefulWidget {
  final Map<String,dynamic> tappedLocation;
  final Function(Map<String,dynamic>) selectedLocation;
  const page3({Key?key, required this.selectedLocation, required this.tappedLocation}):super(key:key);
  @override
  State<page3> createState() => _page3State();
}

class _page3State extends State<page3> {
  late Future<List<Widget>> weatherDetails;
  final weatherApiKey = dotenv.env['WEATHER_API_KEY'];
  Map<String,dynamic> curr_weatherInfo = {
    'name': null,
    'longitude': 0.0,
    'latitude': 0.0,
    'temperature': 0.0,
    'icon': null,
  };
  @override
  void initState(){
    super.initState();
    weatherDetails = fetchWeatherInfo();
  }
  void retryAttempt(){
    weatherDetails = fetchWeatherInfo();
  }
  Future<List<Widget>> fetchWeatherInfo() async{
    try{
      List<Widget> weatherForecasts = [];
      final lon = widget.tappedLocation['longitude'];
      final lat = widget.tappedLocation['latitude'];
      final url = Uri.parse('https://api.weatherapi.com/v1/forecast.json?key=$weatherApiKey&q=$lat,$lon&days=7&aqi=yes&alerts=yes',);
      final response = await http.get(url).timeout(Duration(seconds: 10));
      if(response.statusCode == 200){
        final data = jsonDecode(response.body);
        final location = data['location'];
        print("Location: " + location['name']+", "+location['country']);
        final forecastDays = data['forecast']['forecastday'] as List<dynamic>;
        DateTime today = DateTime.now();
        weatherForecasts.add(
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    "Weather Forecast of next 7 days\n${location['name']}, ${location['country']}",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20),)
              )
          ),
        );
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
          final condition = day['condition'];
          final cond_text = condition['text'];
          final cond_icon = condition['icon'];
          final astro = forecastDay['astro'];
          final sunSet = astro['sunset'];
          final sunRise = astro['sunrise'];
          // final moonSet = astro['moonset'];
          // final moonRise = astro['moonrise'];
          DateTime forecastDate = DateTime.parse(date);
          if(todayOnly==forecastDate){
            curr_weatherInfo['name']= "${location['name']}, ${location['country']}";
            curr_weatherInfo['longitude']= lat;
            curr_weatherInfo['latitude']= lon;
            curr_weatherInfo['temperature']= avgTemp;
            curr_weatherInfo['icon']= "${cond_icon}";
          }
          // setState(() {
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
                            Text(todayOnly==forecastDate?"Today":"${date}"),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Text("🌡 ${avgTemp}°C", style: TextStyle(
                                    fontSize: 50
                                ),),
                                Column(
                                  children: [
                                    Image.network("https:${cond_icon}",width: 100,height: 100,fit: BoxFit.contain,),
                                    Container(width:100,child: Text("${cond_text}",textAlign: TextAlign.center,),),
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
        }
      }else{
        print("request failed...try again");
        print( response.statusCode);
      }
      return weatherForecasts;
    }catch(e){
      print("Connection failed: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<List<Widget>>(
         future: weatherDetails,
         builder: (context,snapshot){
           if(snapshot.connectionState==ConnectionState.waiting){
             return Center(child: CircularProgressIndicator(),);
           }else if(snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty){
             return Center(child: widget.tappedLocation['name']==null?Text("Nothing to show",
               style: TextStyle(fontSize: 20),)
           :ElevatedButton(
                 onPressed: (){
                   setState(() {
                     retryAttempt();
                   });
             }, child: Text("Retry")));
           }else{
             widget.selectedLocation(curr_weatherInfo);
             return SingleChildScrollView(
               child: Column(
                 children: snapshot.data!,
             ),
           );
          }
         },
       ),
    );
  }
}

