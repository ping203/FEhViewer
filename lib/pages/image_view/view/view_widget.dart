import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:fehviewer/common/service/depth_service.dart';
import 'package:fehviewer/generated/l10n.dart';
import 'package:fehviewer/models/index.dart';
import 'package:fehviewer/network/gallery_request.dart';
import 'package:fehviewer/pages/gallery/controller/gallery_page_controller.dart';
import 'package:fehviewer/pages/image_view/controller/view_controller.dart';
import 'package:fehviewer/utils/logger.dart';
import 'package:fehviewer/utils/toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:liquid_progress_indicator/liquid_progress_indicator.dart';

class GalleryImage extends StatefulWidget {
  const GalleryImage({
    Key key,
    @required this.index,
  }) : super(key: key);

  @override
  _GalleryImageState createState() => _GalleryImageState();
  final int index;
}

class _GalleryImageState extends State<GalleryImage> {
  Future<GalleryPreview> _future;
  final CancelToken _getMoreCancelToken = CancelToken();

  GalleryPageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = Get.find(tag: pageCtrlDepth);
    _future = _pageController.getImageInfo(widget.index,
        cancelToken: _getMoreCancelToken);
  }

  @override
  void dispose() {
    super.dispose();
    // _getMoreCancelToken.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final GalleryPreview _currentPreview =
        _pageController.galleryItem.galleryPreview[widget.index];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () {
        logger.d('long press');

        showImageSheet(context, _currentPreview.largeImageUrl, () {
          setState(() {
            _future = _pageController.getImageInfo(widget.index,
                cancelToken: _getMoreCancelToken);
          });
        });
      },
      child: FutureBuilder<GalleryPreview>(
        future: _future,
        builder: (_, AsyncSnapshot<GalleryPreview> previewFromApi) {
          if (_currentPreview.largeImageUrl == null ||
              _currentPreview.largeImageHeight == null) {
            if (previewFromApi.connectionState == ConnectionState.done) {
              if (previewFromApi.hasError) {
                // todo 加载异常
                logger.e(' ${previewFromApi.error}');
                return Container(
                  alignment: Alignment.center,
                  constraints: BoxConstraints(
                    maxHeight: context.width * 0.8,
                  ),
                  // padding: const EdgeInsets.symmetric(vertical: 50),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error,
                        size: 50,
                        color: Colors.red,
                      ),
                      Text(
                        '${widget.index + 1}',
                        style: const TextStyle(
                            color: CupertinoColors.secondarySystemBackground),
                      ),
                    ],
                  ),
                );
              } else {
                _currentPreview.largeImageUrl =
                    previewFromApi.data.largeImageUrl;
                _currentPreview.largeImageHeight =
                    previewFromApi.data.largeImageHeight;
                _currentPreview.largeImageWidth =
                    previewFromApi.data.largeImageWidth;

                Future.delayed(const Duration(milliseconds: 100)).then((value) {
                  Get.find<ViewController>()
                      .update(['GalleryImage_${widget.index}']);
                });

                return _buildImage(_currentPreview.largeImageUrl);
              }
            } else {
              return UnconstrainedBox(
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: context.mediaQueryShortestSide,
                    minWidth: context.width / 2,
                  ),
                  // margin:
                  //     const EdgeInsets.symmetric(vertical: 50, horizontal: 50),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        '${widget.index + 1}',
                        style: const TextStyle(
                          fontSize: 50,
                          color: CupertinoColors.systemGrey6,
                        ),
                      ),
                      const Text(
                        '获取中...',
                        style: TextStyle(
                          color: CupertinoColors.systemGrey6,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          } else {
            // 返回图片组件
            final String url = _currentPreview.largeImageUrl;
            return _buildImage(url);
          }
        },
      ),
    );
  }

  Widget _buildImage(String url) {
    return Container(
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.contain,
        fadeInDuration: const Duration(milliseconds: 100),
        fadeOutDuration: const Duration(milliseconds: 100),
        progressIndicatorBuilder: (context, url, downloadProgress) {
          // 下载进度回调
          return UnconstrainedBox(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: context.mediaQueryShortestSide,
                minWidth: context.width / 2,
              ),
              alignment: Alignment.center,
              // margin: const EdgeInsets.symmetric(vertical: 50, horizontal: 50),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    height: 70,
                    width: 70,
                    child: LiquidCircularProgressIndicator(
                      value: downloadProgress.progress ?? 0.0,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color.fromARGB(255, 163, 199, 100)),
                      backgroundColor: const Color.fromARGB(255, 50, 50, 50),
                      // borderColor: Colors.teal[900],
                      // borderWidth: 2.0,
                      direction: Axis.vertical,
                      center: downloadProgress.progress != null
                          ? Text(
                              '${(downloadProgress.progress ?? 0) * 100 ~/ 1}%',
                              style: TextStyle(
                                color: downloadProgress.progress < 0.5
                                    ? CupertinoColors.white
                                    : CupertinoColors.black,
                                fontSize: 12,
                                height: 1,
                              ),
                            )
                          : Container(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      '${widget.index + 1}',
                      style: const TextStyle(
                        color: CupertinoColors.systemGrey6,
                        height: 1,
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        },
        errorWidget: (context, url, error) => const Center(
          child: Icon(
            Icons.error,
            size: 50,
            color: Colors.red,
          ),
        ),
      ),
    );
  }
}

