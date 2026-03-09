import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../theme/design_system.dart';
import 'home_screen.dart';
import 'diagnose_screen.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? imagePath;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.imagePath,
  }) : timestamp = timestamp ?? DateTime.now();
}

class PromptScreen extends StatefulWidget {
  const PromptScreen({super.key});

  @override
  State<PromptScreen> createState() => _PromptScreenState();
}

class _PromptScreenState extends State<PromptScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isTyping = false;
  String? _pendingImagePath;

  @override
  void initState() {
    super.initState();
    _messages.add(ChatMessage(
      text:
          "Xin chào! Tôi là FarmAI Assistant. Tôi có thể giúp bạn giải đáp các thắc mắc về cây trồng, bệnh hại, và kỹ thuật canh tác. Hãy hỏi tôi bất cứ điều gì!",
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: FarmColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: FarmColors.surfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Thêm tệp đính kèm',
              style: FarmTextStyles.heading3,
            ),
            const SizedBox(height: 20),
            _buildAttachmentOption(
              icon: Icons.camera_alt_rounded,
              label: 'Bật Camera',
              subtitle: 'Chụp ảnh để chẩn đoán',
              color: FarmColors.primary,
              onTap: () {
                Navigator.pop(context);
                _openCamera();
              },
            ),
            _buildAttachmentOption(
              icon: Icons.photo_library_rounded,
              label: 'Thêm Ảnh',
              subtitle: 'Chọn từ thư viện',
              color: FarmColors.accent,
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(label, style: FarmTextStyles.button),
      subtitle: Text(subtitle, style: FarmTextStyles.labelSmall),
      trailing: Icon(Icons.chevron_right, color: FarmColors.textSecondary),
    );
  }

  Future<void> _openCamera() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DiagnoseScreen()),
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pendingImagePath = image.path;
      });
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty && _pendingImagePath == null) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text.isEmpty ? 'Đã gửi ảnh' : text,
        isUser: true,
        imagePath: _pendingImagePath,
      ));
      _controller.clear();
      _pendingImagePath = null;
      _isTyping = true;
    });

    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text: _getAIResponse(text),
          isUser: false,
        ));
      });
      _scrollToBottom();
    });
  }

  String _getAIResponse(String query) {
    final lowerQuery = query.toLowerCase();
    if (lowerQuery.contains('bệnh') || lowerQuery.contains('sâu')) {
      return "Để chẩn đoán chính xác bệnh trên cây trồng, bạn có thể sử dụng tính năng 'Chẩn đoán AI' bằng cách chụp ảnh lá cây. Hệ thống sẽ phân tích và đưa ra kết quả trong vài giây.";
    } else if (lowerQuery.contains('phân bón') ||
        lowerQuery.contains('bón phân')) {
      return "Việc bón phân cần căn cứ vào giai đoạn phát triển của cây và điều kiện đất. Với cây lúa, nên chia làm 3 lần bón: bón lót, bón thúc đẻ nhánh, và bón đón đòng.";
    } else if (lowerQuery.contains('tưới') || lowerQuery.contains('nước')) {
      return "Lượng nước tưới phụ thuộc vào loại cây và thời tiết. Nên tưới vào sáng sớm hoặc chiều mát để tránh bay hơi. Kiểm tra độ ẩm đất trước khi tưới.";
    } else if (lowerQuery.contains('ảnh') || lowerQuery.isEmpty) {
      return "Tôi đã nhận được ảnh của bạn. Để phân tích chi tiết, vui lòng sử dụng tính năng Chẩn đoán AI trên thanh điều hướng.";
    } else {
      return "Cảm ơn câu hỏi của bạn! Để được hỗ trợ tốt nhất, vui lòng mô tả chi tiết hơn về vấn đề bạn đang gặp phải với cây trồng.";
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        backgroundColor: FarmColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: FarmColors.textPrimary),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          },
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: FarmStyles.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("FarmAI Assistant",
                    style: FarmTextStyles.button
                        .copyWith(color: FarmColors.textPrimary)),
                Text(
                  _isTyping ? "Đang trả lời..." : "Online",
                  style: FarmTextStyles.labelSmall.copyWith(
                    color: _isTyping ? FarmColors.warning : FarmColors.success,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: FarmColors.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == _messages.length) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          if (_pendingImagePath != null) _buildPendingImage(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildPendingImage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(_pendingImagePath!),
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: -4,
                right: -4,
                child: GestureDetector(
                  onTap: () => setState(() => _pendingImagePath = null),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: FarmColors.error,
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.close, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Text(
            'Ảnh đính kèm',
            style: FarmTextStyles.labelSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: FarmStyles.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (message.imagePath != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(message.imagePath!),
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? FarmColors.primary : FarmColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    boxShadow: isUser ? null : FarmStyles.cardShadow,
                  ),
                  child: Text(
                    message.text,
                    style: FarmTextStyles.bodyLarge.copyWith(
                      color: isUser ? Colors.white : FarmColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 46),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: FarmStyles.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.smart_toy_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: FarmColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: FarmStyles.cardShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 600 + (index * 200)),
                  builder: (context, value, child) {
                    return Container(
                      margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: FarmColors.primary.withValues(
                            alpha: 0.3 + (0.7 * (1 - (value - value.floor())))),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: FarmColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // + Button
          GestureDetector(
            onTap: _showAttachmentOptions,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: FarmColors.surfaceContainer,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.add,
                color: FarmColors.primary,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Text input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: FarmColors.surfaceContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                style: FarmTextStyles.bodyLarge,
                decoration: InputDecoration(
                  hintText: "Nhập câu hỏi của bạn...",
                  hintStyle: FarmTextStyles.bodyMedium,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Send button
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: FarmStyles.primaryGradient,
                borderRadius: BorderRadius.circular(22),
              ),
              child:
                  const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
