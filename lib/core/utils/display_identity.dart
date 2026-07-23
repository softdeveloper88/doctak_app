import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Title-case display names for people, organizations, and groups.
/// Preserves mixed-case brands (TutorXMath) and short acronyms (CME).
String formatDisplayName(String? value, [String fallback = '']) {
  final raw = (value ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
  if (raw.isEmpty) return fallback;
  return raw
      .split(' ')
      .map((word) {
        return word.splitMapJoin(
          RegExp(r"([-'])"),
          onMatch: (m) => m.group(0)!,
          onNonMatch: (part) {
            if (part.isEmpty) return part;
            final hasLower = RegExp(r'[a-z]').hasMatch(part);
            final hasInnerUpper = RegExp(r'[A-Z]').hasMatch(part.length > 1 ? part.substring(1) : '');
            if (hasLower && hasInnerUpper) return part;
            if (part.length <= 5 &&
                part == part.toUpperCase() &&
                RegExp(r'[A-Z]').hasMatch(part)) {
              return part;
            }
            return part[0].toUpperCase() + part.substring(1).toLowerCase();
          },
        );
      })
      .join(' ');
}

enum DefaultAvatarKind { user, organization, group }

String normalizeAvatarGender(String? gender) {
  final value = (gender ?? '').trim().toLowerCase();
  if (value.isEmpty) return 'unknown';
  if (value == 'male' || value == 'm' || value == 'man') return 'male';
  if (value == 'female' || value == 'f' || value == 'woman' || value == 'w') {
    return 'female';
  }
  if (value == 'other' || value == 'non-binary' || value == 'nonbinary' || value == 'nb') {
    return 'other';
  }
  return 'unknown';
}

/// Logical asset path (kept for URL/legacy checks). Artwork is inlined — see
/// [defaultAvatarSvg] — so Shorebird patches and missing bundle files never
/// throw `Unable to load asset`.
String defaultAvatarAsset({
  DefaultAvatarKind kind = DefaultAvatarKind.user,
  String? gender,
}) {
  switch (kind) {
    case DefaultAvatarKind.organization:
      return 'assets/images/avatars/default-organization.svg';
    case DefaultAvatarKind.group:
      return 'assets/images/avatars/default-group.svg';
    case DefaultAvatarKind.user:
      final normalized = normalizeAvatarGender(gender);
      if (normalized == 'male') return 'assets/images/avatars/default-male.svg';
      if (normalized == 'female') return 'assets/images/avatars/default-female.svg';
      return 'assets/images/avatars/default-neutral.svg';
  }
}

/// Inlined SVG for default avatars (no AssetBundle dependency).
String defaultAvatarSvg({
  DefaultAvatarKind kind = DefaultAvatarKind.user,
  String? gender,
}) {
  switch (kind) {
    case DefaultAvatarKind.organization:
      return _kOrgSvg;
    case DefaultAvatarKind.group:
      return _kGroupSvg;
    case DefaultAvatarKind.user:
      final normalized = normalizeAvatarGender(gender);
      if (normalized == 'male') return _kMaleSvg;
      if (normalized == 'female') return _kFemaleSvg;
      return _kNeutralSvg;
  }
}

/// Whether [url] is one of our generated defaults (prefer local artwork offline).
bool isDefaultAvatarUrl(String? url) {
  final value = (url ?? '').toLowerCase();
  return value.contains('/avatars/default-') ||
      value.contains('assets/images/avatars/default-') ||
      value.endsWith('img_avtar.png');
}

Widget buildDefaultAvatarWidget({
  required double size,
  DefaultAvatarKind kind = DefaultAvatarKind.user,
  String? gender,
}) {
  Widget drawnFallback() {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DefaultAvatarPainter(kind: kind, color: Colors.grey),
      ),
    );
  }

  return SvgPicture.string(
    defaultAvatarSvg(kind: kind, gender: gender),
    width: size,
    height: size,
    fit: BoxFit.cover,
    placeholderBuilder: (_) => drawnFallback(),
    errorBuilder: (_, __, ___) => drawnFallback(),
  );
}

