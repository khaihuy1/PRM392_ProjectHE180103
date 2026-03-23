import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';

class IntellectualSpinPage extends StatefulWidget {
  @override
  _IntellectualSpinPageState createState() => _IntellectualSpinPageState();
}

class _IntellectualSpinPageState extends State<IntellectualSpinPage> {
  int totalScore = 500;
  int highScore = 0;
  int betScore = 0;
  int currentQuestionIndex = 0;
  int userSlots = 1;
  bool isAnswering = true;
  bool _isSpinning = false;
  int _lastResult = 0;

  int secondsRemaining = 60;
  int turnsLeft = 5;
  Timer? _gameTimer;

  final StreamController<int> selected = StreamController<int>.broadcast();
  TextEditingController _betController = TextEditingController();

  // --- NGÂN HÀNG 20 CÂU HỎI TẾT HÀI HƯỚC ---
  final List<Map<String, dynamic>> questionBank = [
    {"q": "Tết này không giống Tết xưa, không còn được nhận...?", "a": ["Lì xì", "Lời phê", "Lương hưu", "Vé phạt"], "correct": 0},
    {"q": "Bánh chưng có hình gì?", "a": ["Hình tròn", "Hình vuông", "Hình tam giác", "Hình thoi"], "correct": 1},
    {"q": "Trái gì Tết nào cũng 'khổ'?", "a": ["Khổ qua", "Dưa hấu", "Đu đủ", "Xoài"], "correct": 0},
    {"q": "Con gì đến Tết là ai cũng muốn 'né'?", "a": ["Con giáp", "Con nợ", "Con lân", "Con cháu"], "correct": 1},
    {"q": "Mùng 1 Tết, người ta thường làm gì để lấy hên?", "a": ["Quét nhà", "Đi chùa", "Cãi lộn", "Ngủ nướng"], "correct": 1},
    {"q": "Thịt mỡ dưa hành, câu tiếp theo là gì?", "a": ["Bánh chưng xanh", "Câu đối đỏ", "Rượu bia nhiều", "Lì xì dày"], "correct": 1},
    {"q": "Trong mâm ngũ quả, trái nào tượng trưng cho sự 'cầu'?", "a": ["Dừa", "Sung", "Mãng cầu", "Xoài"], "correct": 2},
    {"q": "Lì xì màu gì là phổ biến nhất?", "a": ["Xanh lá", "Vàng tươi", "Đỏ thắm", "Tím lịm"], "correct": 2},
    {"q": "Hoa gì đặc trưng cho Tết miền Bắc?", "a": ["Hoa Mai", "Hoa Cúc", "Hoa Đào", "Hoa Vạn Thọ"], "correct": 2},
    {"q": "Tết 2026 là năm con gì?", "a": ["Bính Ngọ (Ngựa)", "Ất Tỵ (Rắn)", "Đinh Mùi (Dê)", "Canh Thân (Khỉ)"], "correct": 0},
    {"q": "Giao thừa là thời khắc mấy giờ?", "a": ["11 giờ đêm", "00 giờ sáng", "1 giờ sáng", "21 giờ tối"], "correct": 1},
    {"q": "Tục lệ 'Xông đất' diễn ra khi nào?", "a": ["Sau giao thừa", "Sáng mùng 2", "Chiều 30", "Rằm tháng Giêng"], "correct": 0},
    {"q": "Loại quả nào 'vừa mập vừa tròn' trong mâm ngũ quả?", "a": ["Chuối", "Bưởi", "Quất", "Thanh long"], "correct": 1},
    {"q": "Hoạt động nào 'đốt tiền' nhiều nhất ngày Tết?", "a": ["Mua sắm", "Lì xì", "Đánh bài", "Tất cả đúng"], "correct": 3},
    {"q": "Ông Táo cưỡi con gì về trời?", "a": ["Con rồng", "Con ngựa", "Con cá chép", "Con hổ"], "correct": 2},
    {"q": "Ngày Tết 'vàng' nhất là hoa gì?", "a": ["Hoa Hồng", "Hoa Mai", "Hoa Ly", "Hoa Lan"], "correct": 1},
    {"q": "Món ăn nào giải ngán cực tốt sau Tết?", "a": ["Thịt kho hột vịt", "Bánh tét", "Gỏi gà", "Canh chua"], "correct": 3},
    {"q": "Câu chúc Tết 'quốc dân' là gì?", "a": ["Happy New Year", "Chúc mừng năm mới", "Vạn sự như ý", "Cả B và C"], "correct": 3},
    {"q": "Đồ vật gì dùng để trang trí cây đào, cây mai?", "a": ["Bóng đèn", "Bao lì xì nhỏ", "Dây kim tuyến", "Tất cả đúng"], "correct": 3},
    {"q": "Ai là người mang quà đến cho trẻ em đêm Noel (Tết Tây)?", "a": ["Ông Táo", "Ông già Noel", "Ông nội", "Ông hàng xóm"], "correct": 1},
  ];

  List<Map<String, dynamic>> currentSessionQuestions = [];

