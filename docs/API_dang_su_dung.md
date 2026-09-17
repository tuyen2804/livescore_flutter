# API đang dùng trong app Live Score

> Rà từ mã nguồn `D:\live_score`. **Cập nhật 16/09/2026** — lần này gọi thật từng endpoint bóng đá và một endpoint đại diện cho mỗi họ Sofascore để ghi lại **format trả về**. Giãn 3,5 giây giữa các request để tránh bị chặn mềm.

## Tổng quan

| Nhóm | Nhà cung cấp | Số endpoint | Ghi chú |
|---|---|---:|---|
| API bóng đá | Backend riêng (dữ liệu gốc Sportmonks + Highlightly) | 10 | 1/10 endpoint đang lỗi phía server |
| API Sofascore | Sofascore (API nội bộ, không bán gói) | 86 | 23 môn ngoài bóng đá |
| API ảnh | Sportmonks · Sofascore · Highlightly · YouTube | 9 | Tải thẳng từ CDN, không qua backend |
| Dịch vụ ngoài | YouTube · Google Play · Firebase | 8 | Firebase chưa chạy trên iOS |
| **Tổng** | | **113** | |

### Quy ước đọc phần "Format trả về"

- JSON trong tài liệu là **cắt từ response thật ngày 16/09/2026**, không phải ví dụ bịa.
- `…` nghĩa là còn phần tử cùng dạng phía sau.
- Trường nào app **không đọc** thì có ghi chú `(app bỏ qua)`.

---

## 1. API bóng đá riêng

**Base URL:** `https://sp098-live-score.pandaglobal.top` — lấy từ khoá `base_url` của Firebase Remote Config, đổi được từ xa.

**Header:** `Accept: application/json`, `Accept-Charset: UTF-8`. Không có API key. Đứng sau Cloudflare — User-Agent lạ (ví dụ `python-urllib`) bị trả **403**, `curl`/Dart/Cronet thì qua.

| # | Nhóm | Method | Đường dẫn | Tham số | Dùng ở màn | Trạng thái 16/09 | Ghi chú |
|---:|---|---|---|---|---|---|---|
| 1 | Feed trận | `GET` | `/live-score/league-live` | `date=YYYY-MM-DD` | Home (tab bóng đá) | OK — 90 trận | Danh sách trận theo ngày, gồm cả trận đang đá |
| 2 | Chi tiết trận | `GET` | `/live-score/match-centre-live` | `fixture_id` | Chi tiết trận – Info/Stats/Lineup/H2H | OK — 91 KB | Trả 5 khối trong 1 lần gọi |
| 3 | Bảng xếp hạng | `GET` | `/live-score/standings` | `league_id` | Chi tiết giải – tab Table | OK — 16 dòng | Champions League (id=2) không có dữ liệu |
| 4 | Lịch giải | `GET` | `/live-score/list-fixtures-upcoming` | `league_id` | Chi tiết giải – tab Fixtures | OK — 40 trận | Champions League (id=2) trả rỗng |
| 5 | Highlight | `GET` | `/live-score/match-high-light` | `date=YYYY-MM-DD` | Tab Highlights | OK — 165 video | **Nguồn khác**: Highlightly, không phải Sportmonks |
| 6 | Dự đoán | `GET` | `/live-score/match-forecast-new` | `fixture_id`, `language` | Tab Prediction | **LỖI phía server** | 3 dạng lỗi khác nhau, xem §1.6 |
| 7 | Lịch đội | `GET` | `/live-score/fixtures-by-date-for-team` | `team_id` | Chi tiết đội – tab Fixtures | OK — 10 trận | Bị chặn mềm nếu dò liên tục |
| 8 | Bình chọn – đọc | `GET` | `/live-score/match-centre-vote` | `fixture_id` | Chi tiết trận – thẻ bình chọn | OK | — |
| 9 | Bình chọn – ghi | `POST` | `/live-score/match-centre-vote-team-win` | `fixture_id` + một trong `home_win`/`draw`/`away_win` `=1` | Chi tiết trận – thẻ bình chọn | Không gọi thử (ghi dữ liệu) | App bỏ qua response |
| 10 | Đội hình | `GET` | `/live-score/list-player` | `team_id` | Chi tiết đội – tab Squad | OK — 31 cầu thủ | — |

