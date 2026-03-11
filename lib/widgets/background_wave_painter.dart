import 'package:flutter/material.dart';

class BackgroundWavePainter extends CustomPainter {
  final Color waveColor; // 🔥 We can now pass the color in!

  BackgroundWavePainter({required this.waveColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = waveColor..style = PaintingStyle.fill;
    
    final path1 = Path();
    path1.moveTo(0, size.height * 0.6);
    path1.quadraticBezierTo(size.width * 0.2, size.height * 0.4, size.width, size.height * 0.15);
    path1.lineTo(size.width, 0);
    path1.lineTo(0, 0);
    path1.close();
    canvas.drawPath(path1, paint);
    
    final path2 = Path();
    path2.moveTo(0, size.height);
    path2.quadraticBezierTo(size.width * 0.25, size.height * 0.9, size.width, size.height * 0.7);
    path2.lineTo(size.width, size.height);
    path2.close();
    canvas.drawPath(path2, paint);
  }
  
  // Set to true so it redraws when you flip the switch!
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true; 
}