// ── Centralized Theme Colors ────────────────────────────
import 'package:flutter/material.dart';

class StatusColors {
  // Normal Status
  static const Color normalPrimary = Color(0xFF1D9E75);
  static const Color normalBg = Color(0xFFE1F5EE);
  static const Color normalAccent = Color(0xFF5DCAA5);
  static const Color normalDark = Color(0xFF0F6E56);

  // Warning Status
  static const Color warningPrimary = Color(0xFFBA7517);
  static const Color warningBg = Color(0xFFFAEEDA);
  static const Color warningAccent = Color(0xFFEF9F27);
  static const Color warningDark = Color(0xFF633806);

  // Critical Status
  static const Color criticalPrimary = Color(0xFFE24B4A);
  static const Color criticalBg = Color(0xFFFCEBEB);
  static const Color criticalDark = Color(0xFFA32D2D);
  static const Color criticalSiren = Color(0xFFFAC775);

  // Neutral
  static const Color wheelDark = Color(0xFF444441);
  static const Color wheelGrey = Color(0xFF888780);
}

class PainterDimensions {
  // Normal Painter
  static const double normalFaceRadius = 42;
  static const double normalEyeRadius = 5;
  static const double normalSmileAmplitude = 8;
  static const double normalSmileOffset = 10;

  // Warning Painter
  static const double warningFaceRadius = 40;
  static const double warningEyeRadius = 5;
  static const double warningHandsRadius = 25;
  static const double warningHandsEndY = 10;
  static const double warningHandsHeadRadius = 5;
  static const double warningHandsHeadX = 27;

  // Critical Painter
  static const double criticalFaceRadius = 36;
  static const double criticalEyeRadius = 5;
  static const double criticalAmbulanceWidth = 96;
  static const double criticalAmbulanceHeight = 18;
  static const double criticalWheelRadius = 7;
  static const double criticalWheelCenterRadius = 4;
  static const double criticalSirenWidth = 10;
  static const double criticalSirenHeight = 8;
}
