import 'package:flutter/material.dart';
import 'game_play_page.dart';
import 'intellectual_spin_page.dart';
import 'rules_page.dart'; // Trang luật chơi 2 Tab của bạn

class StartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red[900]!, Colors.orange[800]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. Logo & Tiêu đề
            Icon(Icons.auto_awesome, size: 100, color: Colors.yellow),
            Text(
              "GAME TẾT KHAI HUY",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.yellow,
                letterSpacing: 2,
                shadows: [
                  Shadow(color: Colors.black45, offset: Offset(2, 2), blurRadius: 4)
                ],
              ),
            ),

            SizedBox(height: 50),

            // 2. Nút chọn trò chơi 1: HỨNG LÌ XÌ
            _buildGameButton(
              context,
              "HỨNG LÌ XÌ",
              Icons.redeem,
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => GamePlayPage())),
              Colors.yellow[700]!,
              Colors.red[900]!,
            ),

            SizedBox(height: 20),

            // 3. Nút chọn trò chơi 2: VÒNG QUAY TRÍ TUỆ
            _buildGameButton(
              context,
              "VÒNG QUAY TRÍ TUỆ",
              Icons.auto_fix_high,
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => IntellectualSpinPage())),
              Colors.yellow[700]!,
              Colors.red[900]!,
            ),

            SizedBox(height: 40), // Khoảng cách giữa nút Game và nút Luật chơi

            // 4. NÚT ĐẾN TRANG LUẬT CHƠI (Nằm ngay bên dưới)
            _buildGameButton(
              context,
              "LUẬT CHƠI",
              Icons.help_outline,
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => RulesPage())),
              Colors.white.withOpacity(0.2), // Màu khác biệt để phân biệt với nút Game
              Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  // Widget tạo nút bấm linh hoạt
  Widget _buildGameButton(BuildContext context, String title, IconData icon, VoidCallback onTap, Color bgColor, Color textColor) {
    return SizedBox(
      width: 280,
      height: 70,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 30),
        label: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          side: bgColor == Colors.white.withOpacity(0.2) ? BorderSide(color: Colors.white) : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 10,
        ),
        onPressed: onTap,
      ),
    );
  }
}