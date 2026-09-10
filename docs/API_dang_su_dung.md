# API đang dùng trong app Live Score

> Rà từ mã nguồn `D:\live_score`, cập nhật **09/09/2026**. Cột *Trạng thái* là kết quả gọi thử thật, có giãn cách 3 giây giữa các request để tránh bị chặn mềm.

## Tổng quan

| Nhóm | Nhà cung cấp | Số endpoint | Ghi chú |
|---|---|---:|---|
| API bóng đá | Backend riêng (dữ liệu gốc Sportmonks) | 10 | 1/10 endpoint đang lỗi phía server |
| API Sofascore | Sofascore (API nội bộ, không bán gói) | 86 | 23 môn ngoài bóng đá |
| API ảnh | Sportmonks · Sofascore · YouTube | 9 | Tải thẳng từ CDN, không qua backend |
| Dịch vụ ngoài | YouTube · Google Play · Firebase | 8 | Firebase chưa chạy trên iOS |
| **Tổng** | | **113** | |

---

## 1. API bóng đá riêng

**Base URL:** `https://sp098-live-score.pandaglobal.top` — lấy từ khoá `base_url` của Firebase Remote Config, đổi được từ xa.

**Header:** `Accept: application/json`, `Accept-Charset: UTF-8`. Không có API key.

| # | Nhóm | Method | Đường dẫn | Tham số | Dùng ở màn | Trạng thái | Ghi chú |
|---:|---|---|---|---|---|---|---|
| 1 | Feed trận | `GET` | `/live-score/league-live` | `date=YYYY-MM-DD` | Home (tab bóng đá) | OK — 28 mục | Danh sách trận theo ngày, gồm cả trận đang đá |
| 2 | Chi tiết trận | `GET` | `/live-score/match-centre-live` | `fixture_id` | Chi tiết trận – tab Info/Stats/Lineup/H2H | OK — 5 khoá | Trả match, events, lineups, statistics, h2h trong 1 lần gọi |
| 3 | Bảng xếp hạng | `GET` | `/live-score/standings` | `league_id` | Chi tiết giải – tab Table | OK — 20 mục | Champions League (id=2) không có dữ liệu |
| 4 | Lịch giải | `GET` | `/live-score/list-fixtures-upcoming` | `league_id` | Chi tiết giải – tab Fixtures | OK — 40 mục | Champions League (id=2) trả rỗng |
| 5 | Highlight | `GET` | `/live-score/match-high-light` | `date=YYYY-MM-DD` | Tab Highlights | OK — 27 mục | Trả về video id YouTube |
| 6 | Dự đoán | `GET` | `/live-score/match-forecast-new` | `fixture_id, language` | Tab Prediction | LỖI phía server | Luôn trả {error:true,'The system is busy'} hoặc 'Không tìm thấy dự đoán nào' |
| 7 | Lịch đội | `GET` | `/live-score/fixtures-by-date-for-team` | `team_id` | Chi tiết đội – tab Fixtures | OK — 36 mục | Bị chặn mềm nếu dò liên tục, trả 'Không tìm thấy fixtures nào' giả |
| 8 | Bình chọn – đọc | `GET` | `/live-score/match-centre-vote` | `fixture_id` | Chi tiết trận – thẻ bình chọn | OK — 4 khoá | countTeam1Win / countTeam2Win / countDraws |
| 9 | Bình chọn – ghi | `POST` | `/live-score/match-centre-vote-team-win` | `fixture_id, home_win\|draw\|away_win = 1` | Chi tiết trận – thẻ bình chọn | OK | Tham số đổi theo lựa chọn 1=home, 2=draw, 3=away |
| 10 | Đội hình | `GET` | `/live-score/list-player` | `team_id` | Chi tiết đội – tab Squad | OK — 28 mục | Kèm ảnh cầu thủ dạng URL đầy đủ của Sportmonks |

---

