import 'dart:math';
import 'package:flutter/material.dart';

class WaveformPainter extends CustomPainter {
  final double amplitude;
  final Color color;
  final double frequency;
  final double phase;

  WaveformPainter({
    this.amplitude = 1.0,
    this.color = Colors.blue,
    this.frequency = 1.0,
    this.phase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    var x = 0.0;
    final dx = size.width / 100;

    // 移动到起始点
    path.moveTo(0, size.height / 2);

    // 绘制波形
    while (x < size.width) {
      final y = size.height / 2 +
          sin((x * frequency / size.width * 2 * pi) + phase) * amplitude * size.height / 4;
      path.lineTo(x, y);
      x += dx;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.amplitude != amplitude ||
        oldDelegate.phase != phase ||
        oldDelegate.color != color ||
        oldDelegate.frequency != frequency;
  }
}

class WaveformWidget extends StatefulWidget {
  final double amplitude;
  final Color color;
  final bool isRecording;

  const WaveformWidget({
    super.key,
    this.amplitude = 1.0,
    this.color = Colors.blue,
    this.isRecording = false,
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
    )..addListener(() {
        setState(() {
          _phase = _controller.value * 2 * pi;
        });
      });

    if (widget.isRecording) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(WaveformWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording != oldWidget.isRecording) {
      if (widget.isRecording) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
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
        amplitude: widget.amplitude,
        color: widget.color,
        phase: _phase,
        frequency: widget.isRecording ? 2.0 : 1.0,
      ),
      child: const SizedBox(
        width: double.infinity,
        height: 100,
      ),
    );
  }
}
