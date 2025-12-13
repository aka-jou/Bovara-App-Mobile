import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/services/gemini_service.dart.bak';

class AssistantChatPage extends StatefulWidget {
  const AssistantChatPage({super.key});

  @override
  State<AssistantChatPage> createState() => _AssistantChatPageState();
}

class _AssistantChatPageState extends State<AssistantChatPage>
    with TickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _sending = false;
  bool _assistantTyping = false;

  // Voz
  late stt.SpeechToText _speechToText;
  bool _isListening = false;
  bool _speechEnabled = false;
  bool _canCancelRecording = false;
  String _lastWords = '';

  // Gemini
  late GeminiService _geminiService;

  // Animaciones
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late AnimationController _thinkingController;
  late Animation<double> _thinkingAnimation;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initGemini();
    _initAnimations();
    _addWelcomeMessage();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _thinkingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _thinkingAnimation = CurvedAnimation(
      parent: _thinkingController,
      curve: Curves.easeInOut,
    );
  }

  void _initGemini() {
    try {
      _geminiService = GeminiService();
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al inicializar Gemini: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      });
    }
  }

  void _addWelcomeMessage() {
    final now = TimeOfDay.now();
    final ts = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    _messages.add(
      ChatMessage(
        text: '¡Hola! Soy el Asistente Bovara \n\n'
            'Puedo ayudarte con:\n'
            '• Análisis de producción \n'
            '• Calendarios de vacunación \n'
            '• Registro de pesajes ️\n'
            '• Recomendaciones de manejo \n'
            '• Y mucho más\n\n'
            '¿En qué puedo ayudarte hoy?',
        isUser: false,
        timestamp: ts,
      ),
    );
  }

  Future<void> _initSpeech() async {
    _speechToText = stt.SpeechToText();
    _speechEnabled = await _speechToText.initialize(
      onError: (error) {
        debugPrint('Error en Speech-to-Text: $error');
        if (mounted) setState(() => _isListening = false);
      },
      onStatus: (status) {
        debugPrint('Estado de Speech: $status');
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _isListening = false);
        }
      },
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _speechToText.stop();
    _pulseController.dispose();
    _thinkingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),
      appBar: _buildHeader(context),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              itemCount: _messages.length + (_assistantTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _assistantTyping) {
                  return _buildThinkingIndicator();
                }
                final msg = _messages[index];
                return _buildMessageWithAnimation(msg, index);
              },
            ),
          ),
          const Divider(height: 1),
          _buildInputBar(),
        ],
      ),
    );
  }

  AppBar _buildHeader(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF2E7D32),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.go('/home'),
      ),
      title: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.smart_toy_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Asistente Bovara',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.6, end: 1.0),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeInOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _assistantTyping ? Colors.amber : Colors.greenAccent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (_assistantTyping ? Colors.amber : Colors.greenAccent).withOpacity(0.6),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      onEnd: () => setState(() {}),
                    ),
                    const SizedBox(width: 6),
                    if (_speechEnabled)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          Icons.mic,
                          color: Colors.white.withOpacity(0.7),
                          size: 12,
                        ),
                      ),
                    Text(
                      _assistantTyping ? 'Pensando...' : 'IA activa',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      centerTitle: false,
      actions: [
        IconButton(
          onPressed: _clearChat,
          icon: const Icon(Icons.refresh, color: Colors.white, size: 22),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.more_vert, color: Colors.white, size: 24),
        ),
      ],
    );
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reiniciar conversación'),
        content: const Text('¿Deseas borrar todo el historial de chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _messages.clear();
                _geminiService.clearHistory();
                _addWelcomeMessage();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageWithAnimation(ChatMessage message, int index) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(index),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: _buildMessage(message),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: isUser ? _buildUserMessage(message) : _buildAssistantMessage(message),
          ),
        ],
      ),
    );
  }

  Widget _buildUserMessage(ChatMessage message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(6),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E7D32).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.isVoiceMessage)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.mic, color: Colors.white70, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Mensaje de voz',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                message.text,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: 0.8,
                    child: Text(
                      message.timestamp,
                      style: const TextStyle(fontSize: 11, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.done_all, color: Colors.white70, size: 14),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAssistantMessage(ChatMessage message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(6),
              bottomRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF212121),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    message.timestamp,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4285F4), Color(0xFF34A853)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'Gemini',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThinkingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildThinkingDot(0),
                const SizedBox(width: 6),
                _buildThinkingDot(1),
                const SizedBox(width: 6),
                _buildThinkingDot(2),
                const SizedBox(width: 12),
                RotationTransition(
                  turns: _thinkingAnimation,
                  child: const Icon(Icons.auto_awesome, color: Color(0xFF4285F4), size: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThinkingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 150)),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        final scale = 0.5 + (value * 0.5);
        final opacity = 0.3 + (value * 0.7);
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF4285F4).withOpacity(opacity),
                    const Color(0xFF34A853).withOpacity(opacity),
                  ],
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted) setState(() {});
      },
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: const Color(0xFFF5F5F5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isListening)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: const Icon(Icons.mic, color: Color(0xFF2E7D32), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _lastWords.isEmpty ? 'Escuchando...' : _lastWords,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0D000000),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _inputController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Pregúntale a Bovara...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (_speechEnabled)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: _isListening ? const Color(0xFF2E7D32) : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        if (_isListening)
                          const BoxShadow(
                            color: Color(0x332E7D32),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _toggleListening,
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? Colors.white : const Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sending ? null : _handleSend,
                  icon: _sending
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.send_rounded, color: Color(0xFF2E7D32)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speechToText.stop();
      setState(() => _isListening = false);

      if (_lastWords.isNotEmpty) {
        final transcribedText = _lastWords;
        _inputController.text = transcribedText;
        setState(() => _lastWords = '');

        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _inputController.text.isNotEmpty) {
            _handleSend(isVoice: true);
          }
        });
      }
    } else {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permiso de micrófono denegado'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      setState(() {
        _isListening = true;
        _lastWords = '';
      });

      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _lastWords = result.recognizedWords;
          });
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: 'es_MX',
      );
    }
  }

  void _handleSend({bool isVoice = false}) async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    final now = TimeOfDay.now();
    final ts = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    setState(() {
      _sending = true;
      _messages.add(
        ChatMessage(
          text: text,
          isUser: true,
          timestamp: ts,
          isVoiceMessage: isVoice,
        ),
      );
      _inputController.clear();
    });

    _scrollToBottom();
    setState(() => _assistantTyping = true);

    try {
      final response = await _geminiService.sendMessage(text);

      if (mounted) {
        setState(() {
          _sending = false;
          _assistantTyping = false;
          _messages.add(
            ChatMessage(
              text: response.text,
              isUser: false,
              timestamp: ts,
            ),
          );
        });

        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sending = false;
          _assistantTyping = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }
}

// ========== MODELOS ==========
class ChatMessage {
  final String text;
  final bool isUser;
  final String timestamp;
  final bool isVoiceMessage;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isVoiceMessage = false,
  });
}
