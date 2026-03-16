import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:http/http.dart' as http;

import 'message.dart';

class AppColors {
  static const bg = Color(0xFFF5F7FB);
  static const glass = Color(0xFFFFFFFF);
  static const glassSoft = Color(0xFFF0F2F7);

  static const primary = Color(0xFF4F46E5);
  static const accent = Color(0xFF06B6D4);

  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const border = Color(0xFFE5E7EB);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<Message> _messages = [];

  bool _isLoading = false;
  late AnimationController _typingController;

  static const _apiKey =
      "YOUR_API_KEY";
  static const _apiUrl = "https://openrouter.ai/api/v1/chat/completions";

  @override
  void initState() {
    super.initState();

    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _messages.add(
      Message(
        content: "Hi 👋 I’m Saarthi AI. How can I help you today?",
        isUser: false,
        timestamp: DateTime.now(),
        id: _id(),
      ),
    );
  }

  String _id() =>
      "${DateTime.now().microsecondsSinceEpoch}${Random().nextInt(999)}";

  Future<String> _callAI(String message) async {
    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'deepseek/deepseek-r1-0528:free',
        'messages': [
          {'role': 'system', 'content': 'You are a helpful AI assistant.'},
          {'role': 'user', 'content': message},
        ],
        'temperature': 0.7,
        'max_tokens': 1500,
      }),
    );

    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'];
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    _controller.clear();

    setState(() {
      _messages.add(
        Message(
          content: text,
          isUser: true,
          timestamp: DateTime.now(),
          id: _id(),
        ),
      );
      _isLoading = true;
    });

    _scroll();

    final aiIndex = _messages.length;
    setState(() {
      _messages.add(
        Message(
          content: "Typing…",
          isUser: false,
          timestamp: DateTime.now(),
          id: _id(),
        ),
      );
    });

    try {
      final reply = await _callAI(text);

      setState(() {
        _messages[aiIndex] = Message(
          content: reply,
          isUser: false,
          timestamp: DateTime.now(),
          id: _messages[aiIndex].id,
        );
      });
    } catch (_) {
      setState(() {
        _messages[aiIndex] = Message(
          content: "⚠️ Something went wrong. Please try again.",
          isUser: false,
          timestamp: DateTime.now(),
          id: _messages[aiIndex].id,
        );
      });
    } finally {
      _isLoading = false;
      _scroll();
    }
  }

  void _scroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(child: _chat()),
            _input(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Saarthi AI",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                "Your smart assistant",
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chat() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _bubble(_messages[i]),
    );
  }

  Widget _bubble(Message m) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: m.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: m.isUser ? null : AppColors.glass,
                gradient: m.isUser
                    ? const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF6366F1)],
                      )
                    : null,
                borderRadius: BorderRadius.circular(22),
                border: m.isUser ? null : Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: m.isUser
                  ? Text(
                      m.content,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    )
                  : GptMarkdown(
                      m.content,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _input() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.glass,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _controller,
                maxLines: null,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: "Ask anything…",
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isLoading ? null : _send,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                ),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _isLoading ? Icons.hourglass_empty : Icons.send_rounded,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
