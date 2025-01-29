import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Portfolio {
  final String userId;
  final List<Asset> assets;
  final List<Liability> liabilities;
  final DateTime lastUpdated;

  Portfolio({
    required this.userId,
    required this.assets,
    required this.liabilities,
    required this.lastUpdated,
  });

  double get netWorth =>
      assets.fold(0.0, (sum, asset) => sum + asset.value) -
      liabilities.fold(0, (sum, liability) => sum + liability.amount);

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'assets': assets.map((asset) => asset.toJson()).toList(),
        'liabilities':
            liabilities.map((liability) => liability.toJson()).toList(),
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory Portfolio.fromJson(Map<String, dynamic> json) => Portfolio(
        userId: json['userId'],
        assets: (json['assets'] as List)
            .map((asset) => Asset.fromJson(asset))
            .toList(),
        liabilities: (json['liabilities'] as List)
            .map((liability) => Liability.fromJson(liability))
            .toList(),
        lastUpdated: DateTime.parse(json['lastUpdated']),
      );
}

class Asset {
  final String name;
  final double value;
  final String type;

  Asset({required this.name, required this.value, required this.type});

  Map<String, dynamic> toJson() => {
        'name': name,
        'value': value,
        'type': type,
      };

  factory Asset.fromJson(Map<String, dynamic> json) => Asset(
        name: json['name'],
        value: json['value'].toDouble(),
        type: json['type'],
      );
}

class Liability {
  final String name;
  final double amount;
  final double interestRate;

  Liability({
    required this.name,
    required this.amount,
    required this.interestRate,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount': amount,
        'interestRate': interestRate,
      };

  factory Liability.fromJson(Map<String, dynamic> json) => Liability(
        name: json['name'],
        amount: json['amount'].toDouble(),
        interestRate: json['interestRate'].toDouble(),
      );
}

class FinanceEducationPage extends StatefulWidget {
  final String? userId;

  const FinanceEducationPage({super.key, this.userId});

  @override
  State<FinanceEducationPage> createState() => _FinanceEducationPageState();
}

class _FinanceEducationPageState extends State<FinanceEducationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Portfolio? portfolio;
  final _assetNameController = TextEditingController();
  final _assetValueController = TextEditingController();
  final _liabilityNameController = TextEditingController();
  final _liabilityAmountController = TextEditingController();
  final _liabilityInterestController = TextEditingController();