/// Draws simple person / building / group silhouettes without any icon font.
class _DefaultAvatarPainter extends CustomPainter {
  _DefaultAvatarPainter({required this.kind, required this.color});

  final DefaultAvatarKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final o = Offset((size.width - s) / 2, (size.height - s) / 2);
    final fill = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.06
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (kind) {
      case DefaultAvatarKind.organization:
        final rect = Rect.fromLTWH(
          o.dx + s * 0.26,
          o.dy + s * 0.2,
          s * 0.48,
          s * 0.6,
        );
        canvas.drawRect(rect, stroke);
        for (var row = 0; row < 3; row++) {
          for (var col = 0; col < 2; col++) {
            canvas.drawRect(
              Rect.fromLTWH(
                o.dx + s * (0.34 + col * 0.2),
                o.dy + s * (0.28 + row * 0.16),
                s * 0.1,
                s * 0.08,
              ),
              fill,
            );
          }
        }
        break;
      case DefaultAvatarKind.group:
        canvas.drawCircle(o + Offset(s * 0.35, s * 0.36), s * 0.13, fill);
        canvas.drawCircle(o + Offset(s * 0.65, s * 0.36), s * 0.13, fill);
        canvas.drawArc(
          Rect.fromCenter(
            center: o + Offset(s * 0.35, s * 0.78),
            width: s * 0.4,
            height: s * 0.36,
          ),
          3.14,
          3.14,
          true,
          fill,
        );
        canvas.drawArc(
          Rect.fromCenter(
            center: o + Offset(s * 0.65, s * 0.78),
            width: s * 0.4,
            height: s * 0.36,
          ),
          3.14,
          3.14,
          true,
          fill,
        );
        break;
      case DefaultAvatarKind.user:
        canvas.drawCircle(o + Offset(s * 0.5, s * 0.36), s * 0.17, fill);
        canvas.drawArc(
          Rect.fromCenter(
            center: o + Offset(s * 0.5, s * 0.88),
            width: s * 0.62,
            height: s * 0.56,
          ),
          3.14,
          3.14,
          true,
          fill,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _DefaultAvatarPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.color != color;
}

// Unique gradient ids per SVG avoid flutter_svg collisions when many avatars
// share the screen.
const _kNeutralSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 160 160" role="img" aria-label="Default doctor avatar">
  <defs>
    <linearGradient id="dn-bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#4B8FBF"/>
      <stop offset="100%" stop-color="#2F6F98"/>
    </linearGradient>
    <linearGradient id="dn-coat" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#F7FAFC"/>
      <stop offset="100%" stop-color="#E6EEF4"/>
    </linearGradient>
  </defs>
  <circle cx="80" cy="80" r="80" fill="url(#dn-bg)"/>
  <circle cx="80" cy="62" r="28" fill="#E8C3A4"/>
  <path d="M46 56c4-16 14-26 34-26s30 10 34 26c-8-6-20-10-34-10s-26 4-34 10z" fill="#3D2C24"/>
  <path d="M36 148c4-34 22-50 44-50s40 16 44 50" fill="url(#dn-coat)"/>
  <path d="M68 98h24v42H68z" fill="#2F6F98"/>
  <circle cx="80" cy="112" r="4.5" fill="#7BC4A0"/>
  <path d="M72 112h16" stroke="#57A882" stroke-width="2" stroke-linecap="round"/>
</svg>
''';

const _kMaleSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 160 160" role="img" aria-label="Default male doctor avatar">
  <defs>
    <linearGradient id="dm-bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#1B7BC7"/>
      <stop offset="100%" stop-color="#0F5A95"/>
    </linearGradient>
    <linearGradient id="dm-coat" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#F8FBFF"/>
      <stop offset="100%" stop-color="#E4EEF8"/>
    </linearGradient>
  </defs>
  <circle cx="80" cy="80" r="80" fill="url(#dm-bg)"/>
  <circle cx="80" cy="62" r="28" fill="#F0C7A4"/>
  <path d="M48 58c2-18 14-30 32-30s30 12 32 30c-6-8-18-12-32-12s-26 4-32 12z" fill="#3A2A22"/>
  <path d="M36 148c4-34 22-50 44-50s40 16 44 50" fill="url(#dm-coat)"/>
  <path d="M68 98h24v42H68z" fill="#0F5A95"/>
  <circle cx="80" cy="112" r="4.5" fill="#F4C15D"/>
  <path d="M72 112h16" stroke="#D9A63E" stroke-width="2" stroke-linecap="round"/>
</svg>
''';

const _kFemaleSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 160 160" role="img" aria-label="Default female doctor avatar">
  <defs>
    <linearGradient id="df-bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#5B8DEF"/>
      <stop offset="100%" stop-color="#3B6BC8"/>
    </linearGradient>
    <linearGradient id="df-coat" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#FFFBFA"/>
      <stop offset="100%" stop-color="#F0E8F2"/>
    </linearGradient>
  </defs>
  <circle cx="80" cy="80" r="80" fill="url(#df-bg)"/>
  <path d="M34 78c4-36 20-52 46-52s42 16 46 52c-8-18-24-28-46-28S42 60 34 78z" fill="#2C1B16"/>
  <circle cx="80" cy="64" r="27" fill="#F3C3A3"/>
  <path d="M44 78c6 22 18 34 36 34s30-12 36-34c-8 10-20 16-36 16S52 88 44 78z" fill="#2C1B16"/>
  <path d="M36 148c4-34 22-50 44-50s40 16 44 50" fill="url(#df-coat)"/>
  <path d="M68 98h24v42H68z" fill="#3B6BC8"/>
  <circle cx="80" cy="112" r="4.5" fill="#E8A0B8"/>
  <path d="M72 112h16" stroke="#C97995" stroke-width="2" stroke-linecap="round"/>
</svg>
''';

const _kGroupSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 160 160" role="img" aria-label="Default group avatar">
  <defs>
    <linearGradient id="dg-bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#2563EB"/>
      <stop offset="100%" stop-color="#1D4ED8"/>
    </linearGradient>
  </defs>
  <rect width="160" height="160" rx="28" fill="url(#dg-bg)"/>
  <circle cx="80" cy="54" r="18" fill="#DBEAFE"/>
  <circle cx="48" cy="64" r="14" fill="#BFDBFE"/>
  <circle cx="112" cy="64" r="14" fill="#BFDBFE"/>
  <path d="M40 124c4-24 18-36 40-36s36 12 40 36" fill="#EFF6FF"/>
  <path d="M28 120c2-16 10-24 22-24 4 8 12 14 30 16" fill="#DBEAFE"/>
  <path d="M132 120c-2-16-10-24-22-24-4 8-12 14-30 16" fill="#DBEAFE"/>
</svg>
''';

const _kOrgSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 160 160" role="img" aria-label="Default organization avatar">
  <defs>
    <linearGradient id="do-bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#0F766E"/>
      <stop offset="100%" stop-color="#115E59"/>
    </linearGradient>
  </defs>
  <rect width="160" height="160" rx="28" fill="url(#do-bg)"/>
  <rect x="42" y="38" width="76" height="84" rx="8" fill="#ECFDF8"/>
  <rect x="52" y="50" width="18" height="14" rx="2" fill="#99F6E4"/>
  <rect x="76" y="50" width="18" height="14" rx="2" fill="#99F6E4"/>
  <rect x="100" y="50" width="8" height="14" rx="2" fill="#99F6E4"/>
  <rect x="52" y="72" width="18" height="14" rx="2" fill="#99F6E4"/>
  <rect x="76" y="72" width="18" height="14" rx="2" fill="#99F6E4"/>
  <rect x="100" y="72" width="8" height="14" rx="2" fill="#99F6E4"/>
  <rect x="66" y="96" width="28" height="26" rx="4" fill="#0F766E"/>
</svg>
''';
