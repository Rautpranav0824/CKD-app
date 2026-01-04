import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

void main() => runApp(const CkdMitraApp());

class CkdMitraApp extends StatelessWidget {
  const CkdMitraApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF5F7F9),
        useMaterial3: true,
      ),
      home: const AccountSetupScreen(),
    );
  }
}

// --- 1. ACCOUNT SETUP ---
class AccountSetupScreen extends StatefulWidget {
  const AccountSetupScreen({super.key});
  @override
  State<AccountSetupScreen> createState() => _AccountSetupScreenState();
}

class _AccountSetupScreenState extends State<AccountSetupScreen> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String _selectedStage = 'Stage 3'; 

  void _completeSetup() {
    if (_weightController.text.isNotEmpty && _ageController.text.isNotEmpty) {
      double weight = double.parse(_weightController.text);
      int age = int.parse(_ageController.text);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => 
        HomeScreen(userWeight: weight, userAge: age, ckdStage: _selectedStage),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: [
            const SizedBox(height: 60),
            const Icon(Icons.health_and_safety, size: 80, color: Colors.blue),
            const Text("CKD MITRA", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.blue)),
            const Text("Your AI Kidney Companion", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            TextField(controller: _weightController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Weight (kg)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.monitor_weight))),
            const SizedBox(height: 20),
            TextField(controller: _ageController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Age", border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today))),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedStage,
              decoration: const InputDecoration(labelText: "CKD Stage", border: OutlineInputBorder(), prefixIcon: Icon(Icons.layers)),
              items: ['Stage 1-2', 'Stage 3', 'Stage 4', 'Stage 5', 'Stage 5D (Dialysis)'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
              onChanged: (v) => setState(() => _selectedStage = v!),
            ),
            const SizedBox(height: 40),
            SizedBox(width: double.infinity, height: 60, child: ElevatedButton(onPressed: _completeSetup, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text("GO TO DASHBOARD", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
          ],
        ),
      ),
    );
  }
}

// --- 2. MAIN HOME SCREEN ---
class HomeScreen extends StatefulWidget {
  final double userWeight; final int userAge; final String ckdStage;
  const HomeScreen({super.key, required this.userWeight, required this.userAge, required this.ckdStage});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int currentProtein = 0; int currentPhos = 0; int currentPotass = 0;

  double get proteinLimit => (widget.ckdStage == 'Stage 5D (Dialysis)') ? widget.userWeight * 1.2 : (widget.ckdStage == 'Stage 1-2' ? widget.userWeight * 0.8 : widget.userWeight * 0.6);
  int get phosLimit => 800; 
  int get potassLimit => (widget.ckdStage == 'Stage 1-2') ? 3500 : 2000;

