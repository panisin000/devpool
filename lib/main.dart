/*
 * Copyright Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weather/weather.dart';
import 'package:intl/intl.dart';
import 'package:weather_icons/weather_icons.dart';
import 'package:weather_animation/weather_animation.dart';
// import 'package:weather_icons/weather_icons.dart';

enum AppState { NOT_DOWNLOADED, DOWNLOADING, FINISHED_DOWNLOADING }

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String key = 'aae2f1ab8a154309dad79c79d48066a4';
  late WeatherFactory ws;
  late Weather weather;
  List<Weather> _data = [];
  AppState _state = AppState.NOT_DOWNLOADED;
  double lat = 13.8527709;
  double lon = 99.5592319;
  String place = 'จตุจักร';
  // String txtError = "";
  TextEditingController inputControllerPlace = TextEditingController();
  var outputDate;
  var inputFormat = DateFormat('dd/MM/yyyy HH:mm');
  final newFormatter = DateFormat("dd MMM yyyy HH:mm");
  bool loaded = false;

  String weatherCode = "";

  @override
  void initState() {
    super.initState();
    init();
    // inputControllerPlace.text = place;
  }

  init() async {
    ws = WeatherFactory(key, language: Language.THAI);
    var _pos = await _determinePosition();
    weather = await ws.currentWeatherByLocation(_pos.latitude, _pos.longitude);
    var inputDate = inputFormat.parse(
        '${weather.date!.day}/${weather.date!.month}/${weather.date!.year} ${weather.date!.hour}:${weather.date!.month}');
    print("inputDate=>$inputDate");
    setState(() {
      _data = [weather];
      loaded = true;
      outputDate = newFormatter.format(inputDate);
      _state = AppState.FINISHED_DOWNLOADING;
    });
  }

  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  void queryForecast() async {
    /// Removes keyboard
    FocusScope.of(context).requestFocus(FocusNode());
    setState(() {
      _state = AppState.DOWNLOADING;
    });

    List<Weather> forecasts = await ws.fiveDayForecastByLocation(lat, lon);
    setState(() {
      _data = forecasts;
      _state = AppState.FINISHED_DOWNLOADING;
    });
  }

  void queryWeather([bool local = false]) async {
    /// Removes keyboard
    FocusScope.of(context).requestFocus(FocusNode());

    setState(() {
      _state = AppState.DOWNLOADING;
    });
    if (local) {
      Position position = await _determinePosition();
      setState(() {
        lat = position.latitude;
        lon = position.longitude;
      });
      weather = await ws.currentWeatherByLocation(lat, lon);
      var inputDate = inputFormat.parse(
          '${weather.date!.day}/${weather.date!.month}/${weather.date!.year} ${weather.date!.hour}:${weather.date!.month}');
      print("inputDate=>$inputDate");
      setState(() {
        _data = [weather];
        outputDate = newFormatter.format(inputDate);
        _state = AppState.FINISHED_DOWNLOADING;
      });
    } else {
      try {
        weather = await ws.currentWeatherByCityName(inputControllerPlace.text);

        var inputDate = inputFormat.parse(
            '${weather.date!.day}/${weather.date!.month}/${weather.date!.year} ${weather.date!.hour}:${weather.date!.month}');
        print("inputDate=>$inputDate");
        setState(() {
          _data = [weather];
          outputDate = newFormatter.format(inputDate);
          _state = AppState.FINISHED_DOWNLOADING;
        });
      } on OpenWeatherAPIException catch (e) {
        print("error==>${e}");
        setState(() {
          _data = [];
          // txtError = "city not found";
          _state = AppState.NOT_DOWNLOADED;
        });
      }
    }

    // print("${_data.}");
  }

  Widget contentFinishedDownload() {
    return Center(
      child: ListView.separated(
        itemCount: _data.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_data[index].toString()),
          );
        },
        separatorBuilder: (context, index) {
          return const Divider();
        },
      ),
    );
  }

  Widget contentDownloading() {
    return Container(
      margin: const EdgeInsets.all(25),
      child: Column(children: [
        const Text(
          'Loading Weather...',
          style: TextStyle(fontSize: 20),
        ),
        Container(
            margin: const EdgeInsets.only(top: 50),
            child:
                const Center(child: CircularProgressIndicator(strokeWidth: 10)))
      ]),
    );
  }

  Widget contentNotDownloaded() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const <Widget>[
          Text(
            'City not found',
            style: TextStyle(fontSize: 40),
          ),
        ],
      ),
    );
  }

  Widget _resultView() => _state == AppState.FINISHED_DOWNLOADING
      ? contentFinishedDownload()
      : _state == AppState.DOWNLOADING
          ? contentDownloading()
          : contentNotDownloaded();

  void _saveLat(String input) {
    lat = double.tryParse(input) ?? lat;
    print(lat);
  }
  // void _savePlace(String input) {
  //   lat = double.tryParse(input) ;
  //   print(lat);
  // }

  void _saveLon(String input) {
    lon = double.tryParse(input) ?? lon;
    print(lon);
  }

  Widget _coordinateInputs() {
    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
              margin: const EdgeInsets.all(5),
              child: TextField(
                autofocus: true,
                cursorColor: Colors.white70,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
                controller: inputControllerPlace,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderSide:
                          const BorderSide(width: 3, color: Colors.deepPurple),
                      borderRadius: BorderRadius.circular(20)),
                  hintText: 'กรูณาใส่ชื่อเมือง',
                  hintStyle: const TextStyle(color: Colors.white70),
                  suffixIcon: const Icon(
                    Icons.find_in_page,
                    color: Colors.deepPurpleAccent,
                  ),
                  enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                          width: 3, color: Colors.deepPurpleAccent),
                      borderRadius: BorderRadius.circular(20)),
                  // disabledBorder: OutlineInputBorder(
                  //     borderSide:
                  //         BorderSide(width: 3, color: Colors.deepPurpleAccent),
                  //     borderRadius: BorderRadius.circular(20)),
                ),
                onChanged: (e) {
                  place = e;
                },
              )),
        ),
        // Expanded(
        //   child: Container(
        //       margin: const EdgeInsets.all(5),
        //       child: TextField(
        //           decoration: const InputDecoration(
        //               border: OutlineInputBorder(), hintText: 'Enter latitude'),
        //           keyboardType: TextInputType.number,
        //           onChanged: _saveLat,
        //           onSubmitted: _saveLat)),
        // ),
        // Expanded(
        //     child: Container(
        //         margin: const EdgeInsets.all(5),
        //         child: TextField(
        //             decoration: const InputDecoration(
        //                 border: OutlineInputBorder(),
        //                 hintText: 'Enter longitude'),
        //             keyboardType: TextInputType.number,
        //             onChanged: _saveLon,
        //             onSubmitted: _saveLon)))
      ],
    );
  }

  Widget _buttons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          margin: const EdgeInsets.all(10),
          child: TextButton(
            onPressed: () {
              queryWeather(true);
            },
            style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.deepPurple)),
            child: const Text(
              'local weather',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.all(10),
          child: TextButton(
            onPressed: () {
              queryWeather();
            },
            style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.deepPurple)),
            child: const Text(
              'Find weather',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        // Container(
        //   margin: const EdgeInsets.all(5),
        //   child: TextButton(
        //     onPressed: queryForecast,
        //     style: ButtonStyle(
        //         backgroundColor: MaterialStateProperty.all(Colors.blue)),
        //     child: const Text(
        //       'Fetch forecast',
        //       style: TextStyle(color: Colors.white),
        //     ),
        //   ),
        // )
      ],
    );
  }

  Widget weatherIconCode(String weatherCode) {
    return Column(
      children: [
        BoxedIcon(
          WeatherIcons.fromString(weatherCode,
              // Fallback is optional, throws if not found, and not supplied.
              fallback: WeatherIcons.na),
        ),
        Text("Icon for '$weatherCode'"),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return loaded
        ? MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.deepPurple,
            ),
            home: Scaffold(
              appBar: AppBar(
                title: const Text('Weather Example App'),
                backgroundColor: Colors.deepPurpleAccent,
                leading: const IconButton(
                  onPressed: null,
                  icon: Icon(Icons.menu),
                ),
              ),
              body: Column(
                children: [
                  Container(
                    height: 400,
                    // width: size.width,
                    margin: const EdgeInsets.only(right: 10, left: 10),
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(20),
                          right: Radius.circular(20)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Color(0xff3fa2fa),
                          Color(0xff955cd1),
                        ], // Gradient from https://learnui.design/tools/gradient-generator.html
                        tileMode: TileMode.mirror,
                      ),
                    ),
                    child: Column(
                      children: <Widget>[
                        _coordinateInputs(),
                        _buttons(),
                        // const Text(
                        //   'Output:',
                        //   style: TextStyle(fontSize: 20,color: Colors.white),
                        // ),
                        const Divider(
                          height: 20.0,
                          thickness: 2.0,
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: _state == AppState.FINISHED_DOWNLOADING
                              ? Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        "${_data[0].areaName},",
                                        style: const TextStyle(
                                            fontSize: 40, color: Colors.white),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        "${_data[0].country}",
                                        style: const TextStyle(
                                            fontSize: 40, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                )
                              : Container(),
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: _state == AppState.FINISHED_DOWNLOADING
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Column(
                                      children: [
                                        Text(
                                          "${_data[0].temperature!.celsius!.toStringAsFixed(1)} C",
                                          style: const TextStyle(
                                              fontSize: 46,
                                              color: Colors.white),
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Text(
                                              "Min:${_data[0].tempMin!.celsius!.toStringAsFixed(1)}",
                                              style: const TextStyle(
                                                  fontSize: 20,
                                                  color: Colors.white),
                                            ),
                                            const Padding(
                                                padding: EdgeInsets.only(
                                                    left: 10,
                                                    right: 10,
                                                    top: 20)),
                                            Text(
                                              "Max:${_data[0].tempMax!.celsius!.toStringAsFixed(1)}",
                                              style: const TextStyle(
                                                  fontSize: 20,
                                                  color: Colors.white),
                                            ),
                                          ],
                                        ),
                                        const Padding(
                                            padding: EdgeInsets.only(top: 10)),
                                        Text(
                                          "Feel like ${_data[0].tempFeelsLike!.celsius!.toStringAsFixed(1)}",
                                          style: const TextStyle(
                                              fontSize: 20,
                                              color: Colors.white),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "${_data[0].weatherDescription}",
                                          style: const TextStyle(
                                              fontSize: 30,
                                              color: Colors.white),
                                        ),
                                        Image.network(
                                            'http://openweathermap.org/img/w/${_data[0].weatherIcon}.png',
                                            height: 100,
                                            fit: BoxFit.cover),
                                      ],
                                    )
                                  ],
                                )
                              : Container(),
                        ),
                        _state == AppState.FINISHED_DOWNLOADING
                            ? Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  "$outputDate",
                                  style: const TextStyle(
                                      fontSize: 20, color: Colors.white),
                                ),
                              )
                            : Container(),
                        // IconButton(
                        //     // Display a Wind icon facing towards east
                        //     icon: WindIcon.towards_n,
                        //     iconSize: 30,
                        //     onPressed: () {}),
                        // weatherIconCode("${_data[0].weatherIcon}"),
                        // Text("$outputDate"),

                        // Expanded(child: Text(txtError)),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(child: _resultView()),
                ],
              ),
            ),
          )
        : MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              appBar: AppBar(
                  title: const Text("Loading"),
                  backgroundColor: Colors.deepPurpleAccent),
              body: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Center(child: CircularProgressIndicator()),
                  Text("Loading")
                ],
              ),
            ),
          );
  }
}