## 2. API Sofascore

**Base URL:** `https://api.sofascore.com/api/v1/`

**Header:** User-Agent trình duyệt. Sofascore chặn theo dấu vân tay TLS nên request phải đi qua Cronet (Android) / NSURLSession (iOS), `dart:io` bị trả 403.

> Đây là API nội bộ của Sofascore, **không có gói thương mại**. Có thể ngừng hoạt động bất cứ lúc nào.

### Feed theo môn / ngày  (9)

| # | Đường dẫn | Tham số | Hàm trong code | Dùng ở màn |
|---:|---|---|---|---|
| 1 | `sport/${tzOffset ?? _tz}/event-count` | `String query` | `searchAll` | Tìm kiếm |
| 2 | `sport/$sportSlug/$date/events` | `String sportSlug, String date` | `getSportEvents` | Tầng repository |
| 3 | `sport/$sportSlug/$date/${tzOffset ?? _tz}/categories` | `String sportSlug, String date, [ String? tzOffset, ]` | `getCategoriesForDate` | Home (feed đa môn) |
| 4 | `sport/$sportSlug/popular-events` | `String sportSlug` | `getPopularEvents` | Home (feed đa môn) |
| 5 | `sport/$sportSlug/$countryCode/popular-events/$date` | `String sportSlug, String countryCode, String date,` | `getPopularEventsForDate` | Home (feed đa môn) |
| 6 | `sport/$sportSlug/categories` | `String sportSlug` | `getSportCategories` | Leagues |
| 7 | `sport/$sportSlug/categories` | `String sportSlug` | `getSportStageCategories` | Home (feed đa môn) |
| 8 | `sport/$sportSlug/available-category-filters` | `String sportSlug` | `getAvailableCategoryFilters` | Home (feed đa môn) |
| 9 | `sport/mma/main-events/$date` | `String date` | `getMmaMainEvents` | Home (feed đa môn) |

### Khu vực – danh mục  (2)

| # | Đường dẫn | Tham số | Hàm trong code | Dùng ở màn |
|---:|---|---|---|---|
| 10 | `category/$categoryId/scheduled-events/$date` | `int categoryId, String date,` | `getCategoryEventsForDate` | Home (feed đa môn) |
| 11 | `category/$categoryId/unique-tournaments` | `int categoryId` | `getCategoryUniqueTournaments` | Home (feed đa môn) |

### Lịch tháng  (2)

| # | Đường dẫn | Tham số | Hàm trong code | Dùng ở màn |
|---:|---|---|---|---|
| 12 | `calendar/$yearMonth/$tzOffset/$sportSlug/unique-tournaments` | `String yearMonth, String sportSlug, [ String tzOffset = '25200', ]` | `getCalendar` | Chưa dùng trong app |
| 13 | `calendar/$yearMonth/${tzOffset ?? _tz}/$sportSlug/stages` | `String yearMonth, String sportSlug, [ String? tzOffset, ]` | `getStageCalendar` | Home (feed đa môn) |

### Giải đấu  (15)