### Vỏ chung

Mọi endpoint bọc trong cùng một vỏ:

```json
{ "success": true, "data": … }
```

Lỗi thì đổi thành — **và trả HTTP 500**, message bằng **tiếng Việt**:

```json
{ "success": false, "message": "Không tìm thấy dự đoán nào ", "data": null }
```

Ngoại lệ: `match-forecast-new` còn một dạng thứ ba — HTTP 200, `success: true`, nhưng lỗi nằm **bên trong** `data` (§1.6).

### 1.1 `league-live` — `data` là mảng trận

```json
{ "success": true, "data": [
  { "id": 19635911,
    "date": "2026-09-16",
    "countryId": 47, "leagueId": 573, "seasonId": 26806,
    "nameVenue": "Strawberry Arena",
    "name": "AIK vs Mjällby",
    "kickoffUtc": "2026-09-16 17:00:00",
    "kickoffEpoch": 1789578000,
    "lengthMinutes": 90,
    "state": 1,
    "groupName": "", "roundName": "18",
    "score": "0 - 0",
    "homeId": 2825, "awayId": 411,
    "homeName": "AIK", "awayName": "Mjällby",
    "homeShortName": "AIK", "awayShortName": "MJA",
    "homeTeamLogoUrl": "https://cdn.sportmonks.com/images/soccer/teams/9/2825.png",
    "awayTeamLogoUrl": "https://cdn.sportmonks.com/images/soccer/teams/27/411.png",
    "leagueLogoUrl":   "https://cdn.sportmonks.com/images/soccer/leagues/29/573.png",
    "leagueName": "Allsvenskan",
    "playingTime": 0 },
  … ] }
```

Hai trường quyết định cách hiển thị:

| Trường | Ý nghĩa |
|---|---|
| `state` | `1` = chưa đá · `5` = đã kết thúc · các giá trị khác = đang diễn ra / hoãn |
| `playingTime` | Phút đang đá; `0` khi chưa bắt đầu hoặc đã xong |
| `score` | Chuỗi `"2 - 1"`, **không** phải số — phải tự tách |
| `kickoffEpoch` | Giây (không phải mili-giây) |

### 1.2 `match-centre-live` — `data` là object 5 khối

```json
{ "success": true, "data": {
    "match": { … }, "events": [ … ], "lineups": [ … ],
    "statistics": [ … ], "h2h": [ … ] } }
```

**`data.match`** — giống hệt một phần tử của `league-live`, chỉ thêm `time` (mốc thời gian server, mili-giây) và bỏ `date`/`countryId`.

**`data.events`** — diễn biến trận:

```json
{ "id": 157926696, "fixtureId": 19667159, "teamId": 6188,
  "typeName": "Yellowcard", "minute": 7, "extraMinute": null,
  "playerId": 218531, "playerName": "Bressan", "relatedPlayerName": "" }
```

**`data.lineups`** — mỗi cầu thủ một phần tử, cả hai đội chung một mảng, lọc theo `teamId`:

```json
{ "id": 14674700927, "fixtureId": 19667159, "teamId": 2352,
  "playerId": 37577104, "playerName": "Marcelo Alixandre Ajul",
  "playerImageUrl": "https://cdn.sportmonks.com/images/soccer/players/16/37577104.png",
  "jerseyNumber": 3,
  "formation": "4-2-3-1",
  "positionField": "2:4",
  "isCaptain": 0,
  "stats": [ { "typeId": 118, "typeName": "Rating",
               "developerName": "RATING", "value": "6.4" }, … ] }
```

- `positionField` là `"hàng:cột"` để xếp sơ đồ sân.
- `isCaptain` là `0/1`, không phải boolean.
- `stats[].value` luôn là **chuỗi**, kể cả số (`"6.4"`, `"19"`).

**`data.statistics`** — đúng 2 phần tử, mỗi đội một:

