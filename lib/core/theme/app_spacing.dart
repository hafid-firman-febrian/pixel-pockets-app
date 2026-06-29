import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  
  static const double s2 = 2;
  static const double s4 = 4;
  static const double s6 = 6;
  static const double s8 = 8;
  static const double s10 = 10;
  static const double s12 = 12;
  static const double s14 = 14;
  static const double s16 = 16;
  static const double s24 = 24;
  static const double s32 = 32;

  
  
  static const EdgeInsets screen = EdgeInsets.symmetric(horizontal: s16);

  
  static const EdgeInsets screenAll = EdgeInsets.all(s16);

  
  
  static const EdgeInsets header = EdgeInsets.symmetric(
    horizontal: s16,
    vertical: s12,
  );

  
  static const EdgeInsets headerSm = EdgeInsets.symmetric(
    horizontal: s16,
    vertical: s8,
  );

  
  
  static const EdgeInsets sectionLabel = EdgeInsets.fromLTRB(s16, s8, s16, s4);

  
  
  static const EdgeInsets card = EdgeInsets.all(s16);
  static const EdgeInsets cardSm = EdgeInsets.all(s12);

  
  
  static const EdgeInsets listItemSm = EdgeInsets.symmetric(
    horizontal: s12,
    vertical: s10,
  );

  
  static const EdgeInsets listItem = EdgeInsets.symmetric(
    horizontal: s16,
    vertical: s10,
  );

  
  
  static const EdgeInsets chip = EdgeInsets.symmetric(
    horizontal: s10,
    vertical: s4,
  );

  
  
  static const EdgeInsets input = EdgeInsets.symmetric(
    horizontal: s12,
    vertical: s10,
  );

  
  
  static const EdgeInsets form = EdgeInsets.all(s16);

  
  
  static const EdgeInsets iconBtn = EdgeInsets.all(s10);

  
  
  static const EdgeInsets navItem = EdgeInsets.fromLTRB(s4, s10, s4, s12);

  
  static const EdgeInsets fab = EdgeInsets.fromLTRB(s16, 0, s16, s12);

  static const double section = s16;

  static const double item = s12;
}
