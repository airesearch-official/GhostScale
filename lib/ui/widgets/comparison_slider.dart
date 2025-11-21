import 'dart:io';
import 'package:flutter/material.dart';

class ComparisonSlider extends StatefulWidget {
  final File beforeImage;
  final File afterImage;

  const ComparisonSlider({
    Key? key,
    required this.beforeImage,
    required this.afterImage,
  }) : super(key: key);

  @override
  State<ComparisonSlider> createState() => _ComparisonSliderState();
}

class _ComparisonSliderState extends State<ComparisonSlider> {
  double _sliderValue = 0.5; // 0.0 to 1.0

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return Stack(
          children: [
            // 1. After Image (Background - Full)
            Positioned.fill(
              child: Image.file(widget.afterImage, fit: BoxFit.contain),
            ),

            // 2. Before Image (Foreground - Clipped)
            Positioned.fill(
              child: ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: _sliderValue,
                  child: SizedBox(
                    width: width,
                    height: height,
                    child: Image.file(widget.beforeImage, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),

            // 3. Slider Handle and Line
            Positioned(
              left: width * _sliderValue - 1.5, // Center the 3px line
              top: 0,
              bottom: 0,
              child: Container(width: 3, color: Colors.white),
            ),
            Positioned(
              left: width * _sliderValue - 15, // Center the 30px handle
              top: height / 2 - 15,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.compare_arrows,
                  size: 20,
                  color: Colors.black,
                ),
              ),
            ),

            // 4. Touch Detector
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _sliderValue = (details.localPosition.dx / width).clamp(
                      0.0,
                      1.0,
                    );
                  });
                },
                onTapDown: (details) {
                  setState(() {
                    _sliderValue = (details.localPosition.dx / width).clamp(
                      0.0,
                      1.0,
                    );
                  });
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
