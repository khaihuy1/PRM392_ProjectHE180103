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
  // (Các biến trạng thái giữ nguyên từ code cũ)
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

  // --- NGÂN HÀNG CÂU HỎI TẾT ---
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

  // (Các hàm dispose, startCountdown, load/saveHighScore, endGame, prepareQuestions, showFinalResult giữ nguyên)
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

  void _showBetDialog() {
    if (turnsLeft <= 0) { _endGame("Hết lượt lì xì rồi!"); return; }
    _betController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Timer.periodic(Duration(seconds: 1), (t) {
              if (mounted) setDialogState(() {});
              if (secondsRemaining <= 0) t.cancel();
            });

            return AlertDialog(
              backgroundColor: Colors.white.withOpacity(0.9), // Làm thoại hơi trong suốt
              title: Text("LƯỢT $turnsLeft/5 - 🕒 ${secondsRemaining}s", style: TextStyle(color: Colors.red[900])),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Nhập điểm cược (Số dư: $totalScore)", style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 15),
                    TextField(
                      controller: _betController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        hintText: "Ví dụ: 50",
                        filled: true,
                        fillColor: Colors.white,
                      ),
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
                  child: Text("HỦY (THOÁT)", style: TextStyle(color: Colors.grey[700])),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900]),
                  onPressed: () {
                    int? val = int.tryParse(_betController.text);
                    if (val != null && val > 0 && val <= totalScore) {
                      setState(() { betScore = val; _prepareQuestions(); });
                      Navigator.pop(context);
                    }
                  },
                  child: Text("XÁC NHẬN", style: TextStyle(color: Colors.white)),
                )
              ],
            );
          },
        );
      },
    );
  }

  // --- CẬP NHẬT HÀM BUILD ĐỂ CHÈN ẢNH NỀN ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white), // Đổi màu nút back
        backgroundColor: Colors.red[900],
        title: Text("🕒 ${secondsRemaining}s | 🏆 $highScore", style: TextStyle(color: Colors.white)),
      ),
      // Dùng Stack để chèn ảnh nền dưới cùng
      body: Stack(
        children: [
          // Lớp 1: Ảnh nền Tết
          Positioned.fill(
            child: Image.asset(
              'assets/images/tet_bg.png', // Thay ảnh Tết của Huy vào đây
              fit: BoxFit.cover, // Đảm bảo ảnh phủ kín màn hình Reno 5
            ),
          ),

          // Lớp 2: Giao diện game (Làm trong suốt nhẹ để hiện ảnh nền)
          Container(
            color: Colors.black.withOpacity(0.3), // Lớp phủ tối để dễ đọc chữ
            child: isAnswering ? _buildQuestionUI() : _buildSpinUI(),
          ),
        ],
      ),
    );
  }

  // --- LÀM UI CÂU HỎI TRONG SUỐT ---
  Widget _buildQuestionUI() {
    if (currentSessionQuestions.isEmpty) return Container();
    var q = currentSessionQuestions[currentQuestionIndex];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Tiêu đề câu hỏi
          Card(
            color: Colors.white.withOpacity(0.8), // Card trong suốt
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text("Câu: ${currentQuestionIndex + 1}/3", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red[900])),
            ),
          ),

          Spacer(),
          // Nội dung câu hỏi (Chữ trắng trên nền tối)
          Text(q['q'], textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 5)])),
          Spacer(),

          // Danh sách câu trả lời
          ...List.generate(4, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: SizedBox(
              width: double.infinity, height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[100]!.withOpacity(0.9), // Nút trong suốt
                  foregroundColor: Colors.black,
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () {
                  setState(() {
                    if (i == q['correct']) {
                      userSlots++;
                      if (currentQuestionIndex < 2) currentQuestionIndex++; else isAnswering = false;
                    } else { isAnswering = false; }
                  });
                },
                child: Text(q['a'][i], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          )),
        ],
      ),
    );
  }

  // --- LÀM UI VÒNG QUAY NỔI BẬT TRÊN NỀN ---
  Widget _buildSpinUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Thông tin lượt quay
        Card(
          color: Colors.white.withOpacity(0.8),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Text("Lượt: $turnsLeft/5 | Số ô LÌ XÌ: $userSlots", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red[900])),
          ),
        ),

        SizedBox(height: 30),

        // Vòng quay
        SizedBox(
          height: 320,
          child: FortuneWheel(
            selected: selected.stream,
            animateFirst: false,
            onFocusItemChanged: (v) => _lastResult = v,
            items: [
              for (int i = 0; i < 5; i++)
                FortuneItem(
                  child: Text(i < userSlots ? "LÌ XÌ" : "MẤT TRẮNG", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: FortuneItemStyle(
                    color: i < userSlots ? Colors.red[700]! : Colors.yellow[700]!,
                    borderColor: Colors.white,
                    borderWidth: 3,
                  ),
                ),
            ],
          ),
        ),

        SizedBox(height: 40),

        // Nút quay
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[900],
            padding: EdgeInsets.symmetric(horizontal: 50, vertical: 18),
            elevation: 10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
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
          child: Text(_isSpinning ? "ĐANG LẮC..." : "QUAY LẤY HÊN", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        )
      ],
    );
  }
}