```json
{ "id": 996521978, "fixtureId": 19667159, "teamId": 2352,
  "shotOnTarget": 3, "shotOffTarget": 5, "blockerShots": 3,
  "possession": 57, "cornerKicks": 3, "offsides": 2, "fouls": 7,
  "throwIn": 21, "yellowCards": 2, "redCards": 0 }
```

**`data.h2h`** — đúng 1 phần tử, thống kê đối đầu:

```json
{ "fixtureId": 19667159, "team1Id": 6188, "team2Id": 2352,
  "totalWin": 2, "totalDraws": 1, "totalLoss": 1,
  "winLastFive": 2, "drawsLastFive": 1 }
```

### 1.3 `standings` — `data` là mảng dòng bảng

```json
{ "id": 18443436, "position": 1, "points": 48,
  "result": "equal",
  "name": "Sirius",
  "image_path": "https://cdn.sportmonks.com/images/soccer/teams/22/2678.png",
  "overall_matches": 21, "won": 15, "draw": 3, "lost": 3,
  "goalsFor": 50, "goalsAgainst": 27, "goal_difference": 23 }
```

`result` = `"equal"` / `"up"` / `"down"` — hướng thay đổi thứ hạng. Lưu ý `id` ở đây là **id dòng bảng**, không phải id đội; id đội chỉ suy được từ `image_path`.

### 1.4 `list-fixtures-upcoming` và `fixtures-by-date-for-team`

Hai endpoint khác nhau nhưng **format phần tử giống hệt nhau** — dùng `snake_case`, khác hẳn `camelCase` của `league-live`:

```json
{ "id": 19635911,
  "league_id": 573, "league_name": "Allsvenskan",
  "league_image_path": "https://cdn.sportmonks.com/images/soccer/leagues/29/573.png",
  "starting_at": "2026-09-16 17:00:00",
  "home_team_id": 411,
  "home_image_path": "https://cdn.sportmonks.com/images/soccer/teams/27/411.png",
  "home_name": "Mjällby",
  "away_team_id": 2825,
  "away_image_path": "https://cdn.sportmonks.com/images/soccer/teams/9/2825.png",
  "away_name": "AIK" }
```

Không có tỷ số, không có `state` — đây chỉ là lịch. Muốn tỷ số phải gọi `match-centre-live` theo từng `id`.

### 1.5 `match-high-light` — nguồn Highlightly, KHÔNG phải Sportmonks

```json
{ "id": 606458,
  "imgUrl": "https://i.ytimg.com/vi/-_j3gE1Rb0c/hqdefault.jpg",
  "title": "Primera B: Barranquilla vs Ind. Yumbo",
  "url": "https://www.youtube.com/watch?v=-_j3gE1Rb0c",
  "channel": "Win Sports", "source": "youtube",
  "matchId": 1318733361,
  "matchRound": "Clausura - 9",
  "matchDate": 1789509600000,
  "matchCountryCode": "CO", "matchCountryName": "Colombia",
  "matchCountryLogo": "https://highlightly.net/soccer/images/countries/CO.svg",
  "homeTeamId": 1248350, "homeTeamName": "Barranquilla",
  "homeTeamLogo": "https://highlightly.net/soccer/images/teams/1248350.png",
  "awayTeamId": 23327545, "awayTeamName": "Ind. Yumbo",
  "awayTeamLogo": "",
  "leagueId": 205024, "leagueName": "Primera B",
  "leagueLogo": "https://highlightly.net/soccer/images/leagues/205024.png",
  "leagueSeason": 2026 }
```

**Đây là hệ ID hoàn toàn khác.** `matchId` 1318733361 và `leagueId` 205024 là của Highlightly, không map được sang `fixture_id`/`league_id` Sportmonks ở 9 endpoint còn lại. Nên không có cách nối highlight với trận trong app. `matchDate` ở đây là **mili-giây**, khác `kickoffEpoch` (giây) của `league-live`. `logo` có thể là chuỗi rỗng.

### 1.6 `match-forecast-new` — đang hỏng, ba dạng lỗi

Gọi thử 16/09/2026, cả 5 biến thể:

