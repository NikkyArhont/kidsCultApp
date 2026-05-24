import 'package:child_tracker/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reactive_forms/reactive_forms.dart';

class ReactiveCustomInput extends StatelessWidget {
  final String formName;
  final String label;
  final String hint;
  final String iconPath;
  final int maxLines;
  final int minLines;
  final TextInputType inputType;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final Map<String, String Function(Object)>? validationMessages;
  final bool obscure;
  final bool enabled;
  final Function(FormControl<Object?>)? onSubmitted;
  final Color? color;
  final bool hasAsyncValidator;
  final int maxLenght;
  final FocusNode? focus;
  final TextEditingController? controller;

  const ReactiveCustomInput({
    super.key,
    required this.formName,
    this.label = 'Email',
    this.hint = 'Email',
    this.iconPath = 'email.svg',
    this.maxLines = 1,
    this.minLines = 1,
    this.inputType = TextInputType.text,
    this.textCapitalization = TextCapitalization.sentences,
    this.textInputAction,
    this.inputFormatters,
    this.validationMessages,
    this.obscure = false,
    this.enabled = true,
    this.onSubmitted,
    this.color,
    this.hasAsyncValidator = false,
    this.maxLenght = 200,
    this.focus,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) AppText(text: label),
        if (label.isNotEmpty) const SizedBox(height: 8),
        ReactiveTextField(
          controller: controller,
          onSubmitted: onSubmitted,
          key: ValueKey(formName),
          readOnly: !enabled,
          showErrors: (control) => control.invalid && control.touched && enabled,
          formControlName: formName,
          focusNode: focus,
          validationMessages: validationMessages,
          maxLines: maxLines,
          minLines: minLines,
          keyboardType: inputType,
          textCapitalization: textCapitalization,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          obscureText: obscure,
          style: const TextStyle(fontSize: 18, color: greyscale900, fontWeight: FontWeight.w600, fontFamily: Involve),
          maxLength: maxLenght,
          decoration: InputDecoration(
            enabled: enabled,
            contentPadding: const EdgeInsets.symmetric(vertical: 19, horizontal: 20),
            filled: true,
            fillColor: enabled ? greyscale50 : greyscale400,
            hoverColor: primary900.withOpacity(0.08),
            hintText: hint,
            errorMaxLines: 4,
            errorStyle: const TextStyle(fontSize: 16, color: error, fontWeight: FontWeight.normal, fontFamily: Involve),
            hintStyle: const TextStyle(fontSize: 18, color: greyscale500, fontWeight: FontWeight.normal, fontFamily: Involve),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(width: 2, color: primary900),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(width: 2, color: error),
            ),
            counterText: '',
            suffix: ReactiveFormConsumer(builder: (context, form, child) {
              return hasAsyncValidator && form.control(formName).pending
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primary900,
                      ))
                  : const SizedBox();
            }),
          ),
        ),
      ],
    );
  }
}
