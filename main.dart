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
      "name": "安聯收益成長-AM穩定月配息股美元(DSP5)", 
      "url": r"https://www.moneydj.com/funddj/ya/yp010001.djhtm?a=tlz64", 
      "defaultDiv": "0.055"
    },
    {
      "name": "景順環球高評級企業債券E-穩定月配息股美元(IGB5)", 
      "url": r"https://www.moneydj.com/funddj/ya/yp010001.djhtm?a=ctzP0", 
      "defaultDiv": "0.051"
    },
    {
      "name": "摩根投資基金-JPM多重收益A股穩定月配美元 (JFP11)", 
      "url": r"https://www.moneydj.com/funddj/ya/yp010001.djhtm?a=JFZN3", 
      "defaultDiv": "0.045" 
    },
    {
      "name": "富蘭克林坦伯頓全球投資系列-穩定月收益美元(FRP4)", 
      "url": r"https://www.moneydj.com/funddj/ya/yp010001.djhtm?a=flz92", 
      "defaultDiv": "0.052" 
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
    double rate = double.tryParse(exchangeRateController.text) ?? 1.0;
    double nav = double.tryParse(navController.text) ?? 0;
    double divPerUnit = double.tryParse(divController.text) ?? 0;

    if (premium <= 0 || nav <= 0 || rate <= 0) {
      setState(() => result = "請完整輸入金額、手續費、匯率及淨值");
      return;
    }

    double feeAmount = premium * inputFeeRate;
    double netPremium = premium - feeAmount;
    
    double units = (selectedCurrency == "TWD") ? (netPremium / rate) / nav : netPremium / nav;
    double monthlyUSD = units * divPerUnit;
    double monthlyTWD = monthlyUSD * rate;
    double yearlyUSD = monthlyUSD * 12;
    double yearlyTWD = yearlyUSD * rate;

    setState(() {
      if (selectedCurrency == "TWD") {
        result = "【台幣版本結論】\n手續費率：${(inputFeeRate * 100).toStringAsFixed(1)}%\n淨投入金額：${netPremium.toStringAsFixed(0)} TWD\n購入單位數：${units.toStringAsFixed(4)}\n-----------------------------------\n預計每月領取：${monthlyTWD.toStringAsFixed(0)} TWD\n預計每年合計：${yearlyTWD.toStringAsFixed(0)} TWD";
      } else {
        result = "【美元版本結論】\n手續費率：${(inputFeeRate * 100).toStringAsFixed(1)}%\n淨投入金額：${netPremium.toStringAsFixed(2)} USD\n購入單位數：${units.toStringAsFixed(4)}\n-----------------------------------\n預計每月領取：${monthlyUSD.toStringAsFixed(2)} USD\n(約合台幣：${monthlyTWD.toStringAsFixed(0)} TWD)\n\n預計每年合計：${yearlyUSD.toStringAsFixed(2)} USD\n(約合台幣：${yearlyTWD.toStringAsFixed(0)} TWD)";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('基金配息試算'), centerTitle: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            SegmentedButton<String>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 5),
                visualDensity: VisualDensity.compact,
              ),
              segments: [
                ButtonSegment(value: 'TWD', label: Text('台幣', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                ButtonSegment(value: 'USD', label: Text('美元', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              ],
              selected: {selectedCurrency},
              onSelectionChanged: (val) => setState(() => selectedCurrency = val.first),
            ),
            SizedBox(height: 20),
            DropdownButtonFormField<Map<String, dynamic>>(
              decoration: InputDecoration(labelText: "選擇標的", border: OutlineInputBorder()),
              value: selectedFund,
              items: fundOptions.map((f) => DropdownMenuItem(value: f, child: SizedBox(width: MediaQuery.of(context).size.width * 0.7, child: Text(f['name'], style: TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)))).toList(),
              onChanged: (val) {
                setState(() {
                  selectedFund = val;
                  divController.text = val!['defaultDiv'];
                  _launchUrl(val['url']!);
                });
              },
            ),
            SizedBox(height: 15),
            TextField(
              controller: premiumController,
              decoration: InputDecoration(labelText: "投入保費 ($selectedCurrency)", border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              enableInteractiveSelection: true,
            ),
            SizedBox(height: 15),
            TextField(
              controller: feeRateController,
              decoration: InputDecoration(labelText: "手續費率 (%)", hintText: "例如輸入 3 代表 3%", border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              enableInteractiveSelection: true,
            ),
            SizedBox(height: 15),
            TextField(
              controller: exchangeRateController,
              decoration: InputDecoration(labelText: "參考匯率 (USD/TWD)", border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              enableInteractiveSelection: true,
              onChanged: (v) => _saveData(),
            ),
            SizedBox(height: 15),
            TextField(
              controller: navController,
              decoration: InputDecoration(labelText: "當前淨值 (USD)", border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              enableInteractiveSelection: true,
              onChanged: (v) => _saveData(),
            ),
            SizedBox(height: 15),
            TextField(
              controller: divController,
              decoration: InputDecoration(labelText: "單位配息 (USD)", border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              enableInteractiveSelection: true,
              onChanged: (v) => _saveData(),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50), backgroundColor: Colors.blueGrey),
              onPressed: runCalculation,
              child: Text("執行試算", style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
            SizedBox(height: 20),
            Container(
              width: double.infinity, 
              padding: EdgeInsets.all(15), 
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)), 
              child: Text(result)
            ),
            SizedBox(height: 30),
            const Divider(),
            const Text("【手續費率級距參考表】", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            SizedBox(height: 15), 
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFeeTable("台幣", [
                  "200萬以下：5%",
                  "200萬~500萬：4%",
                  "500萬~1000萬：3%",
                  "1000萬以上：2%",
                ]),
                _buildFeeTable("美元", [
                  "66,600以下：5%",
                  "66,600~166,600：4%",
                  "166,600~333,300：3%",
                  "333,300以上：2%",
                ]),
              ],
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeTable(String title, List<String> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
        ...rows.map((row) => Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Text(row, style: const TextStyle(fontSize: 14)),
        )).toList(),
      ],
    );
  }
}
