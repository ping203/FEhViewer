import 'dart:ui';

import 'package:fehviewer/common/global.dart';
import 'package:fehviewer/models/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'base_service.dart';

class LocaleService extends ProfileService {
  RxString localCode = window.locale.toString().obs;

  Locale get locale {
    final String localeSt = localCode.value;
    if (localeSt == null ||
        localeSt.isEmpty ||
        localeSt == '_' ||
        !localeSt.contains('_')) {
      // return window.locale;
      return null;
    }
    final List<String> t = localeSt.split('_');
    return Locale(t[0], t[1]);
  }

  @override
  void onInit() {
    super.onInit();
    final Profile _profile = Global.profile;

    localCode.value = _profile.locale;
    everProfile<String>(localCode, (String value) {
      _profile.locale = value;
    });
  }
}
