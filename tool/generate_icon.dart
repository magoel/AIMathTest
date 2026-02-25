// Generates app icon as SVG, then we convert to PNG
// Run: dart run tool/generate_icon.dart

import 'dart:io';

void main() {
  const size = 1024;
  const half = size / 2;

  // Math + AI Bot icon: A friendly robot face with math symbols
  // on a vibrant blue-purple gradient background
  final svg = '''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $size $size" width="$size" height="$size">
  <defs>
    <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#4F46E5"/>
      <stop offset="100%" style="stop-color:#7C3AED"/>
    </linearGradient>
    <linearGradient id="botBody" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" style="stop-color:#FFFFFF"/>
      <stop offset="100%" style="stop-color:#E0E7FF"/>
    </linearGradient>
  </defs>

  <!-- Background with rounded corners -->
  <rect width="$size" height="$size" rx="220" fill="url(#bg)"/>

  <!-- Math symbols scattered in background -->
  <text x="140" y="220" font-family="Arial" font-size="120" font-weight="bold" fill="rgba(255,255,255,0.15)" transform="rotate(-15,140,200)">+</text>
  <text x="780" y="250" font-family="Arial" font-size="100" font-weight="bold" fill="rgba(255,255,255,0.15)" transform="rotate(10,800,230)">×</text>
  <text x="100" y="850" font-family="Arial" font-size="110" font-weight="bold" fill="rgba(255,255,255,0.15)" transform="rotate(20,120,830)">÷</text>
  <text x="800" y="880" font-family="Arial" font-size="90" font-weight="bold" fill="rgba(255,255,255,0.12)" transform="rotate(-10,820,860)">π</text>
  <text x="150" y="530" font-family="Arial" font-size="80" font-weight="bold" fill="rgba(255,255,255,0.1)">∑</text>
  <text x="820" y="580" font-family="Arial" font-size="85" font-weight="bold" fill="rgba(255,255,255,0.1)">%</text>

  <!-- Robot head (rounded rectangle) -->
  <rect x="270" y="280" width="484" height="420" rx="80" fill="url(#botBody)" stroke="#C7D2FE" stroke-width="8"/>

  <!-- Antenna -->
  <line x1="$half" y1="280" x2="$half" y2="200" stroke="#C7D2FE" stroke-width="12" stroke-linecap="round"/>
  <circle cx="$half" cy="185" r="25" fill="#34D399"/>
  <circle cx="$half" cy="185" r="12" fill="#6EE7B7"/>

  <!-- Eyes -->
  <circle cx="400" cy="460" r="55" fill="#4F46E5"/>
  <circle cx="624" cy="460" r="55" fill="#4F46E5"/>
  <!-- Eye highlights -->
  <circle cx="418" cy="445" r="18" fill="#FFFFFF"/>
  <circle cx="642" cy="445" r="18" fill="#FFFFFF"/>
  <!-- Eye inner -->
  <circle cx="400" cy="460" r="20" fill="#1E1B4B"/>
  <circle cx="624" cy="460" r="20" fill="#1E1B4B"/>

  <!-- Smile -->
  <path d="M 420 560 Q $half 630 604 560" fill="none" stroke="#4F46E5" stroke-width="14" stroke-linecap="round"/>

  <!-- Ears / side panels -->
  <rect x="228" y="410" width="50" height="100" rx="20" fill="#C7D2FE"/>
  <rect x="746" y="410" width="50" height="100" rx="20" fill="#C7D2FE"/>

  <!-- Math on the forehead: "1+1" -->
  <text x="$half" y="385" font-family="Arial" font-size="64" font-weight="bold" fill="#4F46E5" text-anchor="middle">1+1</text>

  <!-- Bottom text: "AI" badge -->
  <rect x="430" y="740" width="164" height="64" rx="32" fill="#34D399"/>
  <text x="$half" y="784" font-family="Arial" font-size="40" font-weight="bold" fill="#FFFFFF" text-anchor="middle">AI</text>
</svg>''';

  final file = File('assets/icon/app_icon.svg');
  file.writeAsStringSync(svg);
  print('SVG icon written to assets/icon/app_icon.svg');
  print('Convert to PNG using: magick convert assets/icon/app_icon.svg -resize 1024x1024 assets/icon/app_icon.png');
}
