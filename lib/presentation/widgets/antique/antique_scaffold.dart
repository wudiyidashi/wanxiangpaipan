import 'package:flutter/material.dart';
import '../../../core/theme/antique_tokens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../cast/compass_background.dart';

/// 仿古风页面骨架：缃色渐变背景 + 可选罗盘装饰 + 可选大字水印。
///
/// 替代所有 [Scaffold]，统一页面背景与装饰层。
class AntiqueScaffold extends StatelessWidget {
  const AntiqueScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.showCompass = false,
    this.watermarkChar,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final bool showCompass;
  final String? watermarkChar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: Stack(
        children: [
          // 1. 缃色渐变背景
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: AntiqueTokens.pageGradient),
            ),
          ),
          // 2. 大字水印（如果提供）
          if (watermarkChar != null)
            Positioned(
              right: -40,
              bottom: 80,
              child: IgnorePointer(
                child: Text(
                  watermarkChar!,
                  style: AppTextStyles.decorText,
                ),
              ),
            ),
          // 3. 罗盘装饰（居中，如果启用）
          if (showCompass)
            const Positioned.fill(
              child: IgnorePointer(
                child: Center(child: CompassBackground()),
              ),
            ),
          // 4. 主内容（appBar 存在时用 SafeArea 避开 AppBar，依赖 Scaffold.extendBodyBehindAppBar 的 MediaQuery 调整）
          Positioned.fill(
            child: appBar != null
                ? SafeArea(
                    top: true,
                    bottom: false,
                    left: false,
                    right: false,
                    child: body,
                  )
                : body,
          ),
        ],
      ),
    );
  }
}
