import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:bitwise_academy/core/constants/app_typography.dart';

/// Reusable widget that renders mixed text+LaTeX strings.
///
/// Supports:
/// - Inline math: `$...$`
/// - Display/block math: `$$...$$`
/// - Falls back to plain [Text] for non-LaTeX strings.
///
/// Usage:
/// ```dart
/// LatexText('What is $\\frac{d}{dx}(x^2)$?')
/// LatexText('$$E = mc^2$$', style: TextStyle(color: Colors.white))
/// ```
class LatexText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const LatexText(
    this.text, {
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    super.key,
  });

  /// Returns true if [text] contains any LaTeX delimiters.
  static bool containsLatex(String text) {
    return text.contains(r'$') || text.contains(r'\(') || text.contains(r'\[');
  }

  @override
  Widget build(BuildContext context) {
    if (text.contains('\n')) {
      final lines = text.split('\n');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: lines.map((line) => LatexText(
          line,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        )).toList(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        if (!containsLatex(text)) {
          return Text(
            text,
            style: style,
            textAlign: textAlign,
            maxLines: maxLines,
            overflow: overflow,
          );
        }

        final segments = _parseSegments(text);

        if (segments.length == 1 && segments.first.isLatex) {
          // Pure math expression – render as a single Math widget with scaling
          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: textAlign == TextAlign.center
                  ? Alignment.center
                  : textAlign == TextAlign.right
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Math.tex(
                segments.first.content,
                textStyle: style,
                mathStyle: segments.first.isBlock
                    ? MathStyle.display
                    : MathStyle.text,
                onErrorFallback: (error) => Text(
                  segments.first.content,
                  style:
                      style?.copyWith(color: Colors.red) ??
                      AppTypography.bodyMd.copyWith(color: Colors.red),
                ),
              ),
            ),
          );
        }

        // Mixed text + LaTeX – use Wrap for flexible layout
        return Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: textAlign == TextAlign.center
              ? WrapAlignment.center
              : textAlign == TextAlign.right
              ? WrapAlignment.end
              : WrapAlignment.start,
          spacing: 0,
          runSpacing: 4,
          children: segments.map((segment) {
            if (segment.isLatex) {
              return ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Math.tex(
                    segment.content,
                    textStyle: style,
                    mathStyle: segment.isBlock
                        ? MathStyle.display
                        : MathStyle.text,
                    onErrorFallback: (error) => Text(
                      segment.content,
                      style:
                          style?.copyWith(
                            color: Colors.red,
                            fontStyle: FontStyle.italic,
                          ) ??
                          AppTypography.bodyMd.copyWith(
                            color: Colors.red,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ),
                ),
              );
            } else {
              return Text(segment.content, style: style);
            }
          }).toList(),
        );
      },
    );
  }

  /// Parses the input string into a list of [_TextSegment]s.
  ///
  /// Handles `$$...$$` (block), `$...$` (inline), `\[...\]` (block),
  /// and `\(...\)` (inline) delimiters.
  static List<_TextSegment> _parseSegments(String input) {
    final List<_TextSegment> segments = [];
    final buffer = StringBuffer();
    int i = 0;

    while (i < input.length) {
      // Check for $$ (block math)
      if (i < input.length - 1 && input[i] == r'$' && input[i + 1] == r'$') {
        // Flush text buffer
        if (buffer.isNotEmpty) {
          segments.add(_TextSegment(buffer.toString()));
          buffer.clear();
        }
        i += 2;
        final end = input.indexOf(r'$$', i);
        if (end == -1) {
          buffer.write(r'$$');
          buffer.write(input.substring(i));
          break;
        }
        segments.add(
          _TextSegment(input.substring(i, end), isLatex: true, isBlock: true),
        );
        i = end + 2;
        continue;
      }

      // Check for \[ (block math)
      if (i < input.length - 1 && input[i] == r'\' && input[i + 1] == '[') {
        if (buffer.isNotEmpty) {
          segments.add(_TextSegment(buffer.toString()));
          buffer.clear();
        }
        i += 2;
        final end = input.indexOf(r'\]', i);
        if (end == -1) {
          buffer.write(r'\[');
          buffer.write(input.substring(i));
          break;
        }
        segments.add(
          _TextSegment(input.substring(i, end), isLatex: true, isBlock: true),
        );
        i = end + 2;
        continue;
      }

      // Check for \( (inline math)
      if (i < input.length - 1 && input[i] == r'\' && input[i + 1] == '(') {
        if (buffer.isNotEmpty) {
          segments.add(_TextSegment(buffer.toString()));
          buffer.clear();
        }
        i += 2;
        final end = input.indexOf(r'\)', i);
        if (end == -1) {
          buffer.write(r'\(');
          buffer.write(input.substring(i));
          break;
        }
        segments.add(_TextSegment(input.substring(i, end), isLatex: true));
        i = end + 2;
        continue;
      }

      // Check for $ (inline math)
      if (input[i] == r'$') {
        if (buffer.isNotEmpty) {
          segments.add(_TextSegment(buffer.toString()));
          buffer.clear();
        }
        i += 1;
        final end = input.indexOf(r'$', i);
        if (end == -1) {
          buffer.write(r'$');
          buffer.write(input.substring(i));
          break;
        }
        segments.add(_TextSegment(input.substring(i, end), isLatex: true));
        i = end + 1;
        continue;
      }

      buffer.write(input[i]);
      i++;
    }

    if (buffer.isNotEmpty) {
      segments.add(_TextSegment(buffer.toString()));
    }

    return segments;
  }
}

/// Internal model for a parsed text/LaTeX segment.
class _TextSegment {
  final String content;
  final bool isLatex;
  final bool isBlock;

  const _TextSegment(
    this.content, {
    this.isLatex = false,
    this.isBlock = false,
  });
}
