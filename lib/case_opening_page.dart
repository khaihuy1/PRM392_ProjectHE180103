import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CaseOpeningPage extends StatefulWidget {
  @override
  _CaseOpeningPageState createState() => _CaseOpeningPageState();
}

class _CaseOpeningPageState extends State<CaseOpeningPage> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  int totalScore = 500;
  bool isOpening = false;

  // Trạng thái kết quả
  String rewardName = "Nhấn để thử vận may!";
  Color rewardColor = Colors.grey;
  int rewardValue = 0;

  // Cấu hình dải băng (Thay đổi ở đây để chỉnh độ to nhỏ của ô)
  final double itemWidth = 140;
  final double itemMargin = 10;

  // Xử lý hiệu ứng Hào quang (Glow)
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  // DANH SÁCH VẬT PHẨM (Icon tạm thời để không bị lỗi thiếu ảnh)
  final List<Map<String, dynamic>> items = [
    {"name": "Hạt Dưa", "val": 10, "color": Colors.grey, "icon": Icons.eco, "chance": 60},
    {"name": "Lì Xì Xanh", "val": 100, "color": Colors.blue, "icon": Icons.moped, "chance": 25},
    {"name": "Bánh Chưng", "val": 500, "color": Colors.purple, "icon": Icons.view_in_ar, "chance": 10},
    {"name": "MÈO VÀNG", "val": 2000, "color": Colors.orange, "icon": Icons.pets, "chance": 5},
  ];

  @override
  void initState() {
    super.initState();
    _loadScore();

    // Khởi tạo Animation ngay tại đây để tránh lỗi LateInitializationError
    _glowController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 800)
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 20.0).animate(
        CurvedAnimation(parent: _glowController, curve: Curves.easeInOut)
    );

    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  _loadScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => totalScore = prefs.getInt('total_score') ?? 500);
  }

  _saveScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('total_score', totalScore);
  }

  // Logic chọn quà theo tỉ lệ phần trăm
  Map<String, dynamic> _pickReward() {
    int r = Random().nextInt(100);
    if (r < 60) return items[0];
    if (r < 85) return items[1];
    if (r < 95) return items[2];
    return items[3];
  }

  Future<void> _startOpening() async {
    if (isOpening || totalScore < 50) return;

    setState(() {
      isOpening = true;
      totalScore -= 50;
      rewardName = "Đang khui hòm...";
      rewardValue = 0;
    });

    // Nhảy dải băng về đầu để bắt đầu vòng quay mới
    _scrollController.jumpTo(0);
    await Future.delayed(Duration(milliseconds: 100));

    final reward = _pickReward();
    final int rewardIndexInList = items.indexOf(reward);

    // Tính toán quãng đường chạy (8 vòng + vị trí món quà)
    int rounds = 8;
    double singleItemFullWidth = itemWidth + (itemMargin * 2);
    double listFullWidth = items.length * singleItemFullWidth;

    // Căn chỉnh để món quà nằm đúng giữa kim chỉ
    double screenWidth = MediaQuery.of(context).size.width;
    double centerAdjustment = (screenWidth / 2) - (singleItemFullWidth / 2);

    double stopPosition = (rounds * listFullWidth) + (rewardIndexInList * singleItemFullWidth) - centerAdjustment;

    // HIỆU ỨNG XOAY KIỂU CS:GO
    await _scrollController.animateTo(
      stopPosition,
      duration: Duration(seconds: 5),
      curve: Curves.easeOutQuart,
    );

    setState(() {
      isOpening = false;
      rewardName = "NHẬN ĐƯỢC: ${reward['name']}";
      rewardColor = reward['color'];
      rewardValue = reward['val'];
      totalScore += rewardValue;
    });

    _saveScore();
  }

  @override
  Widget build(BuildContext context) {
    // Tạo danh sách 100 món quà lặp lại để dải băng dài vô tận
    final displayList = List.generate(25, (index) => items).expand((x) => x).toList();

    return Scaffold(
      backgroundColor: Colors.red[50],
      appBar: AppBar(
        title: Text("KHO BÁU TẾT 2026"),
        backgroundColor: Colors.red[900],
        elevation: 0,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hiển thị điểm số hiện tại
          Text(
              "ĐIỂM: $totalScore",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.red[900])
          ),
          SizedBox(height: 40),

          // --- KHU VỰC DẢI BĂNG XOAY ---
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 170,
                decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.symmetric(horizontal: BorderSide(color: Colors.red[900]!, width: 3))
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: NeverScrollableScrollPhysics(), // Khóa vuốt tay
                  itemCount: displayList.length,
                  itemBuilder: (context, index) {
                    final item = displayList[index];
                    return Container(
                      width: itemWidth,
                      margin: EdgeInsets.symmetric(horizontal: itemMargin, vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: item['color'], width: 3),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(item['icon'], size: 45, color: item['color']),
                          SizedBox(height: 8),
                          Text(
                              item['name'],
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // VẠCH ĐỎ CHỈ ĐIỂM DỪNG (KIM CHỈ CS:GO)
              Container(width: 4, height: 190, color: Colors.red[900]),
              Positioned(top: 0, child: Icon(Icons.arrow_drop_down, color: Colors.red[900], size: 45)),
            ],
          ),

          SizedBox(height: 40),

          // --- KẾT QUẢ ---
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              bool isRare = rewardValue >= 500;
              return Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: (isRare && !isOpening)
                      ? [BoxShadow(color: rewardColor.withOpacity(0.4), blurRadius: _glowAnimation.value, spreadRadius: 5)]
                      : [],
                ),
                child: Column(
                  children: [
                    Text(
                        rewardName,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: rewardColor)
                    ),
                    if (rewardValue > 0 && !isOpening)
                      Text("+$rewardValue ĐIỂM", style: TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            },
          ),

          SizedBox(height: 50),

          // --- NÚT BẤM MỞ HÒM ---
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[900],
              padding: EdgeInsets.symmetric(horizontal: 60, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
              elevation: 10,
            ),
            onPressed: isOpening ? null : _startOpening,
            child: Text(
                "MỞ HÒM (50 ĐIỂM)",
                style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)
            ),
          ),
        ],
      ),
    );
  }
}