  @override
  void initState() {
    super.initState();
    selected.add(0);
    _loadHighScore();
    _startCountdown();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showBetDialog());
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    selected.close();
    _betController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _gameTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (secondsRemaining > 0) {
        if (mounted) setState(() => secondsRemaining--);
      } else {
        _gameTimer?.cancel();
        _endGame("Hết thời gian 1 phút rồi!");
      }
    });
  }

  _loadHighScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() => highScore = prefs.getInt('high_score') ?? 0);
  }

  _saveHighScore() async {
    if (totalScore > highScore) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('high_score', totalScore);
      setState(() => highScore = totalScore);
    }
  }

  void _endGame(String reason) async {
    await _saveHighScore();
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("KẾT THÚC TẾT"),
        content: Text("$reason\nĐiểm: $totalScore\nKỷ lục: $highScore"),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
            child: Text("THOÁT"),
          )
        ],
      ),
    );
  }

  void _showBetDialog() {
    if (turnsLeft <= 0) { _endGame("Hết lượt lì xì rồi!"); return; }
    _betController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        // Dùng StatefulBuilder để Timer chạy được ngay trong Dialog
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Lắng nghe Timer từ bên ngoài
            Timer.periodic(Duration(seconds: 1), (t) {
              if (mounted) setDialogState(() {});
              if (secondsRemaining <= 0) t.cancel();
            });

            return AlertDialog(
              title: Text("LƯỢT $turnsLeft/5 - 🕒 Còn ${secondsRemaining}s"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Nhập điểm cược (Số dư: $totalScore)"),
                    SizedBox(height: 10),
                    TextField(
                      controller: _betController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(border: OutlineInputBorder(), hintText: "Ví dụ: 50"),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await _saveHighScore();
                    Navigator.pop(context);
                    Navigator.popUntil(context, (r) => r.isFirst);
                  },
                  child: Text("HỦY (THOÁT)"),
                ),
                ElevatedButton(
                  onPressed: () {
                    int? val = int.tryParse(_betController.text);
                    if (val != null && val > 0 && val <= totalScore) {
                      setState(() { betScore = val; _prepareQuestions(); });
                      Navigator.pop(context);
                    }
                  },
                  child: Text("XÁC NHẬN"),
                )
              ],
            );
          },
        );
      },
    );
  }

  void _prepareQuestions() {
    setState(() {
      currentQuestionIndex = 0;
      userSlots = 1;
      isAnswering = true;
      currentSessionQuestions = (List.from(questionBank)..shuffle())
          .cast<Map<String, dynamic>>()
          .take(3)
          .toList();
    });
  }

  void _showFinalResult(int winIdx) {
    bool won = winIdx < userSlots;
    setState(() {
      if (won) totalScore += betScore; else totalScore -= betScore;
      turnsLeft--;
      _saveHighScore();
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(won ? "THẮNG LỚN! 🎉" : "MẤT LÌ XÌ RỒI! 🧧"),
        content: Text("Lượt còn lại: $turnsLeft\nĐiểm hiện tại: $totalScore"),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (turnsLeft > 0 && totalScore > 0 && secondsRemaining > 0) {
                _showBetDialog();
              } else {
                _endGame(totalScore <= 0 ? "Cháy túi rồi!" : "Kết thúc!");
              }
            },
            child: Text("TIẾP TỤC"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.red[900],
        title: Text("🕒 ${secondsRemaining}s | 🔄 $turnsLeft | 🏆 $highScore"),
      ),
      body: isAnswering ? _buildQuestionUI() : _buildSpinUI(),
    );
  }

  Widget _buildQuestionUI() {
    if (currentSessionQuestions.isEmpty) return Container();
    var q = currentSessionQuestions[currentQuestionIndex];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text("Câu: ${currentQuestionIndex + 1}/3", style: TextStyle(fontSize: 18, color: Colors.red[900])),
          Spacer(),
          Text(q['q'], textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Spacer(),
          ...List.generate(4, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[100], foregroundColor: Colors.black),
                onPressed: () {
                  setState(() {
                    if (i == q['correct']) {
                      userSlots++;
                      if (currentQuestionIndex < 2) currentQuestionIndex++; else isAnswering = false;
                    } else { isAnswering = false; }
                  });
                },
                child: Text(q['a'][i], style: TextStyle(fontSize: 16)),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSpinUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 320,
          child: FortuneWheel(
            selected: selected.stream,
            animateFirst: false,
            onFocusItemChanged: (v) => _lastResult = v,
            items: [
              for (int i = 0; i < 5; i++)
                FortuneItem(
                  child: Text(i < userSlots ? "LÌ XÌ" : "MẤT TRẮNG", style: TextStyle(fontWeight: FontWeight.bold)),
                  style: FortuneItemStyle(
                    color: i < userSlots ? Colors.red : Colors.yellow[700]!,
                    borderColor: Colors.white,
                    borderWidth: 3,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 30),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900], padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
          onPressed: _isSpinning ? null : () {
            setState(() => _isSpinning = true);
            final r = Random().nextInt(5);
            selected.add(r);
            Future.delayed(Duration(seconds: 4), () {
              if (mounted) {
                _showFinalResult(_lastResult);
                setState(() => _isSpinning = false);
              }
            });
          },
          child: Text(_isSpinning ? "ĐANG LẮC..." : "QUAY LẤY HÊN", style: TextStyle(color: Colors.white, fontSize: 18)),
        )
      ],
    );
  }
}