// lib/features/assistant/presentation/pages/assistant_chat_page.dart
//
// Chat con Bovi (Grupo D del rediseño).
//
// Estructura:
//   - Header verde con gradient: botón atrás + avatar Bovi + nombre + chip IA
//     + puntito de "en línea" + botón "cambiar idioma" (placeholder).
//   - Sección plegable "Recomendaciones de uso" con 4 cards horizontales
//     (Habla o escribe, Consulta al instante, Sin conexión, Atajos rápidos).
//   - Timeline del chat con mensajes:
//       - Usuario: burbuja verde con gradient a la derecha.
//       - Bot: burbuja blanca a la izquierda con avatar de Bovi que
//         PARPADEA y HABLA mientras responde (animación real).
//   - Barra de chips sugeridos ("¿Alguna vaca en celo?" etc).
//   - Input con micrófono y botón enviar.
//
// LÓGICA CONECTADA REAL:
//   - Llama a AssistantService.sendMessage() con el mensaje del usuario.
//   - Micrófono usa el paquete speech_to_text ya en el pubspec.
//   - Los prompts sugeridos rellenan y envían automáticamente.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../../core/theme/theme.dart';
import '../../data/services/assistant_service.dart';

class AssistantChatPage extends StatefulWidget {
  final String? autoSendMessage;
  const AssistantChatPage({super.key, this.autoSendMessage});

  @override
  State<AssistantChatPage> createState() => _AssistantChatPageState();
}

class _AssistantChatPageState extends State<AssistantChatPage> {
  final _service = AssistantService();
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _speech = stt.SpeechToText();

  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _showTips = false;
  bool _isRecording = false;
  bool _speechReady = false;