| Gọi | HTTP | Response |
|---|---:|---|
| `?fixture_id=19635911&language=en` | 200 | `{"success":true,"data":{"error":true,"message":"The system is busy, please try again later."}}` |
| `?fixture_id=19635911` (bỏ `language`) | 200 | y hệt trên |
| `?fixture_id=19635911&language=vi` | 200 | y hệt trên |
| `?fixture_id=19667159` (trận đã đá xong) | 500 | `{"success":false,"message":"Không tìm thấy result dự đoán nào ","data":null}` |
| `?language=en` (thiếu `fixture_id`) | 500 | `{"success":false,"message":"Không tìm thấy dự đoán nào ","data":null}` |

Ba kết luận:

1. **`language` hiện không có tác dụng** — en/vi/bỏ hẳn đều ra cùng một response. Tham số này dành cho phần văn bản phân tích (`analysis.text`), nhưng chưa bao giờ chạm tới được vì tầng sinh dự đoán đã chết trước đó.
2. Message lỗi là **tiếng Việt** (`"Không tìm thấy result dự đoán nào "`, thừa dấu cách cuối) — backend do người Việt dựng, phần dự đoán nhiều khả năng gọi tiếp sang một dịch vụ AI bên ngoài và dịch vụ đó đang hỏng.
3. Trận đã kết thúc và trận sắp đá trả **hai lỗi khác nhau**, nên server có phân nhánh theo trạng thái trận — tức luồng vẫn còn, chỉ là nguồn dự đoán chết.