| # | Đường dẫn | Tham số | Hàm trong code | Dùng ở màn |
|---:|---|---|---|---|
| 14 | `unique-tournament/$tournamentId/scheduled-events/$date` | `int tournamentId, String date,` | `getUniqueTournamentEvents` | Home (feed đa môn) |
| 15 | `unique-tournament/$tournamentId/seasons` | `int tournamentId` | `getUniqueTournamentSeasons` | Tầng repository |
| 16 | `unique-tournament/$tournamentId/season/$seasonId/events/last/0` | `int tournamentId, int seasonId,` | `getSeasonLastEvents` | Tầng repository |
| 17 | `unique-tournament/$tournamentId/season/$seasonId/events/next/0` | `int tournamentId, int seasonId,` | `getSeasonNextEvents` | Tầng repository |
| 18 | `tournament/$tournamentId` | `int tournamentId` | `getTournament` | Tầng repository |
| 19 | `unique-tournament/$id` | `int id` | `getUniqueTournamentDetails` | Chưa dùng trong app |
| 20 | `unique-tournament/$uniqueTournamentId/season/$seasonId/standings/total` | `int uniqueTournamentId, int seasonId,` | `getUniqueTournamentStandings` | Tầng repository |
| 21 | `tournament/$tournamentId/season/$seasonId/standings/total` | `int tournamentId, int seasonId,` | `getTournamentStandings` | Tầng repository |
| 22 | `tournament/$tournamentId/season/$seasonId/team-events/total` | `int tournamentId, int seasonId,` | `getTournamentTeamEvents` | Chưa dùng trong app |
| 23 | `unique-tournament/$tournamentId/season/$seasonId/cuptrees` | `int tournamentId, int seasonId` | `getCupTrees` | Chưa dùng trong app |
| 24 | `unique-tournament/$uniqueTournamentId/tournament/$tournamentId/mma-events/$fightType` | `int uniqueTournamentId, int tournamentId, String fightType,` | `getMmaEvents` | Tầng repository |
| 25 | `unique-tournament/$id` | `int id` | `getMmaUniqueTournamentDetail` | Tầng repository |
| 26 | `unique-tournament/$uniqueTournamentId/featured-events` | `int uniqueTournamentId` | `getMmaFeaturedEvents` | Tầng repository |
| 27 | `unique-tournament/$uniqueTournamentId/main-events/next/$page` | `int uniqueTournamentId, [ int page = 0, ]` | `getMmaMainEventsNext` | Tầng repository |
| 28 | `unique-tournament/$uniqueTournamentId/main-events/last/$page` | `int uniqueTournamentId, [ int page = 0, ]` | `getMmaMainEventsLast` | Tầng repository |

### Chặng đua  (12)

| # | Đường dẫn | Tham số | Hàm trong code | Dùng ở màn |
|---:|---|---|---|---|
| 29 | `stage/sport/$sportSlug/scheduled/$date` | `String sportSlug, String date,` | `getScheduledStages` | Home (feed đa môn) |
| 30 | `stage/$stageId` | `int stageId` | `getStageDetailsRaw` | Chưa dùng trong app |
| 31 | `stage/$stageId/extended` | `int stageId` | `getStageDetailsExtendedRaw` | Chưa dùng trong app |
| 32 | `stage/$stageId/extended` | `int stageId` | `getStageDetailsExtended` | Home (feed đa môn) |
| 33 | `stage/$stageId/v2/substages` | `int stageId` | `getStageSubstages` | Tầng repository |
| 34 | `stage/$stageId/highlights` | `int stageId` | `getStageHighlights` | Chưa dùng trong app |
| 35 | `stage/$stageId/standings/competitor` | `int stageId` | `getStageCompetitorStandings` | Tầng repository |
| 36 | `stage/$stageId/standings/team` | `int stageId` | `getStageTeamStandings` | Chưa dùng trong app |
| 37 | `unique-stage/$uniqueStageId/seasons` | `int uniqueStageId` | `getUniqueStageSeasonsRaw` | Chưa dùng trong app |
| 38 | `unique-stage/$uniqueStageId/seasons` | `int uniqueStageId` | `getUniqueStageSeasons` | Home (feed đa môn) |
| 39 | `unique-stage/$uniqueStageId/recent-stage-ids` | `int uniqueStageId` | `getUniqueStageRecentStageIds` | Chưa dùng trong app |
| 40 | `stage/$stageId/races/type/$outrightTeamType` | `int stageId, [ String outrightTeamType = 'competitor', ]` | `getStageSeasonRaces` | Chưa dùng trong app |

### Kênh phát sóng  (2)

