import 'package:flutter/material.dart';

class RulesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // DefaultTabController quản lý trạng thái của 2 tabs
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Hướng Dẫn Chơi", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Color(0xFFB71C1C),
          centerTitle: true,
          elevation: 0,
          // Thanh chọn Tab
          bottom: TabBar(
            indicatorColor: Color(0xFFFFD700),
            indicatorWeight: 4,
            tabs: [
              Tab(icon: Icon(Icons.redeem), text: "HỨNG LỘC"),
              Tab(icon: Icon(Icons.auto_fix_high), text: "VÒNG QUAY"),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFB71C1C), Color(0xFF8B0000)],
            ),
          ),
          child: TabBarView(
            children: [
              // Tab 1: Nội dung của Hứng Lộc
              _buildHungLocRules(context),
              // Tab 2: Nội dung của Vòng Quay
              _buildVongQuayRules(context),
            ],
          ),
        ),
      ),
    );
  }

  // --- TAB 1: HỨNG LỘC ---
  Widget _buildHungLocRules(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSectionTitle("VẬT PHẨM MAY MẮN"),
          _buildRuleCard("🧧", "Lì Xì Đỏ", "+10 Điểm", Colors.redAccent),
          _buildRuleCard("🪙", "Thỏi Vàng", "+50 Điểm (Siêu cấp)", Colors.amber),
          _buildRuleCard("⏳", "Đồng Hồ Xanh", "+5 Giây thời gian", Colors.green),

          SizedBox(height: 10),
          _buildSectionTitle("VẬT PHẨM NGUY HIỂM"),
          _buildRuleCard("💣", "Bom Đen", "-100 Điểm (Cẩn thận!)", Colors.black87),
          _buildRuleCard("⌛", "Đồng Hồ Xám", "-5 Giây thời gian", Colors.blueGrey),

          SizedBox(height: 20),
          _buildUnderstandButton(context),
        ],
      ),
    );
  }

  // --- TAB 2: VÒNG QUAY ---
  Widget _buildVongQuayRules(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSectionTitle("THỬ THÁCH TRÍ TUỆ"),
          _buildRuleCard("💡", "Trả lời câu hỏi", "Trả lời đúng 3 câu để chiếm thêm 3 ô Thắng.", Colors.blueAccent),
          _buildRuleCard("❌", "Trả lời sai", "Dừng lại và quay với số ô hiện có.", Colors.red),

          SizedBox(height: 10),
          _buildSectionTitle("VẬN MAY QUYẾT ĐỊNH"),
          _buildRuleCard("🎡", "Ô Màu Cam", "Chúc mừng! Bạn được X2 số điểm.", Colors.orange),
          _buildRuleCard("🌑", "Ô Màu Xám", "Rất tiếc! Bạn bị trừ điểm cược.", Colors.grey),

          SizedBox(height: 30),
          Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
                color: Colors.yellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.yellow)
            ),
            child: Text(
              "Mẹo: Trả lời càng nhiều câu hỏi, tỉ lệ vào ô THẮNG trên vòng quay càng cao (lên đến 80%)!",
              style: TextStyle(color: Colors.yellow, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(height: 20),
          _buildUnderstandButton(context),
        ],
      ),
    );
  }

  // --- WIDGET DÙNG CHUNG ---
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Text(
        title,
        style: TextStyle(color: Color(0xFFFFD700), fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildRuleCard(String icon, String title, String effect, Color bgColor) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(child: Text(icon, style: TextStyle(fontSize: 28))),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text(effect, style: TextStyle(color: Color(0xFFFFD700), fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnderstandButton(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFFFFD700),
        foregroundColor: Color(0xFF8B0000),
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      onPressed: () => Navigator.pop(context),
      child: Text("ĐÃ HIỂU", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}