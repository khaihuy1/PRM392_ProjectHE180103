import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';

class GamePlayPage extends StatefulWidget {
  @override
  _GamePlayPageState createState() => _GamePlayPageState();
}

class _GamePlayPageState extends State<GamePlayPage> with SingleTickerProviderStateMixin {
  // --- TRẠNG THÁI GAME ---
  int score = 0;
  int highScore = 0;
  int timeLeft = 30;
  bool isNewRecord = false;
  List<LixiItem> items = [];
  Timer? gameTimer;
  Timer? dropTimer;
  final Random random = Random();

  // --- THÔNG SỐ CÁI THÚNG (BASKET) ---
  double basketX = 150;
  double basketWidth = 100;
  double basketHeight = 70;

  // --- HIỆU ỨNG RUNG CHO THÚNG ---
  double basketShake = 0.0;
  Timer? shakeTimer;

  // --- HIỆU ỨNG NỔ SAU KHI HỨNG ---
  List<CatchEffect> catchEffects = [];

  // --- ĐỘ KHÓ ---
  double baseSpeed = 5.0;
  double speedMultiplier = 1.0;

  // --- VÙNG CHẠM (ĐIỀU CHỈNH ĐỂ HỨNG DỄ HƠN) ---
  double catchZoneTop = 0;
  double catchZoneBottom = 0;

  // --- HIỆU ỨNG ---
  late ConfettiController _controllerLeft;
  late ConfettiController _controllerRight;
  late AnimationController _bounceController;

  // --- ÂM THANH ---
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _initEffects();