| # | Đường dẫn | Tham số | Hàm trong code | Dùng ở màn |
|---:|---|---|---|---|
| 41 | `tv/stage/$stageId/country-channels` | `int stageId` | `getStageCountryChannels` | Chưa dùng trong app |
| 42 | `tv/event/$eventId/country-channels` | `int eventId` | `getEventCountryChannels` | Tầng repository |

### Gợi ý mặc định theo quốc gia  (6)

| # | Đường dẫn | Tham số | Hàm trong code | Dùng ở màn |
|---:|---|---|---|---|
| 43 | `config/follow-suggestions/unique-tournaments/$alpha2` | `[ String alpha2 = 'VN', ]` | `getDefaultPinnedTournaments` | Chưa dùng trong app |
| 44 | `config/follow-suggestions/unique-tournaments/$alpha2/sport/$sportSlug` | `String sportSlug, [ String alpha2 = 'VN', ]` | `getDefaultPinnedTournamentsForSport` | Tầng repository |
| 45 | `config/default-unique-tournaments/$countryCode` | `[ String countryCode = 'VN', ]` | `getDefaultUniqueTournaments` | Home (feed đa môn) |
| 46 | `config/follow-suggestions/teams/$alpha2` | `[String alpha2 = 'VN']` | `getDefaultSuggestedTeams` | Home (feed đa môn) |
| 47 | `config/follow-suggestions/teams/$alpha2/sport/$sportSlug` | `String sportSlug, [ String alpha2 = 'VN', ]` | `getDefaultSuggestedTeamsForSport` | Tầng repository |
| 48 | `config/follow-suggestions/players/$alpha2` | `[ String alpha2 = 'VN', ]` | `getDefaultSuggestedPlayers` | Chưa dùng trong app |

### Chi tiết trận  (26)

| # | Đường dẫn | Tham số | Hàm trong code | Dùng ở màn |
|---:|---|---|---|---|
| 49 | `event/newly-added-events` | `—` | `getNewlyAddedEvents` | Chưa dùng trong app |
| 50 | `event/$eventId` | `int eventId` | `getEventDetails` | Tầng repository |
| 51 | `event/$eventId` | `int eventId` | `getEventDetailsRaw` | Tầng repository |
| 52 | `event/$eventId/incidents` | `int eventId` | `getEventIncidents` | Tầng repository |
| 53 | `event/$eventId/best-players` | `int eventId` | `getEventBestPlayers` | Chưa dùng trong app |
| 54 | `event/$eventId/at-bats` | `int eventId` | `getEventAtBats` | Chưa dùng trong app |
| 55 | `event/baseball/$eventId/top-performers` | `int eventId` | `getBaseballTopPerformers` | Chưa dùng trong app |
| 56 | `event/$eventId/umpires` | `int eventId` | `getEventUmpires` | Chưa dùng trong app |
| 57 | `event/$eventId/weather` | `int eventId` | `getEventWeather` | Chưa dùng trong app |
| 58 | `event/$eventId/lineups` | `int eventId` | `getEventLineups` | Tầng repository |
| 59 | `event/$eventId/statistics` | `int eventId` | `getEventStatistics` | Tầng repository |
| 60 | `event/$eventId/innings` | `int eventId` | `getEventInnings` | Chưa dùng trong app |
| 61 | `event/$eventId/odds/1/all` | `int eventId` | `getEventOdds` | Tầng repository |
| 62 | `event/$eventId/votes` | `int eventId` | `getEventVotes` | Tầng repository |
| 63 | `event/$eventId/pregame-form` | `int eventId` | `getEventPregameForm` | Chưa dùng trong app |
| 64 | `event/$eventId/comments/en` | `int eventId` | `getEventComments` | Chưa dùng trong app |
| 65 | `event/$customId/h2h/events` | `String customId` | `getHeadToHeadEvents` | Tầng repository |
| 66 | `event/$eventId/suggests` | `int eventId` | `getEventSuggests` | Chưa dùng trong app |
| 67 | `event/$eventId/graph` | `int eventId` | `getEventGraph` | Chưa dùng trong app |
| 68 | `event/$eventId/graph/sequence` | `int eventId` | `getEventGraphSequence` | Chưa dùng trong app |
| 69 | `event/$eventId/graph/cricket` | `int eventId` | `getEventCricketGraph` | Chưa dùng trong app |
| 70 | `event/$eventId/point-by-point` | `int eventId` | `getEventPointByPoint` | Tầng repository |
| 71 | `event/$eventId/tennis-power` | `int eventId` | `getEventTennisPower` | Chưa dùng trong app |
| 72 | `event/$eventId/ai-insights-postmatch/en` | `int eventId` | `getEventAiInsightsPostmatch` | Chưa dùng trong app |
| 73 | `event/$eventId/media/summary/country/$countryCode` | `int eventId, String countryCode,` | `getEventMediaSummary` | Chưa dùng trong app |
| 74 | `event/$eventId/esports-games` | `int eventId` | `getEventEsportsGames` | Tầng repository |

