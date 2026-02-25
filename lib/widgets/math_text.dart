import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// Renders text with inline LaTeX math expressions.
/// Detects $...$ patterns and renders them as math, plain text otherwise.
class MathText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final WrapAlignment alignment;

  const MathText(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.center,
    this.alignment = WrapAlignment.center,
  });

  /// Clean up LaTeX string — fix escaping issues from JSON/Firestore.
  static String _cleanLatex(String tex) {
    var cleaned = tex;
    // Fix JSON escape sequences that break LaTeX commands:
    // \f (form feed) in JSON eats the backslash from \frac, \flat, etc.
    // \b (backspace) in JSON eats the backslash from \binom, \bar, etc.
    cleaned = cleaned.replaceAll('\x0C', '\\f'); // form feed → \f
    cleaned = cleaned.replaceAll('\x08', '\\b'); // backspace → \b
    // Fix double-escaped backslashes
    cleaned = cleaned.replaceAll('\\\\', '\\');
    return cleaned;
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle = style ?? Theme.of(context).textTheme.bodyLarge!;
    final cleanedText = _cleanLatex(text);

    // If no LaTeX markers, render as plain text
    if (!cleanedText.contains('\$')) {
      return Text(cleanedText, style: defaultStyle, textAlign: textAlign);
    }

    // Split on $...$ patterns
    final parts = <InlineSpan>[];
    final regex = RegExp(r'\$(.+?)\$');
    int lastEnd = 0;

    for (final match in regex.allMatches(cleanedText)) {
      // Add plain text before the match
      if (match.start > lastEnd) {
        parts.add(TextSpan(
          text: cleanedText.substring(lastEnd, match.start),
          style: defaultStyle,
        ));
      }
      // Add math widget — wrap in try/catch to gracefully handle parse errors
      final texContent = match.group(1)!;
      try {
        parts.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Math.tex(
            texContent,
            textStyle: defaultStyle.copyWith(fontSize: (defaultStyle.fontSize ?? 16) * 1.1),
            onErrorFallback: (error) => Text(
              texContent,
              style: defaultStyle,
            ),
          ),
        ));
      } catch (_) {
        // If LaTeX parsing fails, show as plain text
        parts.add(TextSpan(text: texContent, style: defaultStyle));
      }
      lastEnd = match.end;
    }

    // Add remaining plain text
    if (lastEnd < cleanedText.length) {
      parts.add(TextSpan(
        text: cleanedText.substring(lastEnd),
        style: defaultStyle,
      ));
    }

    return Text.rich(
      TextSpan(children: parts),
      textAlign: textAlign,
    );
  }
}
