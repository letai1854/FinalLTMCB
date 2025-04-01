import 'package:flutter/material.dart';

class Footer extends StatelessWidget {
  const Footer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[900],
      padding: EdgeInsets.symmetric(vertical: 30, horizontal: 50),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildFooterSection(
                  'CHĂM SÓC KHÁCH HÀNG',
                  [
                    'Trung tâm trợ giúp',
                    'Hướng dẫn mua hàng',
                    'Thanh toán',
                    'Vận chuyển'
                  ],
                ),
              ),
              Expanded(
                child: _buildFooterSection(
                  'VỀ CHÚNG TÔI',
                  [
                    'Giới thiệu',
                    'Tuyển dụng',
                    'Điều khoản',
                    'Chính sách bảo mật'
                  ],
                ),
              ),
              Expanded(
                child: _buildFooterSection(
                  'THANH TOÁN',
                  ['Visa', 'Mastercard', 'JCB', 'Tiền mặt'],
                ),
              ),
              Expanded(
                child: _buildFooterSection(
                  'THEO DÕI CHÚNG TÔI',
                  ['Facebook', 'Instagram', 'LinkedIn', 'Twitter'],
                ),
              ),
            ],
          ),
          Divider(color: Colors.grey[700], height: 50),
          Text(
            '© 2025 Shopi. Tất cả các quyền được bảo lưu.',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            height: 2,
          ),
        ),
        SizedBox(height: 20),
        ...items.map((item) => Padding(
              padding: EdgeInsets.symmetric(vertical: 5),
              child: Text(
                item,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            )),
      ],
    );
  }
}
