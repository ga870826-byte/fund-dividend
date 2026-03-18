import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(DividendCalcApp());

class DividendCalcApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '基金配息試算',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        useMaterial3: true,
      ),
      home: CalcScreen(),
    );
  }
}

class CalcScreen extends StatefulWidget {
  @override
  _CalcScreenState createState() => _CalcScreenState();
}

class _CalcScreenState extends State<CalcScreen> {
  final TextEditingController premiumController = TextEditingController(); 
  final TextEditingController feeRateController = TextEditingController(); 
  final TextEditingController exchangeRateController = TextEditingController(text: "31.5"); 
  final TextEditingController navController = TextEditingController(); 
  final TextEditingController divController = TextEditingController(); 
  
  String selectedCurrency = "TWD"; 
  String result = "請輸入數據並執行試算";

  final List<Map<String, dynamic>> fundOptions = [
    {
      "name": "安聯收益成長-AM穩定月配息股美元", 
      "url": r"https://www.moneydj.com/funddj/ya/yp010001.djhtm?a=tlz64", 
      "defaultDiv": "0.055"
    },
    {
      "name": "景順環球高評級企業債券E-穩定月配息股美元", 
      "url": r"https://www.moneydj.com/funddj/ya/yp010001.djhtm?a=ctzP0", 
      "defaultDiv": "0.051"
    },
    {
      "name": "摩根投資基金 - 多重收益基金-JPM多重收益A股(穩定月配) JFP11", 
      "url": r"https://www.moneydj.com/funddj/ya/yp010001.djhtm?a=JFZN3", 
      "defaultDiv": "0.045" 
    },
  ];

  Map<String, dynamic>? selectedFund;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      exchangeRateController.text = prefs.getString('saved_rate') ?? "31.5";
      navController.text = prefs.getString('saved_nav') ?? "";
      divController.text = prefs.getString('saved_div') ?? "";
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_rate', exchangeRateController.text);
    await prefs.setString('saved_nav', navController.text);
    await prefs.setString('saved_div', divController.text);
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      setState(() => result = "無法開啟網頁");
    }
  }

  void runCalculation() {
    _saveData();
    double premium = double.tryParse(premiumController.text) ?? 0;
    double inputFeeRate = (double.tryParse(feeRateController.text) ?? 0) / 100; 
    double rate = double.tryParse(exchange
