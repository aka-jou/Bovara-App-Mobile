// lib/features/cattle/presentation/pages/cattle_new_page.dart
//
// Nueva vaca (Grupo E · Nueva vaca del rediseño).
// - Header con back + título + hint "Se guarda offline · 2 minutos".
// - Slot de foto + botones "Tomar foto" / "Galería" (placeholders).
// - Campos: arete, nombre, lote, peso, sexo (segmented), nacimiento, raza.
// - Footer con botón "Guardar animal" + indicador de sync.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/cloudinary_service.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/bovara_buttons.dart';
import '../../data/models/cattle_model.dart';
import '../../data/services/cattle_service.dart';

class CattleNewPage extends StatefulWidget {
  const CattleNewPage({super.key});

  @override
  State<CattleNewPage> createState() => _CattleNewPageState();
}

class _CattleNewPageState extends State<CattleNewPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = CattleService();
  final _cloudinary = CloudinaryService();
  final _picker = ImagePicker();

  final _loteCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  String _gender = 'female';
  String _breed = 'Holstein';
  DateTime? _birthDate;
  bool _saving = false;
  File? _photoFile;
  bool _uploadingPhoto = false;

  static const _breeds = [
    'Holstein', 'Jersey', 'Cebú', 'Angus', 'Brahmán', 'Simmental', 'Otro',
  ];

  @override
  void dispose() {
    _loteCtrl.dispose();
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 3, now.month, now.day),
      firstDate: DateTime(2000),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: BovaraColors.primary,
            onPrimary: Colors.white,
            surface: BovaraColors.surface,
            onSurface: BovaraColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _pickBreed() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: BovaraColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: BovaraColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Text('Raza',
                      style: BovaraText.heading(color: BovaraColors.textPrimary)),
                ],
              ),
            ),
            for (final r in _breeds)
              ListTile(
                title: Text(r,
                    style: BovaraText.body(size: 15, color: BovaraColors.textPrimary)),
                trailing: r == _breed
                    ? const Icon(Icons.check, color: BovaraColors.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, r),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (choice != null) setState(() => _breed = choice);
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 82,
      );
      if (picked == null) return;
      setState(() => _photoFile = File(picked.path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir la cámara/galería: $e')),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.selectionClick();
    setState(() => _saving = true);
    try {
      // Sube la foto primero (si hay). Si falla, no aborta el registro:
      // el animal se crea sin foto y el usuario puede reintentar.
      String? photoUrl;
      if (_photoFile != null) {
        setState(() => _uploadingPhoto = true);
        try {
          photoUrl = await _cloudinary.uploadImage(_photoFile!);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Foto no subida ($e). Se guarda sin foto.'),
                backgroundColor: BovaraColors.warning,
              ),
            );
          }
        } finally {
          if (mounted) setState(() => _uploadingPhoto = false);
        }
      }

      final now = DateTime.now();
      final model = CattleModel(
        id: '',
        name: _nameCtrl.text.trim().isEmpty ? 'Sin nombre' : _nameCtrl.text.trim(),
        lote: _loteCtrl.text.trim(),
        breed: _breed,
        gender: _gender,
        birthDate: _birthDate,
        weight: double.tryParse(_weightCtrl.text.trim()),
        photoUrl: photoUrl,
        createdAt: now,
        updatedAt: now,
      );
      await _service.createCattle(model);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Animal registrado'),
          backgroundColor: BovaraColors.primary,
        ),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: BovaraColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BovaraColors.surface,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _Header(onBack: () => context.pop()),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(26, 4, 26, 20),
                  children: [
                    _PhotoSlot(
                      photoFile: _photoFile,
                      uploading: _uploadingPhoto,
                      onCamera: () => _pickPhoto(ImageSource.camera),
                      onGallery: () => _pickPhoto(ImageSource.gallery),
                      onRemove: () => setState(() => _photoFile = null),
                    ),
                    const SizedBox(height: 18),
                    _FieldLabel(label: 'Número de arete', required_: true),
                    _MonoField(
                      controller: _loteCtrl,
                      hint: 'Ej: 406',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Requerido'
                          : null,
                    ),
                    const SizedBox(height: 15),
                    _FieldLabel(label: 'Nombre', optional: true),
                    _TextField(
                      controller: _nameCtrl,
                      hint: 'Ej: La Pinta',
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldLabel(label: 'Lote'),
                              _TextField(
                                controller: TextEditingController(text: 'A'),
                                hint: 'A',
                                enabled: false,
                                trailing: const Icon(Icons.keyboard_arrow_down,
                                    size: 18, color: BovaraColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldLabel(label: 'Peso inicial'),
                              _TextField(
                                controller: _weightCtrl,
                                hint: '0',
                                keyboardType: TextInputType.number,
                                trailing: Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Text('kg',
                                      style: BovaraText.label(
                                        size: 13,
                                        color: BovaraColors.textDisabled,
                                      )),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _FieldLabel(label: 'Sexo'),
                    _GenderSegment(
                      value: _gender,
                      onChange: (v) => setState(() => _gender = v),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldLabel(label: 'Nacimiento'),
                              InkWell(
                                onTap: _pickBirthDate,
                                borderRadius: BorderRadius.circular(14),
                                child: _StaticField(
                                  text: _birthDate == null
                                      ? 'Elegir…'
                                      : _formatDate(_birthDate!),
                                  placeholder: _birthDate == null,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldLabel(label: 'Raza'),
                              InkWell(
                                onTap: _pickBreed,
                                borderRadius: BorderRadius.circular(14),
                                child: _StaticField(
                                  text: _breed,
                                  trailing: const Icon(Icons.keyboard_arrow_down,
                                      size: 18, color: BovaraColors.textMuted),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _Footer(saving: _saving, onSave: _save),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ─────────────────────────────────────────────────
// SUB WIDGETS
// ─────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 12, 26, 14),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  border: Border.all(color: BovaraColors.border, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    size: 14, color: BovaraColors.textPrimary),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nueva vaca',
                    style: BovaraText.title(color: BovaraColors.textPrimary).copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    )),
                const SizedBox(height: 2),
                Text('Se guarda offline · 2 minutos',
                    style: BovaraText.label(size: 12.5, color: BovaraColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  final File? photoFile;
  final bool uploading;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onRemove;

  const _PhotoSlot({
    required this.photoFile,
    required this.uploading,
    required this.onCamera,
    required this.onGallery,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 164,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: BovaraColors.surfaceAlt,
            border: Border.all(color: BovaraColors.border, width: 1.5),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (photoFile != null)
                Image.file(photoFile!, fit: BoxFit.cover)
              else
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_a_photo_outlined,
                          size: 32, color: BovaraColors.textDisabled),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Foto de la vaca — usa los botones de abajo',
                          textAlign: TextAlign.center,
                          style: BovaraText.label(size: 12, color: BovaraColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              if (photoFile != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: onRemove,
                      customBorder: const CircleBorder(),
                      child: const SizedBox(
                        width: 30,
                        height: 30,
                        child: Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ),
              if (uploading)
                Container(
                  color: Colors.black.withValues(alpha: 0.45),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.6,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _PhotoActionBtn(
                icon: Icons.camera_alt_outlined,
                label: 'Tomar foto',
                bg: const Color(0xFFE7F2E9),
                fg: BovaraColors.primarySoftText,
                onTap: onCamera,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _PhotoActionBtn(
                icon: Icons.photo_library_outlined,
                label: 'Galería',
                bg: BovaraColors.surfaceAlt,
                fg: BovaraColors.textSecondary,
                onTap: onGallery,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'La foto ayuda a identificar al animal en campo y a resolver duplicados de arete.',
          style: BovaraText.body(size: 11.5, color: BovaraColors.textDisabled)
              .copyWith(height: 1.4, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _PhotoActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  const _PhotoActionBtn({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 8),
              Text(label, style: BovaraText.label(size: 12.5, color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool required_;
  final bool optional;
  const _FieldLabel({required this.label, this.required_ = false, this.optional = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: RichText(
        text: TextSpan(
          text: label,
          style: BovaraText.label(size: 13, color: BovaraColors.textPrimary),
          children: [
            if (required_)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: BovaraColors.primary),
              ),
            if (optional)
              TextSpan(
                text: ' (opcional)',
                style: BovaraText.body(size: 13, color: BovaraColors.textDisabled)
                    .copyWith(fontWeight: FontWeight.w500),
              ),
          ],
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final Widget? trailing;
  final bool enabled;
  final String? Function(String?)? validator;

  const _TextField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.trailing,
    this.enabled = true,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: BovaraColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              validator: validator,
              enabled: enabled,
              style: BovaraText.body(size: 14.5, color: BovaraColors.textPrimary),
              cursorColor: BovaraColors.primary,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: BovaraText.body(size: 14.5, color: BovaraColors.textDisabled),
                border: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                errorStyle: const TextStyle(height: 0),
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _MonoField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;

  const _MonoField({
    required this.controller,
    required this.hint,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: BovaraColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: TextFormField(
        controller: controller,
        validator: validator,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: BovaraColors.textPrimary,
          letterSpacing: 0.06 * 17,
        ),
        cursorColor: BovaraColors.primary,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: BovaraColors.textDisabled,
          ),
          border: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          errorStyle: const TextStyle(height: 0),
        ),
      ),
    );
  }
}

class _StaticField extends StatelessWidget {
  final String text;
  final bool placeholder;
  final Widget? trailing;

  const _StaticField({
    required this.text,
    this.placeholder = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: BovaraColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: BovaraText.body(
                size: 14.5,
                color: placeholder ? BovaraColors.textDisabled : BovaraColors.textPrimary,
              ).copyWith(fontWeight: placeholder ? FontWeight.w500 : FontWeight.w600),
            ),
          ),
          trailing ?? const Icon(Icons.keyboard_arrow_down, size: 18, color: BovaraColors.textMuted),
        ],
      ),
    );
  }
}

class _GenderSegment extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChange;
  const _GenderSegment({required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: BovaraColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(child: _SegmentOption(label: 'Hembra', selected: value == 'female', onTap: () => onChange('female'))),
          const SizedBox(width: 4),
          Expanded(child: _SegmentOption(label: 'Macho', selected: value == 'male', onTap: () => onChange('male'))),
        ],
      ),
    );
  }
}

class _SegmentOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x30000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                    spreadRadius: -4,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: BovaraText.label(
            size: 13.5,
            color: selected ? BovaraColors.textPrimary : BovaraColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final bool saving;
  final VoidCallback onSave;

  const _Footer({required this.saving, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: BovaraColors.surface,
        border: Border(top: BorderSide(color: Color(0xFFEFF0EA))),
      ),
      padding: const EdgeInsets.fromLTRB(26, 14, 26, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(
            label: 'Guardar animal',
            onPressed: saving ? null : onSave,
            isLoading: saving,
            height: 54,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: BovaraColors.warning,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text('Se sincronizará al detectar red',
                  style: BovaraText.label(size: 12, color: BovaraColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}
