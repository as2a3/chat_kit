import 'package:chat_kit/src/config/chat_config.dart' show ChatConfig;
import 'package:flutter/material.dart';

/// Visual styling for the chat UI. Pass a custom instance via [ChatConfig], or
/// use one of the built-in presets:
///
/// - [ChatTheme.whatsapp] — classic WhatsApp-style green, light.
/// - [ChatTheme.light] — neutral light theme with a blue accent.
/// - [ChatTheme.dark] — neutral dark theme.
/// - [ChatTheme.amoled] — pure-black dark theme for OLED screens.
///
/// Colors are intentionally explicit (rather than pulled from the host
/// `ThemeData`) so the chat surface looks consistent across host apps, while
/// still being fully overridable. Build a one-off variant from any preset with
/// [copyWith], or animate between two themes with [lerp].
@immutable
class ChatTheme {
  /// Creates a chat theme with explicit colors and bubble radius.
  const ChatTheme({
    required this.primary,
    required this.background,
    required this.appBarColor,
    required this.appBarForeground,
    required this.outgoingBubble,
    required this.incomingBubble,
    required this.outgoingText,
    required this.incomingText,
    required this.metaText,
    required this.inputBarColor,
    required this.readReceiptColor,
    required this.dateSeparatorBackground,
    required this.dateSeparatorText,
    required this.onlineColor,
    this.bubbleRadius = 14,
  });

  /// Classic WhatsApp-style light theme.
  factory ChatTheme.whatsapp() => const ChatTheme(
    primary: Color(0xFF075E54),
    background: Color(0xFFECE5DD),
    appBarColor: Color(0xFF075E54),
    appBarForeground: Colors.white,
    outgoingBubble: Color(0xFFDCF8C6),
    incomingBubble: Colors.white,
    outgoingText: Color(0xFF111111),
    incomingText: Color(0xFF111111),
    metaText: Color(0xFF667781),
    inputBarColor: Color(0xFFF0F0F0),
    readReceiptColor: Color(0xFF34B7F1),
    dateSeparatorBackground: Color(0xFFD7E3E8),
    dateSeparatorText: Color(0xFF54656F),
    onlineColor: Color(0xFF25D366),
  );

  /// Neutral light theme with a blue accent. A good starting point for apps
  /// that aren't going for the WhatsApp look.
  factory ChatTheme.light() => const ChatTheme(
    primary: Color(0xFF2563EB),
    background: Color(0xFFF1F5F9),
    appBarColor: Color(0xFFFFFFFF),
    appBarForeground: Color(0xFF0F172A),
    outgoingBubble: Color(0xFF2563EB),
    incomingBubble: Color(0xFFFFFFFF),
    outgoingText: Color(0xFFFFFFFF),
    incomingText: Color(0xFF0F172A),
    metaText: Color(0xFF64748B),
    inputBarColor: Color(0xFFFFFFFF),
    readReceiptColor: Color(0xFF2563EB),
    dateSeparatorBackground: Color(0xFFE2E8F0),
    dateSeparatorText: Color(0xFF475569),
    onlineColor: Color(0xFF22C55E),
  );

  /// Neutral dark theme.
  factory ChatTheme.dark() => const ChatTheme(
    primary: Color(0xFF00A884),
    background: Color(0xFF0B141A),
    appBarColor: Color(0xFF1F2C34),
    appBarForeground: Colors.white,
    outgoingBubble: Color(0xFF005C4B),
    incomingBubble: Color(0xFF1F2C34),
    outgoingText: Color(0xFFE9EDEF),
    incomingText: Color(0xFFE9EDEF),
    metaText: Color(0xFF8696A0),
    inputBarColor: Color(0xFF1F2C34),
    readReceiptColor: Color(0xFF53BDEB),
    dateSeparatorBackground: Color(0xFF1D282F),
    dateSeparatorText: Color(0xFF8696A0),
    onlineColor: Color(0xFF25D366),
  );

  /// Pure-black dark theme for OLED screens.
  factory ChatTheme.amoled() => const ChatTheme(
    primary: Color(0xFF3B82F6),
    background: Color(0xFF000000),
    appBarColor: Color(0xFF0A0A0A),
    appBarForeground: Color(0xFFF9FAFB),
    outgoingBubble: Color(0xFF1D4ED8),
    incomingBubble: Color(0xFF141414),
    outgoingText: Color(0xFFF9FAFB),
    incomingText: Color(0xFFF9FAFB),
    metaText: Color(0xFF8A8A8A),
    inputBarColor: Color(0xFF0A0A0A),
    readReceiptColor: Color(0xFF60A5FA),
    dateSeparatorBackground: Color(0xFF141414),
    dateSeparatorText: Color(0xFF8A8A8A),
    onlineColor: Color(0xFF22C55E),
  );

  /// Primary accent color used for highlights and buttons.
  final Color primary;

  /// Background color of the chat surface.
  final Color background;

  /// Background color of the app bar.
  final Color appBarColor;

  /// Foreground (text/icon) color of the app bar.
  final Color appBarForeground;

  /// Background color of outgoing message bubbles.
  final Color outgoingBubble;

  /// Background color of incoming message bubbles.
  final Color incomingBubble;

  /// Text color inside outgoing message bubbles.
  final Color outgoingText;

  /// Text color inside incoming message bubbles.
  final Color incomingText;

  /// Timestamps and small captions.
  final Color metaText;

  /// Background color of the message input bar.
  final Color inputBarColor;

  /// "Read" (blue) tick color.
  final Color readReceiptColor;

  /// Background color of the date separator chip.
  final Color dateSeparatorBackground;

