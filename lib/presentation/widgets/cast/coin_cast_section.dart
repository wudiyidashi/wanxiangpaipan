import 'package:flutter/material.dart';
import 'cast_button.dart';
import 'yao_line_placeholder.dart';

class CoinCastSection extends StatelessWidget {
  const CoinCastSection({
    super.key,
    required this.onCast,
    this.isLoading = false,
  });

  final VoidCallback? onCast;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCoinsRow(),
        const SizedBox(height: 32),
        CastButton(
          onPressed: onCast,
          isLoading: isLoading,
        ),
        const SizedBox(height: 24),
        const YaoLinePlaceholder(),
      ],
    );
  }

  Widget _buildCoinsRow() {
    const rotations = [-15.0, 10.0, 25.0];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Transform.rotate(
            angle: rotations[index] * 3.14159 / 180,
            child: _buildCoin(),
          ),
        );
      }),
    );
  }

  Widget _buildCoin() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFFC9A84C), Color(0xFF8B6914)],
          center: Alignment(-0.3, -0.3),
          radius: 0.9,
        ),
        border: Border.all(
          color: const Color(0xFFA08030),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(2, 3),
          ),
          BoxShadow(
            color: const Color(0xFFC9A84C).withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(-1, -1),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: const Text(
        '通寶',
        style: TextStyle(
          color: Color(0xFF3D2800),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
