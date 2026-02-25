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

  @override
  Widget build(BuildContext context) {
    final defaultStyle = style ?? Theme.of(context).textTheme.bodyLarge!;

    // If no LaTeX markers, render as plain text
    if (!text.contains('\$')) {
      return Text(text, style: defaultStyle, textAlign: textAlign);
    }

    // Split on $...$ patterns
    final parts = <InlineSpan>[];
    final regex = RegExp(r'\$(.+?)\$');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      // Add plain text before the match
      if (match.start > lastEnd) {
        parts.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: defaultStyle,
        ));
      }
      // Add math widget
      parts.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Math.tex(
          match.group(1)!,
          textStyle: defaultStyle.copyWith(fontSize: (defaultStyle.fontSize ?? 16) * 1.1),
        ),
      ));
      lastEnd = match.end;
    }

    // Add remaining plain text
    if (lastEnd < text.length) {
      parts.add(TextSpan(
        text: text.substring(lastEnd),
        style: defaultStyle,
      ));
    }

    return Text.rich(
      TextSpan(children: parts),
      textAlign: textAlign,
    );
  }
}