/// 页面滑条
class PageSlider extends StatefulWidget {
  const PageSlider({
    Key key,
    @required this.max,
    @required this.sliderValue,
    @required this.onChangedEnd,
    @required this.onChanged,
  }) : super(key: key);

  final double max;
  final double sliderValue;
  final ValueChanged<double> onChangedEnd;
  final ValueChanged<double> onChanged;

  @override
  _PageSliderState createState() => _PageSliderState();
}

class _PageSliderState extends State<PageSlider> {
  double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.sliderValue;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _value = widget.sliderValue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        children: <Widget>[
          Text(
            '${widget.sliderValue.round() + 1}',
            style: const TextStyle(color: CupertinoColors.systemGrey6),
          ),
          Expanded(
            child: CupertinoSlider(
                min: 0,
                max: widget.max,
                value: widget.sliderValue,
                onChanged: (double newValue) {
                  setState(() {
                    _value = newValue;
                  });
                  widget.onChanged(newValue);
                },
                onChangeEnd: (double newValue) {
                  widget.onChangedEnd(newValue);
                }),
          ),
          Text(
            '${widget.max.round() + 1}',
            style: const TextStyle(color: CupertinoColors.systemGrey6),
          ),
        ],
      ),
    );
  }
}

typedef DidFinishLayoutCallBack = dynamic Function(
    int firstIndex, int lastIndex);

class ViewChildBuilderDelegate extends SliverChildBuilderDelegate {
  ViewChildBuilderDelegate(
    Widget Function(BuildContext, int) builder, {
    int childCount,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    this.onDidFinishLayout,
  }) : super(builder,
            childCount: childCount,
            addAutomaticKeepAlives: addAutomaticKeepAlives,
            addRepaintBoundaries: addRepaintBoundaries);

  final DidFinishLayoutCallBack onDidFinishLayout;

  @override
  void didFinishLayout(int firstIndex, int lastIndex) {
    onDidFinishLayout(firstIndex, lastIndex);
    // print('firstIndex: $firstIndex, lastIndex: $lastIndex');
  }
}

Future<void> showShareActionSheet(BuildContext context, String imageUrl) {
  return showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        final CupertinoActionSheet dialog = CupertinoActionSheet(
          cancelButton: CupertinoActionSheetAction(
              onPressed: () {
                Get.back();
              },
              child: Text(S.of(context).cancel)),
          actions: <Widget>[
            CupertinoActionSheetAction(
                onPressed: () {
                  logger.v('保存到相册');
                  Api.saveImage(context, imageUrl).then((rult) {
                    Get.back();
                    if (rult != null && rult) {
                      showToast('保存成功');
                    }
                  }).catchError((e) {
                    showToast(e);
                  });
                },
                child: const Text('保存到相册')),
            CupertinoActionSheetAction(
                onPressed: () {
                  logger.v('系统分享');
                  Api.shareImage(imageUrl);
                },
                child: const Text('系统分享')),
          ],
        );
        return dialog;
      });
}

Future<void> showImageSheet(
    BuildContext context, String imageUrl, VoidCallback reload) {
  return showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        final CupertinoActionSheet dialog = CupertinoActionSheet(
          cancelButton: CupertinoActionSheetAction(
              onPressed: () {
                Get.back();
              },
              child: Text(S.of(context).cancel)),
          actions: <Widget>[
            CupertinoActionSheetAction(
                onPressed: () {
                  reload();
                  Get.back();
                },
                child: Text(S.of(context).reload_image)),
            CupertinoActionSheetAction(
                onPressed: () {
                  Get.back();
                  showShareActionSheet(context, imageUrl);
                },
                child: Text(S.of(context).share_image)),
          ],
        );
        return dialog;
      });
}
