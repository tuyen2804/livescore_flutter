import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';

/// Port `presentation/highlight/HighlightDetailFragment.kt` — phát video
/// YouTube nhúng, giống `raw/ayp_youtube_player.html` của bản gốc.
class HighlightDetailScreen extends StatefulWidget {
  const HighlightDetailScreen({
    super.key,
    required this.url,
    required this.title,
    required this.homeTeam,
    required this.awayTeam,
    required this.leagueName,
    this.thumb,
  });

  final String url;
  final String title;
  final String homeTeam;
  final String awayTeam;
  final String leagueName;
  final String? thumb;

  @override
  State<HighlightDetailScreen> createState() => _HighlightDetailScreenState();
}

class _HighlightDetailScreenState extends State<HighlightDetailScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.black)
      // Nạp trang HTML nội bộ với baseUrl youtube.com — port
      // `raw/ayp_youtube_player.html`. Nạp thẳng link /embed sẽ bị YouTube
      // trả "Lỗi 153" vì iframe không có origin hợp lệ.
      ..loadHtmlString(_playerHtml, baseUrl: 'https://www.youtube.com');
  }

  /// Lấy id video từ link watch / youtu.be / shorts.
  String? get _videoId {
    final uri = Uri.tryParse(widget.url);
    if (uri == null) return null;
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
    }
    final v = uri.queryParameters['v'];
    if (v != null && v.isNotEmpty) return v;
    final i = uri.pathSegments.indexOf('shorts');
    if (i >= 0 && i + 1 < uri.pathSegments.length) {
      return uri.pathSegments[i + 1];
    }
    return uri.pathSegments.isEmpty ? null : uri.pathSegments.last;
  }

  String get _playerHtml => """
<!DOCTYPE html>
<html>
  <style type="text/css">
    html, body { height:100%; width:100%; margin:0; padding:0;
      background-color:#000000; overflow:hidden; position:fixed; }
  </style>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0,
      maximum-scale=1.0, user-scalable=no">
    <script defer src="https://www.youtube.com/iframe_api"></script>
  </head>
  <body><div id="youTubePlayerDOM"></div></body>
  <script type="text/javascript">
    function onYouTubeIframeAPIReady() {
      new YT.Player('youTubePlayerDOM', {
        height: '100%',
        width: '100%',
        videoId: '${_videoId ?? ''}',
        playerVars: {
          autoplay: 1,
          playsinline: 1,
          rel: 0,
          controls: 1,
          enablejsapi: 1,
          // Thiếu `origin` là YouTube trả "Lỗi 152".
          origin: 'https://www.youtube.com'
        }
      });
    }
  </script>
</html>
""";

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.bgApp,
        // `fragment_highlight_detail.xml`: trình phát chiếm toàn màn (cách trên
        // 60sdp), nút back 32sdp margin 12sdp padding 6sdp nổi ở góc trái.
        body: Stack(
          children: [
            Positioned.fill(
              top: AppDimens.sdp(60),
              child: WebViewWidget(controller: _controller),
            ),
            Positioned(
              left: AppDimens.sdp(12),
              top: AppDimens.sdp(12),
              child: SafeArea(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: SizedBox(
                    width: AppDimens.sdp(32),
                    height: AppDimens.sdp(32),
                    child: Padding(
                      padding: EdgeInsets.all(AppDimens.sdp(6)),
                      child: SvgPicture.asset(
                        'assets/icons/ic_arrow_back.svg',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