    _bounceController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 100),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        double screenHeight = MediaQuery.of(context).size.height;
        setState(() {
          basketX = (MediaQuery.of(context).size.width / 2) - (basketWidth / 2);
          // Định nghĩa vùng hứng: từ cách đáy 140px đến cách đáy 90px
          catchZoneTop = screenHeight - 140;
          catchZoneBottom = screenHeight - 90;
        });
      }
    });

    startGame();
  }

  void _initEffects() {
    _controllerLeft = ConfettiController(duration: const Duration(seconds: 3));
    _controllerRight = ConfettiController(duration: const Duration(seconds: 3));
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = (prefs.getInt('highScore') ?? 0);
    });
  }

  void startGame() {
    gameTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        if (timeLeft > 0) {
          setState(() {
            timeLeft--;
            if (timeLeft % 5 == 0 && timeLeft != 0) speedMultiplier += 0.2;
          });
        } else {
          _handleEndGame();
        }
      }
    });

    dropTimer = Timer.periodic(Duration(milliseconds: 30), (timer) {
      if (mounted) updateGame();
    });
  }

  void updateGame() {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    setState(() {
      // Tạo vật phẩm mới
      if (random.nextInt(12) == 1) {
        items.add(LixiItem(
          x: random.nextDouble() * (screenWidth - 60),
          y: -100,
          speed: (baseSpeed + random.nextDouble() * 4.0) * speedMultiplier,
          type: _getRandomType(),
        ));
      }

      // Di chuyển và kiểm tra va chạm
      for (int i = items.length - 1; i >= 0; i--) {
        var item = items[i];
        item.y += item.speed;
        item.sway += 0.1;

        double itemRealX = item.x + (sin(item.sway) * 15);

        // KIỂM TRA HỨNG - VÙNG VA CHẠM ĐÃ ĐƯỢC CẢI THIỆN
        bool isInCatchZoneY = item.y + 60 >= catchZoneTop && item.y <= catchZoneBottom;
        bool isInCatchZoneX = itemRealX + 40 >= basketX && itemRealX <= basketX + basketWidth;

        if (isInCatchZoneY && isInCatchZoneX) {
          _onItemCaught(item, itemRealX);
          items.removeAt(i);
          continue;
        }

        // Xóa nếu rơi quá đáy
        if (item.y > screenHeight) {
          items.removeAt(i);
        }
      }

      // Cập nhật hiệu ứng nổ
      for (int i = catchEffects.length - 1; i >= 0; i--) {
        catchEffects[i].life--;
        if (catchEffects[i].life <= 0) {
          catchEffects.removeAt(i);
        }
      }
    });
  }

  String _getRandomType() {
    int r = random.nextInt(100);
    if (r < 55) return "RED";
    if (r < 75) return "GOLD";
    if (r < 85) return "BOMB";
    if (r < 93) return "TIME_UP";
    return "TIME_DOWN";
  }

  void _onItemCaught(LixiItem item, double catchX) {
    // RUNG THÚNG KHI HỨNG ĐƯỢC
    _shakeBasket();

    // THÊM HIỆU ỨNG NỔ TẠI VỊ TRÍ HỨNG
    setState(() {
      catchEffects.add(CatchEffect(x: catchX, life: 10));
    });

    // CỘNG ĐIỂM VÀ HIỆU ỨNG
    setState(() {
      if (item.type == "RED") {
        score += 10;
        _playSound('collect.mp3');
        _bounceController.forward().then((_) => _bounceController.reverse());
      }
      else if (item.type == "GOLD") {
        score += 50;
        _playSound('gold.mp3');
        _bounceController.forward().then((_) => _bounceController.reverse());
        // Hiệu ứng pháo hoa nhỏ khi hứng vàng
        _controllerLeft.play();
      }
      else if (item.type == "BOMB") {
        score = max(0, score - 100);
        _playSound('boom.mp3');
        // Rung mạnh hơn khi trúng bom
        _shakeBasket(strong: true);
      }
      else if (item.type == "TIME_UP") {
        timeLeft += 5;
        _playSound('bonus.mp3');
      }
      else if (item.type == "TIME_DOWN") {
        timeLeft = max(0, timeLeft - 5);
        _playSound('penalty.mp3');
      }
    });
  }

  void _shakeBasket({bool strong = false}) {
    setState(() {
      basketShake = strong ? 8.0 : 4.0;
    });
    shakeTimer?.cancel();
    shakeTimer = Timer.periodic(Duration(milliseconds: 30), (timer) {
      if (mounted) {
        setState(() {
          basketShake = basketShake * 0.7;
          if (basketShake < 0.5) {
            basketShake = 0;
            timer.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _handleEndGame() async {
    gameTimer?.cancel();
    dropTimer?.cancel();
    shakeTimer?.cancel();

    final prefs = await SharedPreferences.getInstance();
    int totalScore = prefs.getInt('total_score') ?? 0;
    await prefs.setInt('total_score', totalScore + score);

    if (score > highScore) {
      await prefs.setInt('highScore', score);
      setState(() { isNewRecord = true; highScore = score; });
      _controllerLeft.play();
      _controllerRight.play();
      _playSound('victory.mp3');
    }

    _showResultDialog();
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF8B0000),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Color(0xFFFFD700), width: 3)
        ),
        title: Text(
            isNewRecord ? "KỶ LỤC MỚI! 🎉" : "KẾT THÚC",
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Điểm của bạn: $score", style: TextStyle(color: Colors.white, fontSize: 22)),
            SizedBox(height: 10),
            Text("Kỷ lục hiện tại: $highScore", style: TextStyle(color: Colors.white70, fontSize: 16)),
            SizedBox(height: 15),
            Text("🎊 Chúc mừng năm mới! 🎊", style: TextStyle(color: Color(0xFFFFD700), fontSize: 14)),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFFD700),
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text(
                  "QUAY LẠI",
                  style: TextStyle(color: Color(0xFF8B0000), fontWeight: FontWeight.bold, fontSize: 18)
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _playSound(String fileName) async {
    try {
      await _audioPlayer.play(AssetSource('audio/$fileName'));
    } catch (e) {
      print("Sound error: $e");
    }
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    dropTimer?.cancel();
    shakeTimer?.cancel();
    _controllerLeft.dispose();
    _controllerRight.dispose();
    _bounceController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: GestureDetector(
        onHorizontalDragUpdate: (details) {
          setState(() {
            basketX += details.delta.dx;
            basketX = basketX.clamp(0.0, screenWidth - basketWidth);
          });
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFD32F2F), Color(0xFF700000)]
              )
          ),
          child: Stack(
            children: [
              // Header
              _buildHeader(),

              // Vật phẩm rơi
              ...items.map((item) => Positioned(
                left: item.x + (sin(item.sway) * 15),
                top: item.y,
                child: AnimatedOpacity(
                  opacity: 1.0,
                  duration: Duration(milliseconds: 100),
                  child: _buildItemWidget(item.type),
                ),
              )).toList(),

              // Hiệu ứng nổ khi hứng
              ...catchEffects.map((effect) => Positioned(
                left: effect.x - 20,
                top: catchZoneTop - 20,
                child: Opacity(
                  opacity: effect.life / 10,
                  child: Container(
                    width: 60,
                    height: 60,
                    child: Center(
                      child: Text(
                        "✨",
                        style: TextStyle(fontSize: 30 + (10 - effect.life) * 1.5),
                      ),
                    ),
                  ),
                ),
              )).toList(),

              // Cái thúng hứng (có hiệu ứng rung và nảy)
              Positioned(
                bottom: 80,
                left: basketX + (Random().nextDouble() - 0.5) * basketShake,
                child: AnimatedBuilder(
                  animation: _bounceController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1 + _bounceController.value * 0.1,
                      child: _buildBasketWidget(),
                    );
                  },
                ),
              ),

              // Hướng dẫn kéo thúng
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.swap_horiz, color: Colors.white70, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "KÉO NGANG ĐỂ HỨNG LÌ XÌ",
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Hiệu ứng pháo hoa
              _buildConfettiWidgets(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasketWidget() {
    return Container(
      width: basketWidth,
      height: basketHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.amber[700]!, Colors.amber[900]!],
        ),
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15)
        ),
        border: Border.all(color: Colors.yellow[300]!, width: 3),
        boxShadow: [
          BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4)),
          BoxShadow(color: Colors.yellow.withOpacity(0.3), blurRadius: 10, spreadRadius: 2),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.card_giftcard, color: Colors.yellow[200], size: 32),
          Text(
            "HỨNG LÌ XÌ",
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, shadows: [
              Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(1, 1)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildInfoCol("ĐIỂM", "$score", Color(0xFFFFD700)),
            _buildInfoCol("🎊 THỜI GIAN 🎊", "${timeLeft}s", Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCol(String label, String val, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: [
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
        Text(val, style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildItemWidget(String type) {
    Map<String, dynamic> config = {
      "RED": {"icon": "🧧", "bg": Colors.redAccent, "label": "LÌ XÌ"},
      "GOLD": {"icon": "🪙", "bg": Colors.amber, "label": "VÀNG"},
      "BOMB": {"icon": "💣", "bg": Colors.black87, "label": "BOM"},
      "TIME_UP": {"icon": "⏰", "bg": Colors.green, "label": "+5s"},
      "TIME_DOWN": {"icon": "💀", "bg": Colors.blueGrey, "label": "-5s"},
    };

    var cfg = config[type] ?? config["RED"];

    return Container(
      width: 55,
      height: 80,
      decoration: BoxDecoration(
        color: cfg!["bg"],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 5, offset: Offset(0, 2))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(cfg["icon"], style: TextStyle(fontSize: 32)),
          SizedBox(height: 4),
          Text(
            cfg["label"],
            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildConfettiWidgets() {
    return Stack(children: [
      Align(
          alignment: Alignment.centerLeft,
          child: ConfettiWidget(
            confettiController: _controllerLeft,
            blastDirection: 0,
            gravity: 0.2,
            colors: [Colors.red, Colors.yellow, Colors.green, Colors.orange],
          )
      ),
      Align(
          alignment: Alignment.centerRight,
          child: ConfettiWidget(
            confettiController: _controllerRight,
            blastDirection: pi,
            gravity: 0.2,
            colors: [Colors.red, Colors.yellow, Colors.green, Colors.orange],
          )
      ),
    ]);
  }
}

// Lớp LixiItem (giữ nguyên)
class LixiItem {
  double x, y, speed, sway;
  String type;
  LixiItem({required this.x, required this.y, required this.speed, this.sway = 0, required this.type});
}

// Lớp hiệu ứng nổ khi hứng
class CatchEffect {
  double x;
  int life;
  CatchEffect({required this.x, required this.life});
}