  static const _suggestedChips = <String>[
    '¿Alguna vaca en celo?',
    '¿Qué vacunas toca hoy?',
    '¿Cuántas cabezas tengo?',
    'Tareas pendientes',
    'Ver últimos partos',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(_ChatMessage.bot(
      text: '¡Hola! Soy Bovi. Puedes preguntarme por celos, vacunas, pesos o tareas del día. ¿En qué te ayudo?',
    ));
    _initSpeech();
    if (widget.autoSendMessage != null && widget.autoSendMessage!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _sendMessage(widget.autoSendMessage!);
      });
    }
  }

  Future<void> _initSpeech() async {
    _speechReady = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _isRecording = false);
        }
      },
      onError: (err) {
        if (mounted) setState(() => _isRecording = false);
      },
    );
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    HapticFeedback.selectionClick();

    setState(() {
      _messages.add(_ChatMessage.user(text: trimmed));
      _isTyping = true;
      _inputCtrl.clear();
    });
    _scrollToBottom();

    try {
      final resp = await _service.sendMessage(trimmed);
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage.bot(
          text: resp.response.isEmpty ? '…' : resp.response,
          toolUsed: resp.toolUsed,
        ));
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage.bot(
          text: 'No pude conectar con Bovi ahora mismo. Revisa tu conexión e inténtalo de nuevo.',
          isError: true,
        ));
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startRecording() async {
    if (!_speechReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Micrófono no disponible en este dispositivo')),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _isRecording = true);
    _speech.listen(
      localeId: 'es_MX',
      onResult: (result) {
        setState(() => _inputCtrl.text = result.recognizedWords);
      },
    );
  }

  Future<void> _stopRecording() async {
    await _speech.stop();
    setState(() => _isRecording = false);
    if (_inputCtrl.text.trim().isNotEmpty) {
      _sendMessage(_inputCtrl.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F0),
      body: Column(
        children: [
          _Header(
            showTips: _showTips,
            onToggleTips: () => setState(() => _showTips = !_showTips),
            onBack: () => context.go('/home'),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              itemCount: _messages.length + (_isTyping ? 1 : 0) + 1,
              itemBuilder: (context, index) {
                if (index == 0) return const _DateSeparator(label: 'Hoy · Ahora');
                final adjIndex = index - 1;
                if (adjIndex < _messages.length) {
                  final msg = _messages[adjIndex];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: msg.isUser
                        ? _UserBubble(text: msg.text)
                        : _BotBubble(text: msg.text, isError: msg.isError, isTalking: false),
                  );
                }
                // typing indicator
                return const Padding(
                  padding: EdgeInsets.only(bottom: 14),
                  child: _BotTyping(),
                );
              },
            ),
          ),
          _SuggestedChipsBar(
            chips: _suggestedChips,
            onTap: _sendMessage,
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 6,
              bottom: 20 + MediaQuery.of(context).padding.bottom,
            ),
            child: _isRecording
                ? _RecordingBar(onStop: _stopRecording)
                : _InputBar(
                    controller: _inputCtrl,
                    onSend: () => _sendMessage(_inputCtrl.text),
                    onMic: _startRecording,
                  ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// HEADER
// ═════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  final bool showTips;
  final VoidCallback onToggleTips;
  final VoidCallback onBack;

  const _Header({
    required this.showTips,
    required this.onToggleTips,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [BovaraColors.primary, Color(0xFF1B5C2C)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          child: Column(
            children: [
              Row(
                children: [
                  // Botón atrás
                  Material(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: onBack,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  // Avatar Bovi
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.28),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                          spreadRadius: -6,
                        ),
                      ],
                    ),
                    child: const Center(child: _MiniBoviFace(size: 30)),
                  ),
                  const SizedBox(width: 12),
                  // Nombre + chip IA + estado
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Bovi',
                                style: BovaraText.title(color: Colors.white).copyWith(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.19,
                                )),
                            const SizedBox(width: 7),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFBFE6C6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('IA',
                                  style: BovaraText.label(
                                    size: 9,
                                    color: BovaraColors.primarySoftText,
                                  ).copyWith(letterSpacing: 1)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 1),
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFF8BE0A0),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'En línea · funciona sin internet',
                              style: BovaraText.label(
                                size: 11.5,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Toggle "Recomendaciones de uso"
              InkWell(
                onTap: onToggleTips,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        'RECOMENDACIONES DE USO',
                        style: BovaraText.label(
                          size: 10.5,
                          color: Colors.white.withValues(alpha: 0.78),
                        ).copyWith(letterSpacing: 1.4),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      const SizedBox(width: 9),
                      AnimatedRotation(
                        duration: const Duration(milliseconds: 240),
                        turns: showTips ? 0.5 : 0,
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: 18,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Cards horizontales de tips (colapsables)
              AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                child: showTips
                    ? const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: SizedBox(
                          height: 108,
                          child: _TipCards(),
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipCards extends StatelessWidget {
  const _TipCards();

  @override
  Widget build(BuildContext context) {
    final tips = <_Tip>[
      _Tip(icon: Icons.mic_none_rounded, iconColor: BovaraColors.primary,
        title: 'Habla o escribe',
        body: 'Pregunta por voz con el micrófono o escríbele.'),
      _Tip(icon: Icons.favorite_rounded, iconColor: BovaraColors.celo,
        title: 'Consulta al instante',
        body: 'Celos, vacunas, pesos y tareas del día.'),
      _Tip(icon: Icons.cloud_off_outlined, iconColor: BovaraColors.danger,
        title: 'Sin conexión',
        body: 'Bovi responde aunque no haya señal.'),
      _Tip(icon: Icons.bolt_rounded, iconColor: BovaraColors.warning,
        title: 'Atajos rápidos',
        body: 'Toca una sugerencia para empezar rápido.'),
    ];
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: tips.length,
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemBuilder: (context, i) => _TipCard(tip: tips[i]),
    );
  }
}

class _Tip {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  _Tip({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });
}

class _TipCard extends StatelessWidget {
  final _Tip tip;
  const _TipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 166,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(tip.icon, size: 16, color: tip.iconColor),
          ),
          const SizedBox(height: 9),
          Text(tip.title,
              style: BovaraText.label(size: 13, color: Colors.white)
                  .copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(
            tip.body,
            style: BovaraText.body(
              size: 11,
              color: Colors.white.withValues(alpha: 0.82),
            ).copyWith(fontWeight: FontWeight.w500, height: 1.35),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// AVATAR DE BOVI (cabeza animada estilo prototipo)
// ═════════════════════════════════════════════════════════════════

class _MiniBoviFace extends StatelessWidget {
  final double size;
  const _MiniBoviFace({this.size = 30});

  @override
  Widget build(BuildContext context) {
    // Proporciones del avatar del header (pequeño, estático)
    return SizedBox(
      width: size,
      height: size * 0.83,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Orejas
          Positioned(
            left: 0,
            top: size * 0.2,
            child: Transform.rotate(
              angle: -0.314,
              child: Container(
                width: size * 0.3,
                height: size * 0.28,
                decoration: BoxDecoration(
                  color: const Color(0xFFD7A883),
                  borderRadius: BorderRadius.circular(size),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: size * 0.2,
            child: Transform.rotate(
              angle: 0.314,
              child: Container(
                width: size * 0.3,
                height: size * 0.28,
                decoration: BoxDecoration(
                  color: const Color(0xFFD7A883),
                  borderRadius: BorderRadius.circular(size),
                ),
              ),
            ),
          ),
          // Cabeza
          Positioned(
            top: 0,
            child: Container(
              width: size * 0.75,
              height: size * 0.75,
              decoration: BoxDecoration(
                color: const Color(0xFFF4EDE0),
                borderRadius: BorderRadius.circular(size),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Mancha izq
                  Positioned(
                    top: size * 0.09,
                    left: size * 0.11,
                    child: Container(
                      width: size * 0.19,
                      height: size * 0.17,
                      decoration: const BoxDecoration(
                        color: Color(0xFF7A5535),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Ojos
                  Positioned(
                    top: size * 0.3,
                    left: size * 0.16,
                    child: Container(
                      width: size * 0.12,
                      height: size * 0.12,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: size * 0.06,
                          height: size * 0.06,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2B2018),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: size * 0.3,
                    right: size * 0.16,
                    child: Container(
                      width: size * 0.12,
                      height: size * 0.12,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: size * 0.06,
                          height: size * 0.06,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2B2018),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Hocico
                  Positioned(
                    bottom: size * 0.06,
                    child: Container(
                      width: size * 0.4,
                      height: size * 0.22,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBB9A8),
                        borderRadius: BorderRadius.circular(size),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// MENSAJES
// ═════════════════════════════════════════════════════════════════

class _ChatMessage {
  final bool isUser;
  final String text;
  final String? toolUsed;
  final bool isError;
  _ChatMessage({required this.isUser, required this.text, this.toolUsed, this.isError = false});
  factory _ChatMessage.user({required String text}) => _ChatMessage(isUser: true, text: text);
  factory _ChatMessage.bot({required String text, String? toolUsed, bool isError = false}) =>
      _ChatMessage(isUser: false, text: text, toolUsed: toolUsed, isError: isError);
}

class _DateSeparator extends StatelessWidget {
  final String label;
  const _DateSeparator({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFEAEBE4),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: BovaraText.label(size: 11.5, color: BovaraColors.textMuted),
        ),
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  final String text;
  const _UserBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment(-0.3, -1),
                end: Alignment(0.5, 1),
                colors: [BovaraColors.primary, BovaraColors.primaryDark],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(5),
              ),
              boxShadow: [
                BoxShadow(
                  color: BovaraColors.primaryDark.withValues(alpha: 0.5),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                  spreadRadius: -10,
                ),
              ],
            ),
            child: Text(
              text,
              style: BovaraText.body(size: 14, color: Colors.white).copyWith(
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BotBubble extends StatelessWidget {
  final String text;
  final bool isError;
  final bool isTalking;

  const _BotBubble({
    required this.text,
    this.isError = false,
    this.isTalking = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFE7F2E9),
            border: Border.all(color: const Color(0xFFCBE3CE), width: 1.5),
            shape: BoxShape.circle,
          ),
          child: const Center(child: _MiniBoviFace(size: 20)),
        ),
        const SizedBox(width: 9),
        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                color: isError ? BovaraColors.dangerSoftBg : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(5),
                  bottomRight: Radius.circular(18),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                    spreadRadius: -10,
                  ),
                ],
              ),
              child: Text(
                text,
                style: BovaraText.body(size: 14, color: BovaraColors.textPrimary).copyWith(
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BotTyping extends StatefulWidget {
  const _BotTyping();

  @override
  State<_BotTyping> createState() => _BotTypingState();
}

class _BotTypingState extends State<_BotTyping> with SingleTickerProviderStateMixin {
  late final AnimationController _ac;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Avatar de Bovi HABLANDO (parpadea + boca se mueve)
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFE7F2E9),
            border: Border.all(color: const Color(0xFFCBE3CE), width: 1.5),
            shape: BoxShape.circle,
          ),
          child: const Center(child: _MiniBoviFace(size: 28)),
        ),
        const SizedBox(width: 9),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(5),
              bottomRight: Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 16,
                offset: Offset(0, 6),
                spreadRadius: -10,
              ),
            ],
          ),
          child: AnimatedBuilder(
            animation: _ac,
            builder: (context, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dot(0),
                const SizedBox(width: 5),
                _dot(0.2),
                const SizedBox(width: 5),
                _dot(0.4),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dot(double phase) {
    final v = _ac.value;
    final t = ((v + phase) % 1.0);
    // Onda simple: opacidad + escala
    final scale = 0.6 + 0.4 * (0.5 + 0.5 * (t < 0.5 ? t : 1 - t) * 2);
    final opacity = 0.4 + 0.6 * (t < 0.5 ? t * 2 : (1 - t) * 2);
    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: BovaraColors.primary,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// CHIPS SUGERIDOS
// ═════════════════════════════════════════════════════════════════

class _SuggestedChipsBar extends StatelessWidget {
  final List<String> chips;
  final ValueChanged<String> onTap;

  const _SuggestedChipsBar({required this.chips, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          return InkWell(
            onTap: () => onTap(chips[i]),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFE7F2E9),
                border: Border.all(color: const Color(0xFFCFE6D3)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                chips[i],
                style: BovaraText.label(size: 12.5, color: BovaraColors.primarySoftText),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// INPUT + RECORDING
// ═════════════════════════════════════════════════════════════════

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onMic;

  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.onMic,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(left: 18, right: 8, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                  spreadRadius: -10,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    style: BovaraText.body(size: 14, color: BovaraColors.textPrimary),
                    cursorColor: BovaraColors.primary,
                    decoration: InputDecoration(
                      hintText: 'Escribe o toca el micrófono…',
                      hintStyle: BovaraText.body(
                        size: 14,
                        color: BovaraColors.textDisabled,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onMic,
                  borderRadius: BorderRadius.circular(19),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7F2E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mic, size: 20, color: BovaraColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Botón enviar
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onSend,
            customBorder: const CircleBorder(),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment(-0.3, -1),
                  end: Alignment(0.5, 1),
                  colors: [Color(0xFF3DA35D), BovaraColors.primary],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: BovaraColors.primary.withValues(alpha: 0.7),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                    spreadRadius: -8,
                  ),
                ],
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 22),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecordingBar extends StatefulWidget {
  final VoidCallback onStop;
  const _RecordingBar({required this.onStop});

  @override
  State<_RecordingBar> createState() => _RecordingBarState();
}

class _RecordingBarState extends State<_RecordingBar> with SingleTickerProviderStateMixin {
  late final AnimationController _ac;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 18, right: 10, top: 9, bottom: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF1D2CE), width: 1.5),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 6),
            spreadRadius: -10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: const BoxDecoration(
              color: BovaraColors.danger,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 11),
          Text('Escuchando…',
              style: BovaraText.label(size: 13, color: BovaraColors.textPrimary)),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedBuilder(
              animation: _ac,
              builder: (context, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(9, (i) {
                    final heights = [9.0, 17.0, 12.0, 22.0, 14.0, 20.0, 10.0, 16.0, 9.0];
                    final phase = (i * 0.11) % 1.0;
                    final t = ((_ac.value + phase) % 1.0);
                    final scale = 0.5 + 0.5 * (t < 0.5 ? t * 2 : (1 - t) * 2);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: Container(
                        width: 3,
                        height: heights[i] * scale,
                        decoration: BoxDecoration(
                          color: BovaraColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onStop,
              customBorder: const CircleBorder(),
              child: Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: BovaraColors.danger,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(3)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