**Format lẽ ra phải trả về.** App đã code sẵn parser đầy đủ ở [football_models.dart:619](lib/data/models/football/football_models.dart#L619), dựng lại từ đó:

```json
{ "success": true, "data": {
    "match_result":        { "home": 45, "draw": 28, "away": 27, "accuracy": true },
    "first_goal":          { "home": 52, "noGoal": 8, "away": 40, "accuracy": true },
    "match_score":         { "home": 2,  "away": 1,   "accuracy": false },
    "total_goals":         { "totalGoals": 3, "accuracy": true },
    "both_teams_to_score": { "Ft": true, "H1": false, "H2": true, "accuracy": true },
    "corner":              { "home": 6, "away": 4, "accuracy": false },
    "confidence":          { "percent": 72, "accuracy": true },
    "analysis":            { "text": "…", "accuracy": true } } }
```

| Khối | Kiểu | Ý nghĩa |
|---|---|---|
| `match_result` | int, int, int | % thắng chủ / hoà / thắng khách |
| `first_goal` | int, int, int | % đội ghi bàn trước; `noGoal` = % không có bàn nào |
| `match_score` | int, int | Tỷ số dự đoán |
| `total_goals` | int | Tổng số bàn dự đoán |
| `both_teams_to_score` | bool ×3 | Cả hai cùng ghi bàn — cả trận / hiệp 1 / hiệp 2. Chú ý key **viết hoa**: `Ft`, `H1`, `H2` |
| `corner` | int, int | Số phạt góc mỗi đội |
| `confidence` | int | Độ tin cậy, % |
| `analysis` | string | Đoạn văn phân tích — **đây mới là chỗ `language` tác động** |

Mỗi khối kèm `accuracy: bool` — đúng/sai khi đối chiếu kết quả thật, chỉ có nghĩa với trận đã đá xong. Tất cả khối đều **không bắt buộc**; parser bỏ qua khối thiếu, và nếu **cả 8 khối đều thiếu** thì coi như chưa có dự đoán.

### 1.7 `match-centre-vote` (GET) và `match-centre-vote-team-win` (POST)

Đọc:

```json
{ "success": true, "data": {
    "fixtureId": 19667159,
    "countTeam1Win": 0, "countTeam2Win": 1, "countDraws": 1 } }
```

Ghi — `POST`, tham số nằm ở **query string**, không có body. Đúng một tham số `=1` tuỳ lựa chọn:

```
POST /live-score/match-centre-vote-team-win?fixture_id=19667159&home_win=1
POST /live-score/match-centre-vote-team-win?fixture_id=19667159&draw=1
POST /live-score/match-centre-vote-team-win?fixture_id=19667159&away_win=1
```

App **không đọc response** của endpoint ghi ([football_remote_data_source.dart:102](lib/data/datasources/remote/football_remote_data_source.dart#L102)) — bỏ phiếu xong thì gọi lại endpoint đọc để lấy số mới.

### 1.8 `list-player` — `data` là mảng cầu thủ

```json
{ "team_id": 2825,
  "position_name": "Defender",
  "name": "Hervé Matthys",
  "image_path": "https://cdn.sportmonks.com/images/soccer/players/9/63049.png",
  "height": 186, "weight": 77,
  "date_of_birth": "1996-01-19",
  "jersey_number": 3,
  "nationality": "Belgium",
  "national_path": "https://cdn.sportmonks.com/images/countries/png/short/be.png" }
```

Không có `player_id` — chỉ suy được từ `image_path`. `position_name` là chuỗi tiếng Anh (`Goalkeeper`/`Defender`/`Midfielder`/`Attacker`), không có mã số.

---

## 2. API Sofascore

**Base URL:** `https://api.sofascore.com/api/v1/`

**Header:** User-Agent trình duyệt. Sofascore chặn theo dấu vân tay TLS nên request phải đi qua Cronet (Android) / NSURLSession (iOS), `dart:io` bị trả 403.

> Đây là API nội bộ của Sofascore, **không có gói thương mại**. Có thể ngừng hoạt động bất cứ lúc nào.

### 2.0 Format trả về

Sofascore **không có vỏ `success`/`data`**. Mỗi endpoint trả thẳng một object có đúng một (đôi khi vài) khoá gốc, tên khoá đoán được từ đường dẫn:

| Họ endpoint | Khoá gốc | Kiểm chứng 16/09 |
|---|---|---|
| `sport/{tz}/event-count` | `{ "<môn>": { "live": int, "total": int } }` cho 16 môn | OK |
| `…/events`, `popular-events`, `team/…/events/…` | `{ "events": [Event], "hasNextPage": bool }` | OK — 10 / 30 phần tử |
| `…/categories` | `{ "categories": [Category] }` | OK — 128 |
| `config/default-unique-tournaments/{cc}` | `{ "uniqueTournaments": [UniqueTournament] }` | OK — 198 |
| `event/{id}` | `{ "event": Event }` | OK |
| `event/{id}/incidents` | `{ "incidents": [Incident], "home": {màu áo}, "away": {màu áo} }` | OK — 13 |
| `event/{id}/statistics` | `{ "statistics": [ {period, groups[]} ] }` | OK — 3 hiệp |
| `event/{id}/lineups` | `{ "confirmed": bool, "home": {…}, "away": {…}, "statisticalVersion": int }` | OK |
| `…/standings/total` | `{ "standings": [ {tournament, rows[]} ] }` | OK |
| `team/{id}` | `{ "team": Team, "pregameForm": {…}, "editorEntity": bool }` | OK |
| `team/{id}/players` | `{ "players": [], "foreignPlayers": [], "nationalPlayers": [], "supportStaff": [], "playerPreviousTeam": [], … }` | OK — 28 |
| `search/all?q=` | `{ "results": [ { "entity": {…}, "score": double, "type": "team\|player\|…" } ] }` | OK — 20 |

**Object `Event`** — dùng lại ở gần như mọi endpoint, đây là thứ nặng nhất:

```json
{ "id": 14025034, "slug": "arsenal-manchester-city",
  "customId": "xPsR",
  "startTimestamp": 1789578000,
  "tournament":  { "id": …, "name": …, "slug": …, "priority": int, "isLive": bool,
                   "category": { "id": …, "name": …, "flag": …, "alpha2": …, "country": {…} },
                   "uniqueTournament": { "id": …, "name": …, "primaryColorHex": …, "userCount": int } },
  "season":      { "id": …, "name": …, "year": … },
  "roundInfo":   { "round": int, "name": …, "slug": … },
  "status":      { "code": int, "description": "Ended", "type": "finished" },
  "homeTeam":    { "id": …, "name": …, "shortName": …, "nameCode": "ARS",
                   "gender": "M", "national": bool, "type": int,
                   "sport": {…}, "country": {"alpha2": "GB", …},
                   "teamColors": { "primary": …, "secondary": …, "text": … },
                   "fieldTranslations": { "nameTranslation": {…}, "shortNameTranslation": {…} } },
  "awayTeam":    { … như homeTeam … },
  "homeScore":   { "current": int, "display": int, "period1": int, "period2": int, "normaltime": int },
  "awayScore":   { … },
  "eventState":  { … },
  "winnerCode":  int,
  "finalResultOnly": bool,
  "hasGlobalHighlights": bool }
```

Ba điểm phải để ý khi đọc `Event`:

- **`startTimestamp` là giây**, còn feed bóng đá riêng thì `matchDate` của highlight là mili-giây — dễ lệch 1000 lần.
- **`status.type`** mới là thứ đáng tin để phân loại: `notstarted` / `inprogress` / `finished` / `postponed` / `canceled`. `status.code` là mã nội bộ, đổi theo môn.
- **`homeScore` rỗng `{}`** khi trận chưa đá — không phải `null`, nên kiểm tra `isEmpty` chứ đừng kiểm tra `null`.

**Dòng bảng xếp hạng** (`standings[0].rows[i]`):

```json
{ "id": int, "position": 1,
  "team": { …Team… },
  "matches": 21, "wins": 15, "draws": 3, "losses": 3,
  "scoresFor": 50, "scoresAgainst": 27, "points": 48,
  "scoreDiffFormatted": "+23",
  "promotion": { "id": int, "text": "Champions League" },
  "descriptions": [] }
```

Khác hệ bóng đá riêng: ở đây là `wins/draws/losses` (số nhiều) và `scoresFor/scoresAgainst`, còn backend riêng dùng `won/draw/lost` và `goalsFor/goalsAgainst`.

**Diễn biến** (`incidents[i]`) — mảng **trộn nhiều loại**, phân biệt bằng `incidentType`:

```json
{ "incidentType": "period",     "text": "FT", "homeScore": 2, "awayScore": 1,
  "time": 90, "addedTime": 0, "isLive": false,
  "timeSeconds": 5400, "reversedPeriodTime": 1,
  "reversedPeriodTimeSeconds": …, "periodTimeSeconds": … }
```

`incidentType` gặp trong thực tế: `period`, `goal`, `card`, `substitution`, `injuryTime`, `penaltyShootout`, `varDecision`. Mỗi loại có tập trường riêng, phải switch theo `incidentType` chứ không đọc chung được.

**Kết quả tìm kiếm** (`results[i]`):

```json
{ "type": "team", "score": 1234.5,
  "entity": { "id": …, "name": …, "slug": …, "nameCode": …, "sport": {…},
              "country": {…}, "teamColors": {…}, "userCount": int } }
```

`type` quyết định `entity` là đội, cầu thủ, giải hay trận — cùng một mảng chứa lẫn lộn cả bốn.

### Danh sách 86 endpoint

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

Tất cả trả **ảnh nhị phân**, không phải JSON. Không có vỏ `success`/`data`.

| # | Nguồn | Loại ảnh | URL | Content-Type | Ghi chú |
|---:|---|---|---|---|---|
| 1 | Sportmonks | Logo đội / giải / ảnh cầu thủ / cờ | `https://cdn.sportmonks.com/images/soccer{đường dẫn tương đối}` | `image/png` | Ví dụ `/teams/18/18.png`, `/leagues/27/27.png`. Khoá `image_base_url` của Remote Config; API cũng trả sẵn URL đầy đủ ở `*_image_path` / `*LogoUrl` |
| 2 | Sofascore | Logo đội | `https://img.sofascore.com/api/v1/team/{id}/image` | `image/png` | Không có gói thương mại |
| 3 | Sofascore | Logo giải | `https://img.sofascore.com/api/v1/unique-tournament/{id}/image` | `image/png` | |
| 4 | Sofascore | Logo chặng đua | `https://img.sofascore.com/api/v1/unique-stage/{id}/image` | `image/png` | |
| 5 | Sofascore | Logo khu vực | `https://img.sofascore.com/api/v1/category/{id}/image` | `image/png` | |
| 6 | Sofascore | Cờ quốc gia | `https://img.sofascore.com/api/v1/country/{alpha2}/flag` | `image/png` | `alpha2` = VN, GB, US… |
| 7 | Sofascore | Ảnh cầu thủ | `https://img.sofascore.com/api/v1/player/{id}/image` | `image/png` | |
| 8 | Sofascore | Ảnh HLV | `https://img.sofascore.com/api/v1/manager/{id}/image` | `image/png` | |
| 9 | YouTube | Ảnh bìa highlight | `https://img.youtube.com/vi/{videoId}/hqdefault.jpg` | `image/jpeg` | Miễn phí, không cần API key |

Highlightly (dùng trong `match-high-light`) trả thêm hai dạng: `https://highlightly.net/soccer/images/teams/{id}.png` và `.../countries/{cc}.svg` — **SVG**, một số loader ảnh không đọc được nếu không bật plugin SVG. Trường logo có thể là **chuỗi rỗng** chứ không phải null.

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

Ngoài ra còn hai API cấu hình quảng cáo, không thuộc dữ liệu bóng đá:

| Dịch vụ | Request | Response |
|---|---|---|
| Cấu hình inter/reward | `GET https://api.gamesontop.com/v4/games/services/remoteconfig`, header `pn` = package name, `p` = 1 | `{ "data": { "rc_ads_from": int, "rc_ads_set": { "<ngưỡng>": { "firstDelay", "rewardDelay", "firstDelayType", "rewardInterDelay", "adsIntersConfig": { "<placement>": int } } } } }` |
| Cấu hình native | Firebase Remote Config, khoá `placement_config` | Xem `docs/ADS_NATIVE_DESIGN.md` |

---

## Ghi chú

1. App **không gọi thẳng** nhà cung cấp dữ liệu bóng đá. Nó gọi backend riêng `sp098-live-score.pandaglobal.top`; backend đó mới là bên mua dữ liệu. ID đội, ID giải và ảnh đều theo hệ **Sportmonks** — DB đóng gói trong app có 2.367 giải và 64.452 đội theo hệ ID này.
2. **Ba hệ ID không nói chuyện được với nhau**: Sportmonks (9/10 endpoint bóng đá), Highlightly (riêng `match-high-light`), Sofascore (86 endpoint đa môn). Không có bảng ánh xạ, nên không nối một trận bóng đá với video highlight hay với trang Sofascore của chính nó.
3. **Ba kiểu đặt tên trường trong cùng một backend**: `league-live` và `match-centre-live` dùng `camelCase`; `standings`, `list-fixtures-upcoming`, `fixtures-by-date-for-team`, `list-player` dùng `snake_case`; `match-forecast-new` trộn cả hai (`match_result` nhưng `noGoal`, `totalGoals`, `Ft`/`H1`/`H2` viết hoa). Parser phải viết riêng cho từng endpoint.
4. `match-forecast-new` **đang hỏng phía server** từ trước tới nay, xác nhận lại 16/09/2026 — xem §1.6. Không phải lỗi của app. `language` hiện không có tác dụng.
5. Backend bóng đá **chặn mềm khi bị dò liên tục**: vẫn trả HTTP 200 nhưng đổi nội dung thành `"Không tìm thấy fixtures nào"` — trông y hệt lỗi thiếu dữ liệu. Khi kiểm thử phải giãn ≥3 giây mỗi request.
6. Backend bóng đá đứng sau **Cloudflare** và lọc theo User-Agent: `python-urllib` bị 403, `curl` mặc định thì qua. Khi viết script kiểm thử phải đặt User-Agent.
7. Cột *Dùng ở màn* ghi **"Chưa dùng trong app"** nghĩa là hàm đã port sẵn theo bản Kotlin nhưng chưa có màn nào gọi tới.
8. `match-centre-vote-team-win` là endpoint **POST** duy nhất; tham số nằm ở query string, không có body.
