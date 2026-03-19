import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:io';
import '../theme/design_system.dart';
import '../repository/api_repository.dart';
import '../services/plant_disease_service.dart';
import 'home_screen.dart';

class ChatMessage {
  String text;
  final bool isUser;
  final DateTime timestamp;
  final String? imagePath;
  bool isAnimating;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.imagePath,
    this.isAnimating = false,
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
  final ApiRepository _apiRepo = ApiRepository();
  bool _isTyping = false;
  String? _pendingImagePath;
  Timer? _animationTimer;

  // Chat history in the format expected by the server
  final List<Map<String, String>> _chatHistory = [];

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
    _animationTimer?.cancel();
    super.dispose();
  }

  Future<void> _openCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _pendingImagePath = image.path;
      });
    }
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

    final userText = text.isEmpty ? 'Đã gửi ảnh' : text;
    final imagePath = _pendingImagePath;

    setState(() {
      _messages.add(ChatMessage(
        text: userText,
        isUser: true,
        imagePath: imagePath,
      ));
      _controller.clear();
      _pendingImagePath = null;
      _isTyping = true;
    });

    _scrollToBottom();
    _processAndSend(userText, imagePath);
  }

  Future<void> _processAndSend(String userText, String? imagePath) async {
    String questionForApi = userText;

    // If there's an image, run the TFLite model to generate diagnosis context
    if (imagePath != null) {
      try {
        final service = PlantDiseaseService();
        final result = await service.classifyForChat(imagePath);
        final diagnosisContext =
            '[Phân tích ảnh AI] Cây: ${result.plantName}, '
            '${result.isHealthy ? "Tình trạng: Khỏe mạnh" : "Bệnh: ${result.diseaseName}"}, '
            'Độ tin cậy: ${result.confidence.toStringAsFixed(1)}%.';
        
        // Combine diagnosis context with user text
        if (userText == 'Đã gửi ảnh') {
          questionForApi = '$diagnosisContext\nHãy giải thích chi tiết kết quả chẩn đoán này.';
        } else {
          questionForApi = '$diagnosisContext\n\nCâu hỏi của người dùng: $userText';
        }
      } catch (e) {
        // If model fails, just send the text as-is
        print('[Chat] Image classification failed: $e');
      }
    }

    // Call the chat API
    final response = await _apiRepo.sendChat(
      question: questionForApi,
      chatHistory: List<Map<String, String>>.from(_chatHistory),
    );

    if (!mounted) return;

    String replyText;
    if (response.isSuccess) {
      final json = response.json;
      replyText = json?['answer'] as String? ?? response.body;

      // Update chat history from server response
      final serverHistory = json?['chat_history'] as List<dynamic>?;
      if (serverHistory != null) {
        _chatHistory.clear();
        for (final entry in serverHistory) {
          if (entry is Map) {
            _chatHistory.add({
              'role': entry['role']?.toString() ?? '',
              'content': entry['content']?.toString() ?? '',
            });
          }
        }
      }
    } else {
      replyText =
          '❌ Lỗi: ${response.statusCode != 0 ? 'Server trả về ${response.statusCode}' : response.body}';
    }

    // Start word-by-word animation
    _startTypingAnimation(replyText);
  }

  void _startTypingAnimation(String fullText) {
    final words = fullText.split('');
    int currentIndex = 0;

    final botMessage = ChatMessage(
      text: '',
      isUser: false,
      isAnimating: true,
    );

    setState(() {
      _isTyping = false;
      _messages.add(botMessage);
    });

    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(const Duration(milliseconds: 18), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (currentIndex < words.length) {
        setState(() {
          botMessage.text += words[currentIndex];
        });
        currentIndex++;
        _scrollToBottom();
      } else {
        timer.cancel();
        setState(() {
          botMessage.isAnimating = false;
        });
      }
    });
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
            _animationTimer?.cancel();
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
                  _isTyping ? "Đang suy nghĩ..." : "Online",
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          message.text,
                          style: FarmTextStyles.bodyLarge.copyWith(
                            color:
                                isUser ? Colors.white : FarmColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ),
                      if (message.isAnimating) ...[
                        const SizedBox(width: 4),
                        _buildCursorBlink(),
                      ],
                    ],
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

  Widget _buildCursorBlink() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 530),
      builder: (context, value, child) {
        return Opacity(
          opacity: value > 0.5 ? 1.0 : 0.0,
          child: Container(
            width: 2,
            height: 16,
            color: FarmColors.primary,
          ),
        );
      },
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
          PopupMenuButton<String>(
            icon: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: FarmColors.surfaceContainer,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.add, color: FarmColors.primary, size: 24),
            ),
            splashRadius: 22,
            padding: EdgeInsets.zero,
            offset: const Offset(0, -120),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: FarmColors.surface,
            elevation: 4,
            onSelected: (value) {
              if (value == 'camera') {
                _openCamera();
              } else if (value == 'gallery') {
                _pickImage();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'camera',
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: FarmColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: FarmColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text('Chụp ảnh', style: FarmTextStyles.button),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'gallery',
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: FarmColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.photo_library_rounded, color: FarmColors.accent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text('Thư viện', style: FarmTextStyles.button),
                  ],
                ),
              ),
            ],
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