  /// Text color of the date separator chip.
  final Color dateSeparatorText;

  /// Color used to indicate that a user is online.
  final Color onlineColor;

  /// Corner radius applied to message bubbles.
  final double bubbleRadius;

  /// Returns a copy of this theme with the given fields replaced. Handy for
  /// deriving a variant from a preset, e.g.
  /// `ChatTheme.dark().copyWith(primary: brandColor)`.
  ChatTheme copyWith({
    Color? primary,
    Color? background,
    Color? appBarColor,
    Color? appBarForeground,
    Color? outgoingBubble,
    Color? incomingBubble,
    Color? outgoingText,
    Color? incomingText,
    Color? metaText,
    Color? inputBarColor,
    Color? readReceiptColor,
    Color? dateSeparatorBackground,
    Color? dateSeparatorText,
    Color? onlineColor,
    double? bubbleRadius,
  }) {
    return ChatTheme(
      primary: primary ?? this.primary,
      background: background ?? this.background,
      appBarColor: appBarColor ?? this.appBarColor,
      appBarForeground: appBarForeground ?? this.appBarForeground,
      outgoingBubble: outgoingBubble ?? this.outgoingBubble,
      incomingBubble: incomingBubble ?? this.incomingBubble,
      outgoingText: outgoingText ?? this.outgoingText,
      incomingText: incomingText ?? this.incomingText,
      metaText: metaText ?? this.metaText,
      inputBarColor: inputBarColor ?? this.inputBarColor,
      readReceiptColor: readReceiptColor ?? this.readReceiptColor,
      dateSeparatorBackground:
          dateSeparatorBackground ?? this.dateSeparatorBackground,
      dateSeparatorText: dateSeparatorText ?? this.dateSeparatorText,
      onlineColor: onlineColor ?? this.onlineColor,
      bubbleRadius: bubbleRadius ?? this.bubbleRadius,
    );
  }

  /// Linearly interpolates between [a] and [b] by [t] (0.0 → [a], 1.0 → [b]).
  /// Useful for animating a theme switch.
  // ignore: prefer_constructors_over_static_methods  // mirrors Color.lerp
  static ChatTheme lerp(ChatTheme a, ChatTheme b, double t) {
    return ChatTheme(
      primary: Color.lerp(a.primary, b.primary, t)!,
      background: Color.lerp(a.background, b.background, t)!,
      appBarColor: Color.lerp(a.appBarColor, b.appBarColor, t)!,
      appBarForeground:
          Color.lerp(a.appBarForeground, b.appBarForeground, t)!,
      outgoingBubble: Color.lerp(a.outgoingBubble, b.outgoingBubble, t)!,
      incomingBubble: Color.lerp(a.incomingBubble, b.incomingBubble, t)!,
      outgoingText: Color.lerp(a.outgoingText, b.outgoingText, t)!,
      incomingText: Color.lerp(a.incomingText, b.incomingText, t)!,
      metaText: Color.lerp(a.metaText, b.metaText, t)!,
      inputBarColor: Color.lerp(a.inputBarColor, b.inputBarColor, t)!,
      readReceiptColor:
          Color.lerp(a.readReceiptColor, b.readReceiptColor, t)!,
      dateSeparatorBackground: Color.lerp(
        a.dateSeparatorBackground,
        b.dateSeparatorBackground,
        t,
      )!,
      dateSeparatorText:
          Color.lerp(a.dateSeparatorText, b.dateSeparatorText, t)!,
      onlineColor: Color.lerp(a.onlineColor, b.onlineColor, t)!,
      bubbleRadius: a.bubbleRadius + (b.bubbleRadius - a.bubbleRadius) * t,
    );
  }

  /// Lets descendant widgets read the active [ChatTheme]. Falls back to the
  /// WhatsApp preset if no [ChatThemeProvider] is in the tree.
  // ignore: prefer_constructors_over_static_methods  // public API lookup
  static ChatTheme of(BuildContext context) {
    final inherited = context
        .dependOnInheritedWidgetOfExactType<ChatThemeProvider>();
    return inherited?.theme ?? ChatTheme.whatsapp();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatTheme &&
        other.primary == primary &&
        other.background == background &&
        other.appBarColor == appBarColor &&
        other.appBarForeground == appBarForeground &&
        other.outgoingBubble == outgoingBubble &&
        other.incomingBubble == incomingBubble &&
        other.outgoingText == outgoingText &&
        other.incomingText == incomingText &&
        other.metaText == metaText &&
        other.inputBarColor == inputBarColor &&
        other.readReceiptColor == readReceiptColor &&
        other.dateSeparatorBackground == dateSeparatorBackground &&
        other.dateSeparatorText == dateSeparatorText &&
        other.onlineColor == onlineColor &&
        other.bubbleRadius == bubbleRadius;
  }

  @override
  int get hashCode => Object.hash(
    primary,
    background,
    appBarColor,
    appBarForeground,
    outgoingBubble,
    incomingBubble,
    outgoingText,
    incomingText,
    metaText,
    inputBarColor,
    readReceiptColor,
    dateSeparatorBackground,
    dateSeparatorText,
    onlineColor,
    bubbleRadius,
  );
}

/// Provides a [ChatTheme] down the widget tree. Read it with [ChatTheme.of].
class ChatThemeProvider extends InheritedWidget {
  /// Creates a provider that exposes [theme] to descendants.
  const ChatThemeProvider({
    required this.theme,
    required super.child,
    super.key,
  });

  /// The chat theme made available to descendant widgets.
  final ChatTheme theme;

  @override
  bool updateShouldNotify(ChatThemeProvider oldWidget) =>
      oldWidget.theme != theme;
}
