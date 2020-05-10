import 'dart:async';

import 'package:device_preview/device_preview.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:light/light.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: false,
      builder: (BuildContext context) => MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: LuxMeter(),
    );
  }
}

class LuxMeter extends StatefulWidget {
  LuxMeter({Key key}) : super(key: key);

  @override
  _LuxMeterState createState() => _LuxMeterState();
}

class _LuxMeterState extends State<LuxMeter> {
  List<int> lux = [0];
  Light _light = new Light();
  StreamSubscription lightStream;
  bool showAvg = false;
  List<double> maxXs = [5.0, 10.0, 20.0, 30.0, 50.0, 75.0, 100.0];
  int maxXIndex = 2;
  double maxY = 10.0;
  double get maxX => maxXs[maxXIndex];
  List<Color> gradientColors = [
    Colors.blue.shade800,
    Colors.red.shade200,
  ];
  int sunlight = 25000;

  double get maxLux =>
      lux.fold<double>(0, (max, lux) => lux > max ? lux.toDouble() : max);
  double get minLux =>
      lux.fold<double>(100000, (min, lux) => lux < min ? lux.toDouble() : min);

  int get mostRecentLux => lux[lux.length - 1];
  double get colorFilter =>
      mostRecentLux > sunlight ? 1 : mostRecentLux / sunlight;

  @override
  void initState() {
    startLightStream();
    super.initState();
  }

  @override
  dispose() {
    lightStream.cancel();
    super.dispose();
  }

  void onLightData(int luxValue) async {
    //kanske bara lägga till om det skiljer mer än x procent eller enhter från föregående?
    if (lux.isEmpty || lux.last != luxValue) {
      setState(() {
        lux.add(luxValue);
        if (lux.length > maxX + 1) {
          lux = lux.sublist(lux.length - maxX.toInt() - 1);
        }
      });
    }
  }

  void startLightStream() {
    _light = new Light();
    try {
      lightStream = _light.lightSensorStream.listen(onLightData);
    } on LightException catch (exception) {
      print(exception);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(
            Colors.white.withOpacity(colorFilter), BlendMode.overlay),
        child: Scaffold(
          backgroundColor: Color(0xff232d37),
          body: GestureDetector(
            onDoubleTap: () {
              setState(() {
                if (maxXIndex >= maxXs.length - 1) {
                  maxXIndex = 0;
                } else {
                  maxXIndex = maxXIndex + 1;
                }
              });
            },
            child: Center(
              child: Stack(
                children: <Widget>[
                  AspectRatio(
                    aspectRatio: MediaQuery.of(context).size.width /
                        MediaQuery.of(context).size.height,
                    child: Container(
                      decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(
                            Radius.circular(18),
                          ),
                          color: Color(0xff232d37)),
                      child: Padding(
                        padding: const EdgeInsets.only(
                            right: 30.0, left: 0.0, top: 30, bottom: 10),
                        child: LineChart(
                          mainData(),
                          swapAnimationDuration: Duration(milliseconds: 800),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    top: 2,
                    child: Container(
                      child: Text(
                        "$mostRecentLux lux",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            letterSpacing: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<FlSpot> getLuxSpots() {
    List<FlSpot> luxSpots = [];
    double max = maxLux;
    double min = minLux;

    for (int i = 0; i < lux.length; i++) {
      double luxValue = lux[i].toDouble();
      double factorValue = (luxValue - min) / (max - min) * maxY;
      luxSpots.add(FlSpot(i.toDouble(), factorValue));
    }

    return luxSpots;
  }

  int roundNicely(double v) {
    double min = minLux;
    double max = maxLux;

    double diffRatio = (max - min) / max;

    double value = ((max - min) / maxY) * v + min;

    if (diffRatio > 0.5) {
      return roundSuper(value);
    }
    if (diffRatio > 0.2) {
      return roundHard(value);
    }
    if (diffRatio > 0.02) {
      return roundMedium(value);
    }
    return roundSoft(value);
  }

  int roundSoft(double value) {
    if (value < 10000) {
      return value.round();
    }
    if (value < 100000) {
      return (value / 10).round() * 10;
    }
    return (value / 100).round() * 100;
  }

  int roundMedium(double value) {
    if (value < 1000) {
      return value.round();
    }
    if (value < 10000) {
      return (value / 10).round() * 10;
    }
    if (value < 100000) {
      return (value / 100).round() * 100;
    }
    return (value / 1000).round() * 1000;
  }

  int roundHard(double value) {
    if (value < 100) {
      return value.round();
    }
    if (value < 1000) {
      return (value / 10).round() * 10;
    }
    if (value < 10000) {
      return (value / 100).round() * 100;
    }
    if (value < 100000) {
      return (value / 1000).round() * 1000;
    }
    return (value / 10000).round() * 10000;
  }

  int roundSuper(double value) {
    if (value < 10) {
      return value.round();
    }
    if (value < 100) {
      return (value / 10).round() * 10;
    }
    if (value < 1000) {
      return (value / 100).round() * 100;
    }
    if (value < 10000) {
      return (value / 1000).round() * 1000;
    }
    if (value < 100000) {
      return (value / 10000).round() * 10000;
    }
    return (value / 100000).round() * 100000;
  }

  LineChartData mainData() {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: const Color(0xff37434d),
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: const Color(0xff37434d),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: SideTitles(
          showTitles: true,
          reservedSize: 22,
          textStyle: const TextStyle(
              color: Color(0xff68737d),
              fontWeight: FontWeight.bold,
              fontSize: 16),
          getTitles: (value) {
            return '';
          },
          margin: 8,
        ),
        leftTitles: SideTitles(
          showTitles: true,
          textStyle: const TextStyle(
            color: Color(0xff67727d),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          getTitles: (value) {
            switch (value.toInt()) {
              case 0:
                return "${roundNicely(0)}";
              case 3:
                return "${roundNicely(3)}";

              case 6:
                return "${roundNicely(6)}";

              case 9:
                return "${roundNicely(9)}";
            }
            return '';
          },
          reservedSize: maxLux >= 10000 ? 38 : 28,
          margin: 5,
        ),
      ),
      borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xff37434d), width: 1)),
      minX: 0,
      maxX: maxX,
      minY: 0,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: getLuxSpots(),
          gradientFrom: Offset(1, 1),
          gradientTo: Offset(1, 0),
          //color stops
          //Gradient from och to är vad jag ska kolla på?
          isCurved: true,
          colors: gradientColors,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(
            gradientFrom: Offset(1, 1),
            gradientTo: Offset(1, 0),

            show: true, //Frägen ska vara beroende på max lux ttyp?
            colors:
                gradientColors.map((color) => color.withOpacity(0.3)).toList(),
          ),
        ),
      ],
    );
  }
}
