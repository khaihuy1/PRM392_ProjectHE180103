import 'package:flutter/material.dart';
import 'game_play_page.dart';
import 'intellectual_spin_page.dart';
import 'rules_page.dart';
import 'case_opening_page.dart';

class StartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // LỚP 1: ẢNH NỀN (img.png)
          Positioned.fill(
            child: Image.asset(
              'assets/images/img.png', // Nhớ kiểm tra file này trong thư mục assets nhé
              fit: BoxFit.cover, // Phủ kín toàn bộ màn hình Reno 5
            ),
          ),

          // LỚP 2: LỚP PHỦ MÀU (Overlay) - Giúp chữ và nút dễ nhìn hơn
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3), // Phía trên hơi tối
                    Colors.black.withOpacity(0.6), // Phía dưới tối hơn để hiện nút
                  ],
                ),
              ),
            ),
          ),

          // LỚP 3: NỘI DUNG CHÍNH (LOGO & BUTTONS)
          Center(
            child: SingleChildScrollView( // Chống tràn màn hình khi hiện bàn phím hoặc máy nhỏ
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo & Tiêu đề với hiệu ứng Glow
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.yellow.withOpacity(0.5), blurRadius: 40, spreadRadius: 10)
                      ],
                    ),
                    child: Icon(Icons.auto_awesome, size: 100, color: Colors.yellow),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "GAME TẾT KHAI HUY",
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.yellow[600],
                      letterSpacing: 2,
                      shadows: [
                        Shadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 6)
                      ],
                    ),
                  ),

                  SizedBox(height: 50),

                  // Nút: HỨNG LÌ XÌ
                  _buildGameButton(
                    context,
                    "HỨNG LÌ XÌ",
                    Icons.redeem,
                        () => Navigator.push(context, MaterialPageRoute(builder: (context) => GamePlayPage())),
                    Colors.yellow[700]!,
                    Colors.red[900]!,
                  ),

                  SizedBox(height: 15),

                  // Nút: MỞ HÒM MAY MẮN
                  _buildGameButton(
                    context,
                    "MỞ HÒM MAY MẮN",
                    Icons.inventory_2,
                        () => Navigator.push(context, MaterialPageRoute(builder: (context) => CaseOpeningPage())),
                    Colors.purple[700]!,
                    Colors.white,
                  ),

                  SizedBox(height: 15),

                  // Nút: VÒNG QUAY TRÍ TUỆ
                  _buildGameButton(
                    context,
                    "VÒNG QUAY TRÍ TUỆ",
                    Icons.auto_fix_high,
                        () => Navigator.push(context, MaterialPageRoute(builder: (context) => IntellectualSpinPage())),
                    Colors.orange[800]!,
                    Colors.white,
                  ),

                  SizedBox(height: 40),

                  // Nút: LUẬT CHƠI (Làm mờ hơn để phân biệt với nút chơi)
                  _buildGameButton(
                    context,
                    "LUẬT CHƠI",
                    Icons.help_outline,
                        () => Navigator.push(context, MaterialPageRoute(builder: (context) => RulesPage())),
                    Colors.white.withOpacity(0.3),
                    Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Hàm tạo nút bấm dùng chung (Custom Button)
  Widget _buildGameButton(BuildContext context, String title, IconData icon, VoidCallback onTap, Color bgColor, Color textColor) {
    return Container(
      width: 280,
      height: 65,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 28),
        label: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 0, // Dùng Shadow của Container cho đẹp hơn
        ),
        onPressed: onTap,
      ),
    );
  }
}