import 'package:fehviewer/generated/l10n.dart';
import 'package:fehviewer/pages/item/setting_item.dart';
import 'package:fehviewer/pages/tab/controller/tabhome_controller.dart';
import 'package:fehviewer/route/routes.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

class SettingViewController extends GetxController
    with SingleGetTickerProviderMixin {
  // 控制middle显示
  final RxBool _showMiddle = false.obs;
  bool get showMidle => _showMiddle.value;
  set showMidle(bool val) => _showMiddle.value = val;

  //
  Animation<double> animation;
  AnimationController _animationController;

  final ScrollController _scrollController =
      tabPages.scrollControllerMap[EHRoutes.setting];

  @override
  void onInit() {
    super.onInit();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    animation = Tween(begin: 0.0, end: 1.0).animate(_animationController);

    // 监听滚动
    _scrollController.addListener(_scrollControllerLister);
  }

  void _scrollControllerLister() {
    if (_scrollController.offset < 50.0 && showMidle) {
      _animationController.reverse();
      showMidle = false;
    } else if (_scrollController.offset >= 50.0 && !showMidle) {
      _animationController.forward();
      showMidle = true;
    }
  }

  @override
  void onClose() {
    _animationController.dispose();
    super.onClose();
  }

  // 菜单文案
  var _itemTitles = [];

  var _icons = [];

  var _routes = [];

  List getItemList() {
    List _slivers = [];
    for (int _index = 0; _index < _itemTitles.length + 1; _index++) {
      if (_index == 0) {
        // _slivers.add(Get.find<EhConfigService>().isSafeMode.value ?? false
        //     ? Container()
        //     : UserItem());
        _slivers.add(const SizedBox());
      } else {
        _slivers.add(SettingItems(
          text: _itemTitles[_index - 1],
          icon: _icons[_index - 1],
          route: _routes[_index - 1],
        ));
      }
    }
//    logger.v('${_slivers.length}');
    return _slivers;
  }

  void initData(BuildContext context) {
    _itemTitles = <String>[
      S.of(context).eh,
      S.of(context).download,
      S.of(context).advanced,
      // '安全设置',
      S.of(context).about,
    ];

    _icons = <IconData>[
      FontAwesomeIcons.cookieBite,
      FontAwesomeIcons.download,
      FontAwesomeIcons.tools,
      // FontAwesomeIcons.shieldAlt,
      FontAwesomeIcons.infoCircle,
    ];

    _routes = <String>[
      EHRoutes.ehSetting,
      EHRoutes.downloadSetting,
      EHRoutes.advancedSetting,
      // '',
      EHRoutes.about,
    ];
  }
}
