import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onTap;

  const CustomBottomNav({super.key, this.selectedIndex = 0, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      color: const Color(0xFF0B1220),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(
              Icons.home,
              color: selectedIndex == 0 ? Colors.blue : Colors.white,
            ),
            onPressed: () => onTap?.call(0),
          ),
          IconButton(
            icon: Icon(
              Icons.qr_code_scanner,
              color: selectedIndex == 1 ? Colors.blue : Colors.white,
            ),
            onPressed: () => onTap?.call(1),
          ),
          IconButton(
            icon: Icon(
              Icons.history,
              color: selectedIndex == 2 ? Colors.blue : Colors.white,
            ),
            onPressed: () => onTap?.call(2),
          ),
          IconButton(
            icon: Icon(
              Icons.settings,
              color: selectedIndex == 3 ? Colors.blue : Colors.white,
            ),
            onPressed: () => onTap?.call(3),
          ),
        ],
      ),
    );
  }
}
