import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const CreditScoreApp());
}

class CreditScoreApp extends StatefulWidget {
  const CreditScoreApp({super.key});

  @override
  State<CreditScoreApp> createState() => _CreditScoreAppState();
}

class _CreditScoreAppState extends State<CreditScoreApp> {
  bool isDarkMode = false;

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Credit Score Insights',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
      ),
      home: HomePage(toggleTheme: toggleTheme, isDarkMode: isDarkMode),
    );
  }
}

class UserData {
  final String userId;
  final int creditScore;
  final int creditUtilization;
  final int paymentHistory;
  final int creditAge;
  final DateTime lastChecked;

  UserData({
    required this.userId,
    required this.creditScore,
    required this.creditUtilization,
    required this.paymentHistory,
    required this.creditAge,
    required this.lastChecked,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'creditScore': creditScore,
        'creditUtilization': creditUtilization,
        'paymentHistory': paymentHistory,
        'creditAge': creditAge,
        'lastChecked': lastChecked.toIso8601String(),
      };

  factory UserData.fromJson(Map<String, dynamic> json) => UserData(
        userId: json['userId'],
        creditScore: json['creditScore'],
        creditUtilization: json['creditUtilization'],
        paymentHistory: json['paymentHistory'],
        creditAge: json['creditAge'],
        lastChecked: DateTime.parse(json['lastChecked']),
      );
}

class HomePage extends StatefulWidget {
  final Function toggleTheme;
  final bool isDarkMode;

  const HomePage({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int creditScore = 0;
  List<String> insuranceRecommendations = [];
  List<String> insights = [];
  Timer? timer;
  final TextEditingController userIdController = TextEditingController();
  String? userId;
  int creditUtilization = 0;
  int paymentHistory = 0;
  int creditAge = 0;
  bool isLoading = false;
  List<UserData> recentUsers = [];
  bool showInsuranceCalculator = false;

  // Insurance calculator fields
  final TextEditingController ageController = TextEditingController();
  String selectedInsuranceType = 'Life';
  int coverage = 100000;
  String? calculatedPremium;

  @override
  void initState() {
    super.initState();
    loadRecentUsers();
  }

  @override
  void dispose() {
    timer?.cancel();
    userIdController.dispose();
    ageController.dispose();
    super.dispose();
  }

  Future<void> loadRecentUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getStringList('recentUsers') ?? [];
    setState(() {
      recentUsers =
          usersJson.map((json) => UserData.fromJson(jsonDecode(json))).toList();
    });
  }

  Future<void> saveRecentUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson =
        recentUsers.map((userData) => jsonEncode(userData.toJson())).toList();
    await prefs.setStringList('recentUsers', usersJson);
  }

  void startMonitoring() {
    if (userId == null || userId!.isEmpty) return;

    updateData();
    timer?.cancel();
    timer =
        Timer.periodic(const Duration(seconds: 30), (Timer t) => updateData());
  }

  String calculateInsurancePremium() {
    if (ageController.text.isEmpty) return 'Please enter age';

    final age = int.parse(ageController.text);
    final baseRate = selectedInsuranceType == 'Life'
        ? 5
        : selectedInsuranceType == 'Health'
            ? 7
            : 4;

    double premium = (coverage / 1000) * baseRate;

    // Age factor
    if (age > 50)
      premium *= 1.5;
    else if (age > 30) premium *= 1.2;

    // Credit score factor
    if (creditScore < 600)
      premium *= 1.3;
    else if (creditScore > 700) premium *= 0.8;

    return '\$${premium.toStringAsFixed(2)}/month';
  }

