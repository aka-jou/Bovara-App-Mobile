// lib/core/widgets/bovara_text_field.dart
//
// Campo de texto estándar del rediseño:
//   - Etiqueta arriba (fontSize 13, weight 700, textPrimary).
//   - Caja blanca con borde #E7EAE3 (1.5px), radio 14-16px, sombra sutil.
//   - Ícono opcional a la izquierda, ícono opcional a la derecha (para
//     mostrar/ocultar contraseña).
//   - Hint text opcional debajo (mensaje o "¿olvidaste tu contraseña?").
//
// Uso:
//   BovaraTextField(
//     label: 'Email o teléfono',
//     hint: 'don.carlos@rancho.com',
//     controller: _emailCtrl,
//     leadingIcon: Icons.mail_outline,
//   )

import 'package:flutter/material.dart';
import '../theme/theme.dart';

class BovaraTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final IconData? leadingIcon;
  final Widget? trailing;
  final bool obscureText;
  final bool canToggleObscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final int? maxLines;
  final bool enabled;

  const BovaraTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.leadingIcon,
    this.trailing,
    this.obscureText = false,
    this.canToggleObscure = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.maxLines,
    this.enabled = true,
  });

  @override
  State<BovaraTextField> createState() => _BovaraTextFieldState();
}

class _BovaraTextFieldState extends State<BovaraTextField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: BovaraText.label(size: 13, color: BovaraColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: BovaraColors.border, width: 1.5),
            borderRadius: BorderRadius.circular(BovaraRadius.md),
            boxShadow: const [
              BoxShadow(
                color: Color(0x141428), // rgba(20,40,25,.12)
                blurRadius: 10,
                offset: Offset(0, 3),
                spreadRadius: -6,
              ),
            ],
          ),
          child: Row(
            children: [
              if (widget.leadingIcon != null) ...[
                const SizedBox(width: 16),
                Icon(widget.leadingIcon,
                    size: 18, color: BovaraColors.textMuted),
              ],
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  child: TextFormField(
                    controller: widget.controller,
                    obscureText: _obscure,
                    keyboardType: widget.keyboardType,
                    validator: widget.validator,
                    onChanged: widget.onChanged,
                    maxLines: widget.obscureText ? 1 : widget.maxLines,
                    enabled: widget.enabled,
                    style: BovaraText.body(size: 15),
                    cursorColor: BovaraColors.primary,
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      hintStyle: BovaraText.body(
                        size: 15,
                        color: BovaraColors.textDisabled,
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      errorStyle: BovaraText.caption(color: BovaraColors.danger),
                    ),
                  ),
                ),
              ),
              if (widget.canToggleObscure)
                _ObscureToggle(
                  obscure: _obscure,
                  onTap: () => setState(() => _obscure = !_obscure),
                )
              else if (widget.trailing != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: widget.trailing,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ObscureToggle extends StatelessWidget {
  final bool obscure;
  final VoidCallback onTap;
  const _ObscureToggle({required this.obscure, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BovaraRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 20,
            color: BovaraColors.textMuted,
          ),
        ),
      ),
    );
  }
}
