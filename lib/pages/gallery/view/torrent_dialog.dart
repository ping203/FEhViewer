import 'package:fehviewer/common/service/depth_service.dart';
import 'package:fehviewer/const/const.dart';
import 'package:fehviewer/generated/l10n.dart';
import 'package:fehviewer/models/galleryTorrent.dart';
import 'package:fehviewer/pages/gallery/controller/torrent_controller.dart';
import 'package:fehviewer/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';

class TorrentView extends StatelessWidget {
  const TorrentView({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TorrentController controller = Get.find(tag: pageCtrlDepth);
    return Container(
      height: controller.torrents.length * 40.0 + 30,
      child: controller.obx(
        (String state) {
          return ListView.separated(
            padding: const EdgeInsets.all(0),
            itemBuilder: (_, int index) {
              final GalleryTorrent torrent = controller.torrents[index];
              return Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        torrent.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, height: 1),
                      ),
                      onPressed: () async {
                        final String torrentUrl =
                            '${EHConst.EH_TORRENT_URL}/$state/${torrent.hash}.torrent';
                        logger
                            .d('${torrent.name}\n${torrent.hash}\ntorrentUrl');
                        if (await canLaunch(torrentUrl)) {
                          await launch(torrentUrl);
                        } else {
                          throw 'Could not launch $torrentUrl';
                        }
                      },
                    ),
                  ),
                  CupertinoTheme(
                    data: const CupertinoThemeData(
                        primaryColor: CupertinoColors.systemRed),
                    child: CupertinoButton(
                      padding: const EdgeInsets.only(left: 0),
                      minSize: 30,
                      child: const Icon(
                        FontAwesomeIcons.magnet,
                        size: 16,
                      ),
                      onPressed: () {
                        final String _magnet =
                            'magnet:?xt=urn:btih:${torrent.hash}';
                        logger.v(_magnet);
                        Share.share(_magnet);
                      },
                    ),
                  )
                ],
              );
            },
            separatorBuilder: (_, __) {
              return Divider(
                height: 0.5,
                color: CupertinoDynamicColor.resolve(
                    CupertinoColors.systemGrey4, context),
              );
            },
            itemCount: controller.torrents.length,
          );
        },
        onLoading: Container(
          child: const CupertinoActivityIndicator(
            radius: 14,
          ),
        ),
        onError: (err) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoButton(
                  padding: const EdgeInsets.all(0),
                  child: const Icon(
                    Icons.refresh,
                    size: 30,
                    color: Colors.red,
                  ),
                  onPressed: () {
                    controller.reload();
                  },
                ),
                const Text(
                  'Error',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

Future<void> showTorrentDialog() {
  // Get.put(TorrentController(), tag: pageCtrlDepth);
  return showCupertinoDialog<void>(
      context: Get.overlayContext,
      builder: (_) {
        return CupertinoAlertDialog(
          title: Text(S.of(Get.context).p_Torrent),
          content: Container(
            child: const TorrentView(),
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              child: Text(S.of(Get.overlayContext).cancel),
              onPressed: () {
                Get.back();
              },
            ),
          ],
        );
      });
}