  final List<Map<String, dynamic>> creditTips = [
    {
      'title': 'Payment History (35% Impact)',
      'tips': [
        'Set up automatic payments for bills',
        'Pay all bills on time',
        'If you miss a payment, get current as soon as possible',
        'Keep accounts from going to collections'
      ]
    },
    {
      'title': 'Credit Utilization (30% Impact)',
      'tips': [
        'Keep credit card balances below 30% of limits',
        'Consider requesting credit limit increases',
        'Pay credit card balances multiple times per month',
        'Keep old accounts open to maintain available credit'
      ]
    },
    {
      'title': 'Length of Credit History (15% Impact)',
      'tips': [
        'Keep old accounts open and active',
        'Avoid opening too many new accounts at once',
        'Use older credit cards occasionally to keep them active'
      ]
    },
    {
      'title': 'Credit Mix (10% Impact)',
      'tips': [
        'Maintain a mix of credit types (credit cards, loans)',
        'Consider a secured credit card if building credit',
        'Don\'t open new accounts just for mix - only as needed'
      ]
    },
    {
      'title': 'New Credit (10% Impact)',
      'tips': [
        'Limit hard credit inquiries',
        'Research credit cards before applying',
        'Space out new credit applications',
        'Shop for rates within a focused period'
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.userId != null) {
      loadPortfolio();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _assetNameController.dispose();
    _assetValueController.dispose();
    _liabilityNameController.dispose();
    _liabilityAmountController.dispose();
    _liabilityInterestController.dispose();
    super.dispose();
  }

  Future<void> loadPortfolio() async {
    final prefs = await SharedPreferences.getInstance();
    final portfolioJson = prefs.getString('portfolio_${widget.userId}');
    if (portfolioJson != null) {
      setState(() {
        portfolio = Portfolio.fromJson(jsonDecode(portfolioJson));
      });
    } else {
      setState(() {
        portfolio = Portfolio(
          userId: widget.userId!,
          assets: [],
          liabilities: [],
          lastUpdated: DateTime.now(),
        );
      });
    }
  }

  Future<void> savePortfolio() async {
    if (portfolio == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'portfolio_${widget.userId}', jsonEncode(portfolio!.toJson()));
  }

  void addAsset() {
    if (_assetNameController.text.isEmpty ||
        _assetValueController.text.isEmpty) {
      return;
    }

    setState(() {
      portfolio!.assets.add(Asset(
        name: _assetNameController.text,
        value: double.tryParse(_assetValueController.text) ?? 0.0,
        type: 'General',
      ));
      _assetNameController.clear();
      _assetValueController.clear();
    });
    savePortfolio();
  }

  void addLiability() {
    if (_liabilityNameController.text.isEmpty ||
        _liabilityAmountController.text.isEmpty ||
        _liabilityInterestController.text.isEmpty) {
      return;
    }

    setState(() {
      portfolio!.liabilities.add(Liability(
        name: _liabilityNameController.text,
        amount: double.tryParse(_liabilityAmountController.text) ?? 0.0,
        interestRate: double.tryParse(_liabilityInterestController.text) ?? 0.0,
      ));
      _liabilityNameController.clear();
      _liabilityAmountController.clear();
      _liabilityInterestController.clear();
    });
    savePortfolio();
  }

  Widget buildPortfolioTab() {
    if (portfolio == null) {
      return const Center(
          child: Text('Please log in to manage your portfolio'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Net Worth: \$${portfolio!.netWorth.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Last Updated: ${portfolio!.lastUpdated.toString().split('.')[0]}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assets',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _assetNameController,
                  decoration: const InputDecoration(
                    labelText: 'Asset Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _assetValueController,
                  decoration: const InputDecoration(
                    labelText: 'Value',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: addAsset,
                  child: const Text('Add Asset'),
                ),
                const SizedBox(height: 16),
                ...portfolio!.assets.map((asset) => ListTile(
                      title: Text(asset.name),
                      subtitle: Text('Type: ${asset.type}'),
                      trailing: Text('\$${asset.value.toStringAsFixed(2)}'),
                    )),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Liabilities',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _liabilityNameController,
                  decoration: const InputDecoration(
                    labelText: 'Liability Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _liabilityAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _liabilityInterestController,
                  decoration: const InputDecoration(
                    labelText: 'Interest Rate (%)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: addLiability,
                  child: const Text('Add Liability'),
                ),
                const SizedBox(height: 16),
                ...portfolio!.liabilities.map((liability) => ListTile(
                      title: Text(liability.name),
                      subtitle:
                          Text('Interest Rate: ${liability.interestRate}%'),
                      trailing:
                          Text('\$${liability.amount.toStringAsFixed(2)}'),
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildEducationTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: creditTips.length,
      itemBuilder: (context, index) {
        final section = creditTips[index];
        return Card(
          child: ExpansionTile(
            title: Text(
              section['title'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...(section['tips'] as List).map((tip) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.arrow_right, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(child: Text(tip)),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildResourcesTab() {
    final List<Map<String, String>> resources = [
      {
        'title': 'Credit Report Basics',
        'description':
            'Learn how to read and understand your credit report, including what factors affect your score.',
        'videoUrl': 'https://www.youtube.com/watch?v=71iaNlskCc0',
      },
      {
        'title': 'Debt Management Strategies',
        'description':
            'Explore different methods for managing and paying off debt effectively.',
        'videoUrl': 'https://www.youtube.com/watch?v=J5KIc8Fzbz4',
      },
      {
        'title': 'Budgeting Fundamentals',
        'description':
            'Master the basics of creating and maintaining a budget that works for you.',
        'videoUrl': 'https://www.youtube.com/watch?v=sVKQn2I4HDM',
      },
      {
        'title': 'Investment Basics',
        'description':
            'Understand the fundamentals of investing and growing your wealth.',
        'videoUrl': 'https://www.youtube.com/watch?v=HNPbY6fSeo8',
      },
      {
        'title': 'Emergency Fund Planning',
        'description':
            'Learn how to build and maintain an emergency fund for financial security.',
        'videoUrl': 'https://www.youtube.com/watch?v=g-hir-4WzfU',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: resources.length,
      itemBuilder: (context, index) {
        final resource = resources[index];
        return Card(
          child: ListTile(
            title: Text(
              resource['title']!,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(resource['description']!),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ResourceWebView(
                    title: resource['title']!,
                    url: resource['videoUrl']!,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Education'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Portfolio'),
            Tab(text: 'Education'),
            Tab(text: 'Resources'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildPortfolioTab(),
          buildEducationTab(),
          buildResourcesTab(),
        ],
      ),
    );
  }
}

class ResourceWebView extends StatefulWidget {
  final String title;
  final String url;

  const ResourceWebView({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  State<ResourceWebView> createState() => _ResourceWebViewState();
}

class _ResourceWebViewState extends State<ResourceWebView> {
  late final WebViewController controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (progress == 100) {
              setState(() {
                isLoading = false;
              });
            }
          },
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              controller.reload();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

void main() {
  runApp(
    MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const FinanceEducationPage(userId: 'user123'),
    ),
  );
}