### Esports  (4)

| # | Đường dẫn | Tham số | Hàm trong code | Dùng ở màn |
|---:|---|---|---|---|
| 75 | `esports-game/$gameId/statistics` | `int gameId` | `getEsportsGameStatistics` | Chưa dùng trong app |
| 76 | `esports-game/$gameId/lineups` | `int gameId` | `getEsportsGameLineups` | Chưa dùng trong app |
| 77 | `esports-game/$gameId/bans` | `int gameId` | `getEsportsGameBans` | Chưa dùng trong app |
| 78 | `esports-game/$gameId/rounds` | `int gameId` | `getEsportsGameRounds` | Chưa dùng trong app |

### Đội bóng  (7)

| # | Đường dẫn | Tham số | Hàm trong code | Dùng ở màn |
|---:|---|---|---|---|
| 79 | `team/$teamId` | `int teamId` | `getTeamDetails` | Tầng repository |
| 80 | `team/$teamId/events/last/$page` | `int teamId, [int page = 0]` | `getTeamLastEvents` | Tầng repository |
| 81 | `team/$teamId/events/next/$page` | `int teamId, [int page = 0]` | `getTeamNextEvents` | Tầng repository |
| 82 | `team/$teamId/players` | `int teamId` | `getTeamPlayers` | Tầng repository |
| 83 | `team/$teamId/tournaments` | `int teamId` | `getTeamTournaments` | Chưa dùng trong app |
| 84 | `team/$teamId/transfers` | `int teamId` | `getTeamTransfers` | Chưa dùng trong app |
| 85 | `rankings/team/$teamId` | `int teamId` | `getTeamRankings` | Chưa dùng trong app |

### Tìm kiếm  (1)

| # | Đường dẫn | Tham số | Hàm trong code | Dùng ở màn |
|---:|---|---|---|---|
| 86 | `search/all` | `q={từ khoá}` | `searchAll` | Tìm kiếm |

---

## 3. API ảnh

| # | Nguồn | Loại ảnh | URL | Ví dụ | Ghi chú |
|---:|---|---|---|---|---|
| 1 | Bóng đá | Logo đội / giải / ảnh cầu thủ | `https://cdn.sportmonks.com/images/soccer{đường dẫn tương đối từ DB}` | Ví dụ /teams/18/18.png, /leagues/27/27.png | Khoá image_base_url của Remote Config; API cũng trả sẵn URL đầy đủ ở một số trường |
| 2 | Sofascore | Logo đội | `https://img.sofascore.com/api/v1/team/{id}/image` | — | Không có gói thương mại |
| 3 | Sofascore | Logo giải | `https://img.sofascore.com/api/v1/unique-tournament/{id}/image` | — |  |
| 4 | Sofascore | Logo chặng đua | `https://img.sofascore.com/api/v1/unique-stage/{id}/image` | — |  |
| 5 | Sofascore | Logo khu vực | `https://img.sofascore.com/api/v1/category/{id}/image` | — |  |
| 6 | Sofascore | Cờ quốc gia | `https://img.sofascore.com/api/v1/country/{alpha2}/flag` | alpha2 = VN, GB, US… |  |
| 7 | Sofascore | Ảnh cầu thủ | `https://img.sofascore.com/api/v1/player/{id}/image` | — |  |
| 8 | Sofascore | Ảnh HLV | `https://img.sofascore.com/api/v1/manager/{id}/image` | — |  |
| 9 | YouTube | Ảnh bìa highlight | `https://img.youtube.com/vi/{videoId}/hqdefault.jpg` | — | Miễn phí, không cần API key |

