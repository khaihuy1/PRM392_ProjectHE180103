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

class _GamePlayPageState extends State<GamePlayPage> {
  // --- BIẾN TRẠNG THÁI ---
  int score = 0;
  int highScore = 0;
  int timeLeft = 30;
  bool isNewRecord = false;
  List<LixiItem> items = [];
  Timer? gameTimer;
  Timer? dropTimer;
  final Random random = Random();

  // --- ĐỘ KHÓ & ÂM THANH ---
  double baseSpeed = 4.0;
  double speedMultiplier = 1.0;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // --- HIỆU ỨNG PHÁO HOA ---
  late ConfettiController _controllerLeft;
  late ConfettiController _controllerRight;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _initEffects();
    startGame();
  }

  void _initEffects() {
    _controllerLeft = ConfettiController(duration: const Duration(seconds: 3));
    _controllerRight = ConfettiController(duration: const Duration(seconds: 3));
  }

  // --- LOGIC LƯU ĐIỂM ---
  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = (prefs.getInt('highScore') ?? 0);
    });
  }

  Future<void> _checkAndSaveScore() async {
    if (score > highScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('highScore', score);
      setState(() {
        isNewRecord = true;
        highScore = score;
      });
      _controllerLeft.play();
      _controllerRight.play();
      _playSound('victory.mp3'); // m thanh khi phá kỷ lục
    }
  }

  // --- ĐIỀU KHIỂN GAME ---
  void startGame() {
    gameTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        if (timeLeft > 0) {
          setState(() {
            timeLeft--;
            // Tăng độ khó mỗi 5 giây
            if (timeLeft % 5 == 0 && timeLeft != 0) {
              speedMultiplier += 0.15;
            }
          });
          if (timeLeft <= 5) _playSound('tick.mp3');
        } else {
          _handleEndGame();
        }
      }
    });

    dropTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (mounted) updateGame();
    });
  }

  void updateGame() {
    setState(() {
      // Tốc độ tạo vật phẩm nhanh dần
      int spawnRate = (12 - (speedMultiplier * 2).toInt()).clamp(5, 12);

      if (random.nextInt(spawnRate) == 1) {
        String type;
        int r = random.nextInt(100);
        if (r < 55)
          type = "RED";
        else if (r < 70)
          type = "GOLD";
        else if (r < 82)
          type = "BOMB";
        else if (r < 91)
          type = "TIME_UP";
        else
          type = "TIME_DOWN";

        items.add(
          LixiItem(
            x: random.nextDouble() * MediaQuery.of(context).size.width * 0.8,
            y: -100,
            speed: (baseSpeed + random.nextDouble() * 5.0) * speedMultiplier,
            type: type,
          ),
        );
      }

      for (var item in items) {
        item.y += item.speed;
        item.sway += 0.15;
      }
      items.removeWhere((item) => item.y > MediaQuery.of(context).size.height);
    });
  }

  void _onItemTap(LixiItem item) {
    setState(() {
      if (item.type == "RED") {
        score += 10;
        _playSound('collect.mp3');
      } else if (item.type == "GOLD") {
        score += 50;
        _playSound('gold.mp3');
      } else if (item.type == "BOMB") {
        score = max(0, score - 100);
        _playSound('boom.mp3');
      } else if (item.type == "TIME_UP") {
        timeLeft += 5;
        _playSound('bonus.mp3');
      } else if (item.type == "TIME_DOWN") {
        timeLeft = max(0, timeLeft - 5);
        _playSound('penalty.mp3');
      }
      items.remove(item);
    });
  }

  void _handleEndGame() async {
    gameTimer?.cancel();
    dropTimer?.cancel();
    await _checkAndSaveScore();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF8B0000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Color(0xFFFFD700), width: 2),
        ),
        title: Text(
          isNewRecord ? "KỶ LỤC MỚI! 🎉" : "KẾT THÚC",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFFFD700),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Điểm của bạn: $score",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              "Kỷ lục hiện tại: $highScore",
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFFD700),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text(
                "QUAY LẠI",
                style: TextStyle(
                  color: Color(0xFF8B0000),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _playSound(String fileName) async {
    try {
      final player = AudioPlayer();
      await player.play(AssetSource('audio/$fileName'));
    } catch (e) {
      print("Lỗi phát âm thanh: $e");
    }
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    dropTimer?.cancel();
    _controllerLeft.dispose();
    _controllerRight.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFD32F2F), Color(0xFF700000)],
          ),
        ),
        child: Stack(
          children: [
            // Pháo hoa 2 bên
            Align(
              alignment: Alignment.centerLeft,
              child: ConfettiWidget(
                confettiController: _controllerLeft,
                blastDirection: 0,
                gravity: 0.3,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: ConfettiWidget(
                confettiController: _controllerRight,
                blastDirection: pi,
                gravity: 0.3,
              ),
            ),

            // Header thông tin
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoColumn("ĐIỂM", "$score", Color(0xFFFFD700)),
                    _buildInfoColumn("KỶ LỤC", "$highScore", Colors.white70),
                    _buildInfoColumn("THỜI GIAN", "${timeLeft}s", Colors.white),
                  ],
                ),
              ),
            ),

            // Các vật phẩm đang rơi
            ...items
                .map(
                  (item) => Positioned(
                    left: item.x + (sin(item.sway) * 25),
                    top: item.y,
                    child: GestureDetector(
                      onTapDown: (_) => _onItemTap(item),
                      child: _buildItemWidget(item.type),
                    ),
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, Color valueColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildItemWidget(String type) {
    String icon = "🧧";
    Color bg = Colors.redAccent;
    if (type == "GOLD") {
      icon = "🪙";
      bg = Colors.amber;
    } else if (type == "BOMB") {
      icon = "💣";
      bg = Colors.black;
    } else if (type == "TIME_UP") {
      icon = "⏳";
      bg = Colors.green;
    } else if (type == "TIME_DOWN") {
      icon = "⌛";
      bg = Colors.blueGrey;
    }

    return Container(
      width: 55,
      height: 80,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 5)],
      ),
      child: Center(child: Text(icon, style: TextStyle(fontSize: 30))),
    );
  }
}

class LixiItem {
  double x, y, speed, sway;
  String type;

  LixiItem({
    required this.x,
    required this.y,
    required this.speed,
    this.sway = 0,
    required this.type,
  });
}