  void updateData() {
    if (userId == null) return;

    setState(() {
      isLoading = true;
    });

    // Simulate API call delay
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        // Generate consistent score based on user ID
        final random = Random(userId.hashCode);
        creditScore = random.nextInt(550) + 300;
        creditUtilization = random.nextInt(100);
        paymentHistory = random.nextInt(100);
        creditAge = random.nextInt(20);

        // Update recent users
        final userData = UserData(
          userId: userId!,
          creditScore: creditScore,
          creditUtilization: creditUtilization,
          paymentHistory: paymentHistory,
          creditAge: creditAge,
          lastChecked: DateTime.now(),
        );

        recentUsers.removeWhere((user) => user.userId == userId);
        recentUsers.insert(0, userData);
        if (recentUsers.length > 5) recentUsers.removeLast();
        saveRecentUsers();

        updateRecommendations();
        updateInsights();
        isLoading = false;
      });
    });
  }

  void updateRecommendations() {
    insuranceRecommendations.clear();
    if (creditScore >= 700) {
      insuranceRecommendations.addAll([
        'Premium Life Insurance with low premiums',
        'Comprehensive Health Insurance with additional benefits',
        'Premium Auto Insurance with special discounts',
        'High-value Property Insurance',
        'Premium Travel Insurance',
      ]);
    } else if (creditScore >= 600) {
      insuranceRecommendations.addAll([
        'Standard Life Insurance',
        'Basic Health Insurance',
        'Standard Auto Insurance',
        'Basic Property Insurance',
        'Standard Travel Insurance',
      ]);
    } else {
      insuranceRecommendations.addAll([
        'Basic Life Insurance with higher premiums',
        'Essential Health Insurance',
        'Minimum Auto Insurance coverage',
        'Limited Property Insurance',
        'Basic Travel Insurance with restrictions',
      ]);
    }
  }

  void updateInsights() {
    insights.clear();
    if (creditScore >= 700) {
      insights.addAll([
        'Excellent credit standing',
        'Eligible for premium financial products',
        'Low risk profile for insurers',
        'Credit utilization: $creditUtilization% (Excellent)',
        'Payment history: $paymentHistory% on-time payments',
        'Credit age: $creditAge years',
      ]);
    } else if (creditScore >= 600) {
      insights.addAll([
        'Good credit standing',
        'Room for improvement',
        'Consider credit-building strategies',
        'Credit utilization: $creditUtilization% (Good)',
        'Payment history: $paymentHistory% on-time payments',
        'Credit age: $creditAge years',
      ]);
    } else {
      insights.addAll([
        'Credit needs attention',
        'Focus on improving payment history',
        'Consider credit counseling',
        'Credit utilization: $creditUtilization% (Needs Improvement)',
        'Payment history: $paymentHistory% on-time payments',
        'Credit age: $creditAge years',
      ]);
    }
  }

  Color getCreditScoreColor() {
    if (creditScore >= 700) return Colors.green;
    if (creditScore >= 600) return Colors.orange;
    return Colors.red;
  }

  String getCreditScoreCategory() {
    if (creditScore >= 700) return 'Excellent';
    if (creditScore >= 600) return 'Good';
    return 'Poor';
  }

  Widget buildInsuranceCalculator() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Insurance Calculator',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () =>
                      setState(() => showInsuranceCalculator = false),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Age',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedInsuranceType,
              decoration: const InputDecoration(
                labelText: 'Insurance Type',
                border: OutlineInputBorder(),
              ),
              items: ['Life', 'Health', 'Auto'].map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedInsuranceType = value!;
                  calculatedPremium = calculateInsurancePremium();
                });
              },
            ),
            const SizedBox(height: 16),
            Slider(
              value: coverage.toDouble(),
              min: 50000,
              max: 1000000,
              divisions: 19,
              label: '\$${NumberFormat('#,###').format(coverage)}',
              onChanged: (value) {
                setState(() {
                  coverage = value.toInt();
                  calculatedPremium = calculateInsurancePremium();
                });
              },
            ),
            Text('Coverage: \$${NumberFormat('#,###').format(coverage)}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  calculatedPremium = calculateInsurancePremium();
                });
              },
              child: const Text('Calculate Premium'),
            ),
            if (calculatedPremium != null) ...[
              const SizedBox(height: 16),
              Text(
                'Estimated Premium: $calculatedPremium',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildRecentUsers() {
    if (recentUsers.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Users',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...recentUsers.map((userData) => ListTile(
                  title: Text('User ID: ${userData.userId}'),
                  subtitle: Text(
                    'Score: ${userData.creditScore} (${DateFormat('MMM d, y').format(userData.lastChecked)})',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      setState(() {
                        userId = userData.userId;
                        userIdController.text = userData.userId;
                      });
                      updateData();
                    },
                  ),
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit Score Insights'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => widget.toggleTheme(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => updateData(),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            if (userId == null) ...[
              buildRecentUsers(),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Enter User ID',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: userIdController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'User ID',
                          hintText: 'Enter your user ID',
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            userId = userIdController.text;
                          });
                          startMonitoring();
                        },
                        child: const Text('Start Monitoring'),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Your Credit Score',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                userId = null;
                                creditScore = 0;
                                insuranceRecommendations.clear();
                                insights.clear();
                                timer?.cancel();
                              });
                            },
                            child: const Text('Change User'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (isLoading)
                        const CircularProgressIndicator()
                      else
                        Column(
                          children: [
                            Text(
                              creditScore.toString(),
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: getCreditScoreColor(),
                              ),
                            ),
                            Text(
                              getCreditScoreCategory(),
                              style: TextStyle(
                                fontSize: 24,
                                color: getCreditScoreColor(),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Insurance Recommendations',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                showInsuranceCalculator = true;
                              });
                            },
                            child: const Text('Calculate Premium'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        ...insuranceRecommendations.map((rec) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: Colors.green),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(rec)),
                                ],
                              ),
                            )),
                    ],
                  ),
                ),
              ),
              if (showInsuranceCalculator) ...[
                const SizedBox(height: 16),
                buildInsuranceCalculator(),
              ],
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Profile Insights',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        ...insights.map((insight) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.lightbulb,
                                      color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(insight)),
                                ],
                              ),
                            )),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: userId != null
          ? FloatingActionButton(
              onPressed: updateData,
              child: const Icon(Icons.refresh),
            )
          : null,
    );
  }
}
