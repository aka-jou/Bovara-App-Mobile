// lib/features/onboarding/presentation/pages/onboarding_page.dart
//
// Onboarding de 4 slides (Grupo A del prototipo):
//   1. "Tu libreta del rancho, ahora inteligente" — presentation1.jpg
//   2. "Funciona 100% sin internet" — presentation2.jpg
//   3. "Detecta el celo a tiempo" — presentation4.jpg
//   4. "Conoce a Bovi, tu asistente" — fondo oscuro con avatar
//
// Slides con foto de fondo cubierta por un gradient negro (0.55 → 0.15 →
// 0.55 → 0.94), chip glass con título de sección, título display grande
// (36px) y descripción. Al final, botón "Comenzar" que navega a /welcome.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/bovara_buttons.dart';
import '../../../../core/widgets/bovara_chips.dart';
import '../../../../core/widgets/bovara_logo.dart';
import '../../../../core/widgets/bovara_page_dots.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  int _current = 0;
  bool _preloaded = false;

  static const _slides = <_SlideData>[
    _SlideData(
      chip: 'Bienvenido al rancho digital',
      title: 'Tu libreta del rancho,\nahora inteligente',
      subtitle:
          'Registra pesajes, partos y celos en 2 minutos. Bovara ordena todo por ti y lo mantiene seguro.',
      image: 'assets/images/presentation1.jpg',
      imageAlignment: Alignment(0, -0.3),
    ),
    _SlideData(
      chip: 'Diseñado para el campo',
      title: 'Funciona 100%\nsin internet',
      subtitle:
          'Captura en el corral aunque no haya señal. Bovara sincroniza sola en cuanto vuelve el WiFi.',
      image: 'assets/images/presentation2.jpg',
      imageAlignment: Alignment.center,
    ),
    _SlideData(
      chip: 'Predicción con IA',
      title: 'Detecta el celo\na tiempo',
      subtitle:
          'La IA predice celos, alertas de salud y tareas. No pierdas un solo día de reproducción.',
      image: 'assets/images/presentation4.jpg',
      imageAlignment: Alignment(0, -0.2),
    ),
    _SlideData(
      chip: 'Tu copiloto de campo',
      title: 'Conoce a Bovi,\ntu asistente',
      subtitle:
          'Pregúntale por voz o texto sobre celos, vacunas y tareas. Te responde al instante, aunque estés sin señal.',
      image: null,
      imageAlignment: Alignment.center,
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precachear TODAS las imágenes al primer build para que al deslizar
    // ya estén decodificadas y no haya "salto" al aparecer.
    if (!_preloaded) {
      for (final s in _slides) {
        if (s.image != null) {
          precacheImage(AssetImage(s.image!), context);
        }
      }
      _preloaded = true;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_current >= _slides.length - 1) {
      _finish();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _skip() {
    _pageController.animateToPage(
      _slides.length - 1,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    // Marca que el onboarding ya fue visto para que no vuelva a aparecer.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    if (!mounted) return;
    context.go('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BovaraColors.background,
      // extendBody: true permite que el contenido pase por debajo de los
      // controles inferiores translúcidos.
      extendBody: true,
      body: Stack(
        children: [
          // Slides ocupan TODA la pantalla (fotos hasta abajo)
          PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, i) => _OnboardingSlide(
              data: _slides[i],
              onSkip: _skip,
            ),
          ),
          // Controles inferiores flotando encima
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomControls(
              count: _slides.length,
              current: _current,
              onDotTap: (i) => _pageController.animateToPage(
                i,
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
              ),
              onNext: _next,
              isLast: _current == _slides.length - 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideData {
  final String chip;
  final String title;
  final String subtitle;
  final String? image;
  final Alignment imageAlignment;

  const _SlideData({
    required this.chip,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.imageAlignment,
  });
}

class _OnboardingSlide extends StatelessWidget {
  final _SlideData data;
  final VoidCallback onSkip;

  const _OnboardingSlide({required this.data, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Fondo: foto o gradient radial oscuro
        if (data.image != null)
          Image.asset(data.image!, fit: BoxFit.cover, alignment: data.imageAlignment)
        else
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.4),
                radius: 1.2,
                colors: [Color(0xFF1F3423), BovaraColors.background],
                stops: [0.0, 0.62],
              ),
            ),
            child: const _BoviAvatar(),
          ),

        // Overlay oscuro (solo cuando hay foto)
        if (data.image != null)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: BovaraColors.darkFadeGradient,
                stops: [0.0, 0.32, 0.62, 1.0],
              ),
            ),
          ),

        // Contenido superpuesto
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // Header: logo + botón skip
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const BovaraLogo.small(),
                    _SkipButton(onTap: onSkip),
                  ],
                ),
                const Spacer(),
                // Chip + título + subtítulo alineados a la izquierda
                GlassChip(
                  label: data.chip,
                  dotColor: BovaraColors.primary,
                ),
                const SizedBox(height: BovaraSpace.md),
                Text(
                  data.title,
                  style: BovaraText.display().copyWith(
                    fontSize: 30,
                    height: 1.1,
                    shadows: const [
                      Shadow(color: Color(0x99000000), blurRadius: 24, offset: Offset(0, 2)),
                    ],
                  ),
                ),
                const SizedBox(height: BovaraSpace.md),
                Text(
                  data.subtitle,
                  style: BovaraText.body(
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.88),
                  ).copyWith(
                    height: 1.5,
                    shadows: const [
                      Shadow(color: Color(0x99000000), blurRadius: 16, offset: Offset(0, 1)),
                    ],
                  ),
                ),
                // Espacio para que el bloque de controles inferiores no
                // tape el texto. ~180 = altura aprox del bloque translúcido.
                const SizedBox(height: 180),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SkipButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SkipButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(BovaraRadius.md),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16), width: 1),
            borderRadius: BorderRadius.circular(BovaraRadius.md),
          ),
          child: Text(
            'Saltar',
            style: BovaraText.label(
              size: 12,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  final int count;
  final int current;
  final ValueChanged<int> onDotTap;
  final VoidCallback onNext;
  final bool isLast;

  const _BottomControls({
    required this.count,
    required this.current,
    required this.onDotTap,
    required this.onNext,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    // Bloque translúcido con gradient hacia negro para que la foto de
    // fondo se vea COMPLETA hasta abajo, incluso detrás del botón.
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x00000000),
            Color(0xB3000000),
            Color(0xE6000000),
          ],
          stops: [0.0, 0.4, 1.0],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BovaraPageDots(
            count: count,
            activeIndex: current,
            onTap: onDotTap,
          ),
          const SizedBox(height: BovaraSpace.lg),
          _OnboardingCTA(label: isLast ? 'Comenzar' : 'Siguiente', onTap: onNext),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _OnboardingCTA extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OnboardingCTA({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(36),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 17),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F4EE),
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.24),
                blurRadius: 34,
                offset: const Offset(0, 14),
                spreadRadius: -14,
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: BovaraText.label(
                size: 15,
                color: BovaraColors.background,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Avatar animado de Bovi (slide 4). Cabeza estilizada con orejas, ojos
/// que parpadean y hocico. Extraído del bloque HTML del prototipo.
class _BoviAvatar extends StatefulWidget {
  const _BoviAvatar();

  @override
  State<_BoviAvatar> createState() => _BoviAvatarState();
}

class _BoviAvatarState extends State<_BoviAvatar> with SingleTickerProviderStateMixin {
  late final AnimationController _bob;

  @override
  void initState() {
    super.initState();
    _bob = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 110),
        child: AnimatedBuilder(
          animation: _bob,
          builder: (context, child) {
            final t = Curves.easeInOut.transform(_bob.value);
            return Transform.translate(offset: Offset(0, -5 * t), child: child);
          },
          child: SizedBox(
            width: 172,
            height: 164,
            child: Stack(
              children: [
                // Oreja izquierda
                Positioned(
                  top: 44,
                  left: 2,
                  child: Transform.rotate(
                    angle: -0.314, // -18deg
                    child: Container(
                      width: 52,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD7A883),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.elliptical(31, 23),
                          topRight: Radius.elliptical(21, 15),
                          bottomLeft: Radius.elliptical(26, 19),
                          bottomRight: Radius.elliptical(26, 19),
                        ),
                      ),
                    ),
                  ),
                ),
                // Oreja derecha
                Positioned(
                  top: 44,
                  right: 2,
                  child: Transform.rotate(
                    angle: 0.314,
                    child: Container(
                      width: 52,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD7A883),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.elliptical(21, 15),
                          topRight: Radius.elliptical(31, 23),
                          bottomLeft: Radius.elliptical(26, 19),
                          bottomRight: Radius.elliptical(26, 19),
                        ),
                      ),
                    ),
                  ),
                ),
                // Interior de orejas
                Positioned(
                  top: 14,
                  left: 46,
                  child: Transform.rotate(
                    angle: -0.384,
                    child: Container(
                      width: 24,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFE6D2),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.elliptical(14, 11),
                          bottom: Radius.elliptical(10, 7),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  right: 46,
                  child: Transform.rotate(
                    angle: 0.384,
                    child: Container(
                      width: 24,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFE6D2),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.elliptical(14, 11),
                          bottom: Radius.elliptical(10, 7),
                        ),
                      ),
                    ),
                  ),
                ),
                // Cabeza principal
                Positioned(
                  top: 26,
                  left: 26,
                  child: Container(
                    width: 120,
                    height: 112,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4EDE0),
                      borderRadius: BorderRadius.circular(58),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A785A3C),
                          blurRadius: 16,
                          offset: Offset(0, -8),
                          spreadRadius: -8,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Manchas
                        Positioned(
                          top: 6,
                          left: 14,
                          child: Container(
                            width: 34,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFF7A5535),
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 16,
                          child: Container(
                            width: 22,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Color(0xFF7A5535),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        // Ojos
                        _BoviEye(top: 40, left: 24),
                        _BoviEye(top: 40, right: 24),
                        // Hocico
                        Positioned(
                          bottom: 8,
                          left: 23,
                          child: Container(
                            width: 74,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBB9A8),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x2EA05A46),
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                  spreadRadius: -2,
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 14,
                                  left: 16,
                                  child: Container(
                                    width: 10,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFC98A79),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 14,
                                  right: 16,
                                  child: Container(
                                    width: 10,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFC98A79),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BoviEye extends StatelessWidget {
  final double top;
  final double? left;
  final double? right;
  const _BoviEye({required this.top, this.left, this.right});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE3D9C6), width: 1),
        ),
        child: Center(
          child: Container(
            width: 13,
            height: 13,
            decoration: const BoxDecoration(
              color: Color(0xFF2B2018),
              shape: BoxShape.circle,
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
