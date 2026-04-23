import 'package:flutter/material.dart';

class AIChatInputBar extends StatefulWidget {
  final bool isStreaming;
  final void Function(String text) onSend;
  final VoidCallback onStop;
  final String hintText;

  const AIChatInputBar({
    super.key,
    required this.isStreaming,
    required this.onSend,
    required this.onStop,
    this.hintText = '继续追问…',
  });

  @override
  State<AIChatInputBar> createState() => _AIChatInputBarState();
}

class _AIChatInputBarState extends State<AIChatInputBar> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final nowHas = _controller.text.trim().isNotEmpty;
      if (nowHas != _hasText) setState(() => _hasText = nowHas);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 140),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            if (widget.isStreaming)
              IconButton(
                key: const Key('stop_btn'),
                icon: const Icon(Icons.stop_circle_outlined),
                tooltip: '停止生成',
                color: Colors.redAccent,
                onPressed: widget.onStop,
              )
            else
              IconButton(
                key: const Key('send_btn'),
                icon: const Icon(Icons.send_rounded),
                tooltip: '发送',
                color: Theme.of(context).primaryColor,
                onPressed: _hasText ? _handleSend : null,
              ),
          ],
        ),
      ),
    );
  }
}
