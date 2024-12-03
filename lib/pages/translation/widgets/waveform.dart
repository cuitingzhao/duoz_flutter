import 'dart:math';
import 'package:flutter/material.dart';

class WaveformPainter extends CustomPainter {
  final double amplitude;
  final Color color;
  final double frequency;
  final double phase;

  WaveformPainter({
    this.amplitude = 0.1,
    this.color = Colors.blue,
    this.frequency = 1.0,
    this.phase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final path = Path();
    final width = size.width;
    final height = size.height;
    final mid = height / 2;

    // 计算实际振幅（将高度的 1/4 作为最大振幅）
    final maxAmplitude = height / 12;
    final actualAmplitude = maxAmplitude * amplitude;

    var x = 0.0;
    path.moveTo(0, mid);

    while (x < width) {
      final normalizedX = x / width * 2 * pi;
      final y = mid + sin(normalizedX * frequency + phase) * actualAmplitude;
      path.lineTo(x, y);
      x += 1;
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
    this.amplitude = 0.1,
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
        amplitude: widget.amplitude * 0.5,
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
