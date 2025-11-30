import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const WeatherApp());

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const WeatherScreen(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
    );
  }
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final TextEditingController _cityController = TextEditingController();
  String? temperature;
  String? condition;
  String? city;
  int? humidity;
  double? windSpeed;
  double? feelsLike;
  bool loading = false;
  String? errorMessage;

  final String apiKey =
      "8bfff1a18cdba6c69c9270672a33df09"; // OpenWeatherMap API key

  Future<void> fetchWeather(String cityName) async {
    // Input validation
    if (cityName.trim().isEmpty) {
      setState(() {
        errorMessage = "Please enter a city name";
        temperature = null;
        condition = null;
        humidity = null;
        windSpeed = null;
      });
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
      temperature = null;
      condition = null;
      humidity = null;
      windSpeed = null;
    });

    try {
      final url =
          "https://api.openweathermap.org/data/2.5/weather?q=$cityName&appid=$apiKey&units=metric";

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception("Connection timeout. Please try again.");
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          city = data["name"];
          temperature = data["main"]["temp"].toStringAsFixed(1);
          condition =
              data["weather"][0]["description"].toString().toUpperCase();
          humidity = data["main"]["humidity"];
          windSpeed = (data["wind"]["speed"] as num).toDouble();
          feelsLike = (data["main"]["feels_like"] as num).toDouble();
          loading = false;
          errorMessage = null;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          errorMessage = "City not found. Please check the spelling.";
          loading = false;
        });
      } else {
        setState(() {
          errorMessage = "Error: ${response.statusCode}. Please try again.";
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error: ${e.toString()}";
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "🌤️ Weather App",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        elevation: 8,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade400,
                Colors.blue.shade700,
                Colors.indigo.shade700,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        shadowColor: Colors.blue.withOpacity(0.5),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade50,
              Colors.cyan.shade50,
              Colors.teal.shade50,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Column(
              children: [
                // Search field with colorful design
                TextField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    hintText: "🔍 Enter city name",
                    prefixIcon:
                        const Icon(Icons.location_on, color: Colors.blue),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.blue.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.blue.shade300,
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.purple.shade600,
                        width: 3,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    suffixIcon: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade400,
                            Colors.purple.shade600
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.search, color: Colors.white),
                        onPressed: () => fetchWeather(_cityController.text),
                      ),
                    ),
                  ),
                  onSubmitted: (value) => fetchWeather(value),
                ),
                const SizedBox(height: 40),

                // Loading indicator with vibrant colors
                if (loading)
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade100,
                              Colors.purple.shade100,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.purple),
                          strokeWidth: 4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "🌈 Fetching weather data...",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                // Weather display
                if (!loading && temperature != null) ...[
                  // City Name with emoji and vibrant color
                  Text(
                    "📍 ${city ?? ''}",
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Main Weather Card with vibrant gradient
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade300,
                          Colors.cyan.shade400,
                          Colors.teal.shade500,
                          Colors.indigo.shade600,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: const [0.0, 0.3, 0.6, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.4),
                          blurRadius: 25,
                          offset: const Offset(0, 12),
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Temperature Display
                        Text(
                          "$temperature°C",
                          style: const TextStyle(
                            fontSize: 80,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 0.9,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Condition
                        Text(
                          condition ?? "",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Feels Like Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            "Feels like ${feelsLike?.toStringAsFixed(1) ?? "N/A"}°C",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Key Metrics Section
                  Text(
                    "📊 Weather Details",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Metrics Grid
                  Row(
                    children: [
                      Expanded(
                        child: metricCard(
                          "Temperature",
                          "$temperature°C",
                          Icons.thermostat,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: metricCard(
                          "Humidity",
                          "$humidity%",
                          Icons.water_drop_rounded,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: metricCard(
                          "Wind Speed",
                          "${windSpeed?.toStringAsFixed(1) ?? "N/A"} m/s",
                          Icons.air_rounded,
                          Colors.cyan,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: metricCard(
                          "Feels Like",
                          "${feelsLike?.toStringAsFixed(1) ?? "N/A"}°C",
                          Icons.sentiment_satisfied_alt,
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],

                // Error message
                if (!loading && errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade300, width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.red.shade700, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Empty state with vibrant colors
                if (!loading &&
                    temperature == null &&
                    errorMessage == null) ...[
                  Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade100,
                          Colors.purple.shade100,
                          Colors.pink.shade100,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.blue.shade200,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.cloud_queue_rounded,
                          size: 100,
                          color: Colors.blue.shade400,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "🔍 Search for a city",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Enter a city name to view beautiful weather information",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blue.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Metric Card Widget - Enhanced with vibrant colors
  Widget metricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.12),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.3), color.withOpacity(0.15)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.2), width: 1),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }
}
