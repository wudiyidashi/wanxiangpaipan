import 'package:flutter/material.dart';

class CompassBackground extends StatelessWidget {
  const CompassBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildCircle(260, 0.15),
          _buildCircle(210, 0.10),
          _buildCircle(160, 0.07),
        ],
      ),
    );
  }

  Widget _buildCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Color.fromRGBO(183, 148, 82, opacity),
          width: 1.5,
        ),
      ),
    );
  }
}
