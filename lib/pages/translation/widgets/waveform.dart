import 'dart:math';
import 'package:flutter/material.dart';

class WaveformPainter extends CustomPainter {
  final double volume;
  final bool isRecording;
  final Color color;
  final double phase;
  static const double minAmplitude = 0.1;  // 最小波形振幅
  static const double maxAmplitude = 0.8;  // 最大波形振幅

  WaveformPainter({
    required this.volume,
    required this.isRecording,
    required this.color,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final width = size.width;
    final height = size.height;
    final centerY = height / 2;

    // 计算实际振幅（结合最小振幅）
    final amplitude = isRecording
        ? minAmplitude + (maxAmplitude - minAmplitude) * volume
        : minAmplitude;

    // 绘制波形
    final path = Path();
    path.moveTo(0, centerY);

    // 使用两个正弦波叠加，创造更自然的波形效果
    for (double x = 0; x < width; x++) {
      final normalizedX = (x / width) * 2 * pi;
      final frequency = isRecording ? 2.0 : 1.0;
      final y = centerY + 
               sin(normalizedX * frequency + phase) * (height * amplitude / 2) +
               sin(normalizedX * frequency * 1.5 + phase) * (height * amplitude / 4);
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.volume != volume || 
           oldDelegate.isRecording != isRecording ||
           oldDelegate.color != color ||
           oldDelegate.phase != phase;
  }
}

class WaveformWidget extends StatefulWidget {
  final double volume;
  final bool isRecording;
  final Color? color;

  const WaveformWidget({
    super.key,
    this.volume = 0.0,
    this.isRecording = false,
    this.color,
  });

  @override
  State<WaveformWidget> createState() => _WaveformWidgetState();
}

class _WaveformWidgetState extends State<WaveformWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _phase = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _controller.addListener(() {
      setState(() {
        _phase = _controller.value * 2 * pi;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: WaveformPainter(
        volume: widget.volume,
        isRecording: widget.isRecording,
        color: widget.color ?? Colors.blue,
        phase: _phase,
      ),
      child: const SizedBox(
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }
}