---

## 4. Dịch vụ ngoài

| # | Dịch vụ | URL / SDK | Dùng ở đâu | Ghi chú |
|---:|---|---|---|---|
| 1 | YouTube IFrame API | `https://www.youtube.com/iframe_api` | Highlight detail | Nhúng qua WebView, baseUrl = https://www.youtube.com |
| 2 | YouTube watch | `https://www.youtube.com/watch?v={videoId}` | Highlight | Mở ngoài trình duyệt |
| 3 | Google Play – Rate | `https://play.google.com/store/apps/details?id=com.ind.score2new.stream` | Settings → Rate | Chỉ đúng cho Android, iOS cần link App Store |
| 4 | Google Play – Share | `https://play.google.com/store/apps/details?id={packageName}` | Settings → Share | Nhúng trong chuỗi dịch của cả 14 ngôn ngữ |
| 5 | Chính sách bảo mật | `https://policy.indie-dev.store/` | Settings → Privacy policy | — |
| 6 | Firebase Remote Config | `SDK firebase_remote_config` | Toàn app | Khoá: base_url, image_base_url, force_update, min_app_version, guide_enabled, language_reopen, onboard_reopen, theme_mode |
| 7 | Firebase Analytics | `SDK firebase_analytics` | Toàn app | Chưa chạy trên iOS vì thiếu GoogleService-Info.plist |
| 8 | Firebase Crashlytics | `SDK firebase_crashlytics` | Toàn app | Chưa chạy trên iOS vì thiếu GoogleService-Info.plist |

---

## Ghi chú

1. App **không gọi thẳng** nhà cung cấp dữ liệu bóng đá. Nó gọi backend riêng `sp098-live-score.pandaglobal.top`; backend đó mới là bên mua dữ liệu. ID đội, ID giải và toàn bộ ảnh đều theo hệ **Sportmonks** — DB đóng gói trong app có 2.367 giải và 64.452 đội theo hệ ID này.
2. `base_url` và `image_base_url` đọc từ **Firebase Remote Config**, đổi được từ xa mà không cần phát hành bản mới. Trên iOS hiện chưa có `GoogleService-Info.plist` nên hai giá trị này rơi về mặc định hard-code.
3. `match-forecast-new` **đang hỏng phía server** — thử 25 trận, kể cả trận lớn, đều trả `{"error":true,"message":"The system is busy, please try again later."}` hoặc `"Không tìm thấy dự đoán nào"`. Không phải lỗi của app.
4. Backend bóng đá **chặn mềm khi bị dò liên tục**: vẫn trả HTTP 200 nhưng đổi nội dung thành `"Không tìm thấy fixtures nào"` — trông y hệt lỗi thiếu dữ liệu. Khi kiểm thử phải giãn ≥3 giây mỗi request.
5. Cột *Dùng ở màn* ghi **"Chưa dùng trong app"** nghĩa là hàm đã port sẵn theo bản Kotlin nhưng chưa có màn nào gọi tới.
6. `match-centre-vote-team-win` là endpoint **POST** duy nhất; tham số đổi theo lựa chọn: `home_win=1`, `draw=1` hoặc `away_win=1`.