  // --- NOTIFICATION ALERT LOGIC ---
  void _checkNutrientAlerts() {
    String message = "";
    bool isDanger = false;

    if (currentPotass >= potassLimit) {
      message = "🚨 POTASSIUM DANGER! Limit exceeded. High levels can affect heart rhythm.";
      isDanger = true;
    } else if (currentPotass >= potassLimit * 0.9) {
      message = "⚠️ Potassium Warning: You are at 90%. Avoid high-potassium foods like bananas or potatoes.";
    } else if (currentProtein >= proteinLimit) {
      message = "🚨 PROTEIN LIMIT! Excessive protein increases kidney workload.";
      isDanger = true;
    } else if (currentProtein >= proteinLimit * 0.9) {
      message = "⚠️ Protein Warning: 90% reached. Stick to light, low-protein snacks now.";
    } else if (currentPhos >= phosLimit) {
      message = "🚨 PHOSPHORUS ALERT! Limit reached. High phos weakens bones.";
      isDanger = true;
    } else if (currentPhos >= phosLimit * 0.9) {
      message = "⚠️ Phosphorus Warning: 90% reached. Avoid dairy for the rest of the day.";
    }

    if (message.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(children: [
            Icon(isDanger ? Icons.report_gmailerrorred : Icons.warning_amber_rounded, color: isDanger ? Colors.red : Colors.orange),
            const SizedBox(width: 10),
            Text(isDanger ? "Critical Alert" : "Limit Warning"),
          ]),
          content: Text(message),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      );
    }
  }

  // --- SMART MEAL SUGGESTIONS ---
  void _showRecommendations(String mealType) {
    List<Map<String, String>> suggestions = [];
    bool isDialysis = widget.ckdStage.contains('5D');

    if (mealType == "Breakfast") {
      suggestions = isDialysis 
        ? [{'title': 'Egg White Scramble', 'desc': 'Safe protein for dialysis.'}, {'title': 'White Toast', 'desc': 'Low phosphorus grain.'}]
        : [{'title': 'Poha with Lemon', 'desc': 'Low protein, easy on kidneys.'}, {'title': 'Rice Upma', 'desc': 'Low potassium energy start.'}];
    } 
    else if (mealType == "Lunch") {
      suggestions = isDialysis
        ? [{'title': 'Chicken & Rice', 'desc': 'Essential protein for dialysis.'}, {'title': 'Sautéed Beans', 'desc': 'Safe fiber source.'}]
        : [{'title': 'Rice & Dal', 'desc': 'Controlled plant protein.'}, {'title': 'Cucumber Salad', 'desc': 'Low potassium hydration.'}];
    } 
    else if (mealType == "Dinner") {
      suggestions = isDialysis
        ? [{'title': 'Steamed Fish', 'desc': 'Lean protein dinner.'}, {'title': 'Leached Ridge Gourd', 'desc': 'Potassium-removed veggie.'}]
        : [{'title': 'Rice & Bottle Gourd', 'desc': 'Safest dinner for Stage 3-4.'}, {'title': 'Phulka & Ivy Gourd', 'desc': 'Minimal kidney strain.'}];
    } 
    else {
      suggestions = [{'title': 'Red Grapes', 'desc': 'Kidney-friendly fruit.'}, {'title': 'Unsalted Rice Crackers', 'desc': 'Zero-sodium snack.'}];
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("AI Suggestions: $mealType", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
            Text("Stage-specific menu for ${widget.ckdStage}", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            ...suggestions.map((s) => ListTile(
              leading: const Icon(Icons.restaurant_menu, color: Colors.orange),
              title: Text(s['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(s['desc']!),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Future<void> _scanMeal() async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.gallery);
    if (photo == null) return;

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("AI Vision analyzing meal..."),
      backgroundColor: Colors.blue, 
      duration: Duration(seconds: 1),
    ));

    await Future.delayed(const Duration(seconds: 1));
    setState(() { 
      currentProtein += 25; currentPhos += 300; currentPotass += 750; 
    });
    _checkNutrientAlerts();
  }

  @override
  Widget build(BuildContext context) {
    Widget currentBody = _selectedIndex == 0 ? _buildDashboard() : (_selectedIndex == 2 ? _buildSimpleSupport() : _buildSimpleRisk());
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0.5, title: const Text("CKD MITRA", style: TextStyle(fontWeight: FontWeight.w900))),
      body: currentBody,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => i == 1 ? _scanMeal() : setState(() => _selectedIndex = i),
        selectedItemColor: Colors.blue[900], unselectedItemColor: Colors.grey, type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt_rounded), label: 'Scan'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_rounded), label: 'Support'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: 'Risk'),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("Daily Limits", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            Chip(label: Text(widget.ckdStage, style: const TextStyle(color: Colors.white, fontSize: 12)), backgroundColor: Colors.blue),
          ]),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)]),
            child: Row(
              children: [
                Expanded(child: NutrientCircle(label: "Protein", current: currentProtein, total: proteinLimit.toInt(), unit: "g", color: Colors.orange)),
                Expanded(child: NutrientCircle(label: "Phos", current: currentPhos, total: phosLimit, unit: "mg", color: Colors.redAccent)),
                Expanded(child: NutrientCircle(label: "Potass", current: currentPotass, total: potassLimit, unit: "mg", color: Colors.green)),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Text("Today's Meals", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text("Tap for AI Recommendations", style: TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 15),
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), 
            mainAxisSpacing: 15, crossAxisSpacing: 15, childAspectRatio: 0.85, 
            children: [
              GestureDetector(onTap: () => _showRecommendations("Breakfast"), child: const MealCard(label: "Breakfast", icon: Icons.breakfast_dining)),
              GestureDetector(onTap: () => _showRecommendations("Lunch"), child: const MealCard(label: "Lunch", icon: Icons.lunch_dining)),
              GestureDetector(onTap: () => _showRecommendations("Dinner"), child: const MealCard(label: "Dinner", icon: Icons.dinner_dining)),
              GestureDetector(onTap: () => _showRecommendations("Snacks"), child: const MealCard(label: "Snacks", icon: Icons.cookie)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleSupport() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center, 
      children: [
        const Icon(Icons.chat_bubble_outline, size: 80, color: Colors.blue), 
        const SizedBox(height: 20), 
        Text("AI Support Chat\nLive in ${DateTime.now().year}", textAlign: TextAlign.center, style: const TextStyle(fontSize: 18))
      ],
    ),
  );

  Widget _buildSimpleRisk() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center, 
      children: const [
        Icon(Icons.analytics_outlined, size: 80, color: Colors.orange), 
        SizedBox(height: 20), 
        Text("Risk Predictor\nAnalyzing GFR Trends", textAlign: TextAlign.center, style: TextStyle(fontSize: 18))
      ],
    ),
  );
}

class NutrientCircle extends StatelessWidget {
  final String label; final int current; final int total; final String unit; final Color color;
  const NutrientCircle({super.key, required this.label, required this.current, required this.total, required this.unit, required this.color});
  @override
  Widget build(BuildContext context) {
    double progress = (total == 0) ? 0.0 : (current / total).toDouble();
    return Column(children: [
      Stack(alignment: Alignment.center, children: [
        SizedBox(height: 70, width: 70, child: CircularProgressIndicator(value: progress.clamp(0.0, 1.0), strokeWidth: 7, color: color, backgroundColor: color.withOpacity(0.1))),
        FittedBox(child: Padding(padding: const EdgeInsets.all(8.0), child: Column(children: [Text("$current", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)), Text("/$total$unit", style: const TextStyle(fontSize: 8))]))),
      ]),
      const SizedBox(height: 8),
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
    ]);
  }
}

class MealCard extends StatelessWidget {
  final String label; final IconData icon;
  const MealCard({super.key, required this.label, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blue.withOpacity(0.1)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 40, color: Colors.blue),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ]),
    );
  }
}