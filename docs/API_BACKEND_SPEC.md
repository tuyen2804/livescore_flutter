# Spec dựng backend bóng đá cho app Live Score

> Viết từ **mã nguồn parser** của app, không phải từ response mẫu. Nguồn: [football_models.dart](../lib/data/models/football/football_models.dart), [football_remote_data_source.dart](../lib/data/datasources/remote/football_remote_data_source.dart), [football_repository_impl.dart](../lib/data/repositories/football_repository_impl.dart), [match_status.dart](../lib/core/utils/match_status.dart), [dio_client.dart](../lib/core/network/dio_client.dart).
>
> Mục tiêu: dựng backend mới mà **app hiện tại chạy được ngay, không sửa một dòng Dart nào**. Chỗ nào nên làm khác đi thì ghi rõ ở §7 — nhưng làm khác là phải sửa app.

---

## 1. Hợp đồng chung

### 1.1 Gắn vào app

App lấy base URL từ **Firebase Remote Config**, khoá `base_url`. Đổi backend = đổi giá trị khoá đó, không cần phát hành bản mới. Mặc định hard-code khi Remote Config chưa về: `https://sp098-live-score.pandaglobal.top` ([api_constants.dart:6](../lib/core/constants/api_constants.dart#L6)).

Khoá thứ hai `image_base_url` mặc định `https://cdn.sportmonks.com/images/soccer`.

### 1.2 Header app gửi

```
Accept: application/json
Accept-Charset: UTF-8
```

Không có API key, không có token, không có `User-Agent` cố định. Nếu backend mới cần xác thực thì **phải sửa app** — hiện không có chỗ nào gắn key.

### 1.3 Timeout

Connect 30 giây, receive 30 giây, send 30 giây. Endpoint nào chậm hơn 30 giây coi như hỏng.

### 1.4 Mã HTTP — chỗ dễ làm sai nhất

```dart
validateStatus: (code) => code != null && code < 400
```

**Mọi mã ≥ 400 đều ném exception và app hiện màn hình lỗi.** Không có dữ liệu **không phải** là lỗi.

| Tình huống | Backend phải trả | Không được trả |
|---|---|---|
| Không có trận nào hôm đó | `200` + `{"success":true,"data":[]}` | `404`, `500` |
| `fixture_id` không tồn tại | `200` + `{"success":true,"data":null}` | `404` |
| Thiếu tham số bắt buộc | `400` (app báo lỗi — đúng) | `200` |
| Sự cố thật phía server | `500` | `200` kèm `error` bên trong |

Backend hiện tại làm sai chỗ này: `match-forecast-new` trả `500` khi chỉ đơn giản là chưa có dự đoán, khiến app hiện lỗi thay vì hiện trạng thái rỗng.

### 1.5 Vỏ response

```json
{ "success": true, "data": … }
```

Mức độ app thực sự kiểm tra `success` — **không đồng đều**, đây là hành vi thật của parser:

| Endpoint | Có đọc `success`? |
|---|---|
| `list-player` | **Có** — `success:false` → trả mảng rỗng |
| `match-forecast-new` | **Có** — `success:false` → coi như không có dự đoán |
| 8 endpoint còn lại | **Không** — chỉ đọc `data`, `success` bị bỏ qua hoàn toàn |

Nên: luôn đặt `success` đúng, nhưng đừng trông chờ app dùng nó để phân biệt lỗi. Cách duy nhất chắc chắn là mã HTTP.

### 1.6 Ép kiểu — backend được lỏng tay ở đâu

Parser dùng 3 hàm ép kiểu ([football_models.dart:3-7](../lib/data/models/football/football_models.dart#L3)):

```dart
int?  _int(v)  => v is int ? v : (v is num ? v.toInt() : int.tryParse('$v'));
String? _str(v) => v?.toString();
bool? _bool(v) => v is bool ? v : (v == null ? null : v == 1 || v == 'true');
```

| Kiểu | Chấp nhận | KHÔNG chấp nhận |
|---|---|---|
| int | `5`, `5.0`, `"5"` | `"năm"`, `"5 "` (có dấu cách → `tryParse` trả null) |
| string | mọi thứ (số cũng thành chuỗi) | — |
| bool | `true`, `false`, `1`, `"true"` | **`"1"` (chuỗi) → `false`**, `0` → `false`, `"True"` viết hoa → `false` |

Bẫy duy nhất là boolean: gửi `"1"` dạng chuỗi sẽ bị hiểu thành `false`. Cứ gửi `true`/`false` JSON chuẩn.

Trường thiếu, trường `null`, hay sai kiểu đều **không làm crash** — parser thay bằng giá trị mặc định. Nghĩa là backend có thể bỏ hẳn trường không có dữ liệu thay vì gửi chuỗi rỗng.

### 1.7 Ràng buộc cứng: hệ ID phải là Sportmonks

App đóng gói sẵn SQLite `assets/db/sp098_live_score13.db`:

| Bảng | Số dòng | Cột |
|---|---:|---|
| `league` | 2.367 | `id, country_id, name, image_path, sub_type, priority, is_favourite, time_use` |
| `team` | 64.452 | `id, country_id, name, image_path, type, is_favourite, priority, time_use` |

DB này quyết định: giải nào là "top" (cột `priority` khác null → xếp lên đầu Home), màn chọn giải/đội yêu thích hiển thị gì, và **giải nào được coi là bóng đá** — `leagueId` không có trong bảng `league` bị app đoán là môn khác và gom vào nhánh Sofascore ([football_repository_impl.dart:127](../lib/data/repositories/football_repository_impl.dart#L127)).

**Hệ quả:** backend mới phải trả `leagueId` / `homeId` / `awayId` / `team_id` **theo đúng ID Sportmonks trong DB này**. Dùng hệ ID khác thì phải thay luôn file DB và build lại app.

---

## 2. Bảng endpoint

| # | Method | Đường dẫn | Query | Kiểu `data` |
|---:|---|---|---|---|
| 1 | GET | `/live-score/league-live` | `date` | mảng `Match` |
| 2 | GET | `/live-score/match-centre-live` | `fixture_id` | object `MatchCentre` |
| 3 | GET | `/live-score/standings` | `league_id` | mảng `StandingRow` |
| 4 | GET | `/live-score/list-fixtures-upcoming` | `league_id` | mảng `LeagueFixture` |
| 5 | GET | `/live-score/match-high-light` | `date` | mảng `Highlight` |
| 6 | GET | `/live-score/match-forecast-new` | `fixture_id`, `language` | object `Forecast` |
| 7 | GET | `/live-score/fixtures-by-date-for-team` | `team_id` | mảng `TeamFixture` |
| 8 | GET | `/live-score/match-centre-vote` | `fixture_id` | object `Vote` |
| 9 | POST | `/live-score/match-centre-vote-team-win` | `fixture_id` + 1 cờ | app bỏ qua |
| 10 | GET | `/live-score/list-player` | `team_id` | mảng `SquadPlayer` |

`date` định dạng `YYYY-MM-DD`. Mọi id là số nguyên.

---

## 3. Từng endpoint

### 3.1 `GET /live-score/league-live?date=YYYY-MM-DD`

Feed trận theo ngày — endpoint bận nhất, app gọi **3 lần song song** mỗi lần đổi ngày: hôm trước, hôm đó, hôm sau ([football_repository_impl.dart:59](../lib/data/repositories/football_repository_impl.dart#L59)). Lý do: trận 23:00 giờ UTC có thể rơi sang ngày khác theo giờ máy người dùng. App tự khử trùng `id` và tự lọc lại theo giờ địa phương, nên **backend cứ trả theo ngày UTC, không cần đoán múi giờ**.

Hệ quả về tải: mỗi lần user quẹt sang ngày khác là 3 request. Endpoint này phải cache tốt.

```json
{ "success": true, "data": [ {
  "id":              19635911,
  "date":            "2026-09-16",
  "countryId":       47,
  "leagueId":        573,
  "seasonId":        26806,
  "nameVenue":       "Strawberry Arena",
  "name":            "AIK vs Mjällby",
  "kickoffUtc":      "2026-09-16 17:00:00",
  "kickoffEpoch":    1789578000,
  "lengthMinutes":   90,
  "state":           1,
  "groupName":       "",
  "roundName":       "18",
  "score":           "0 - 0",
  "homeId":          2825,
  "awayId":          411,
  "homeName":        "AIK",
  "awayName":        "Mjällby",
  "homeShortName":   "AIK",
  "awayShortName":   "MJA",
  "homeTeamLogoUrl": "https://cdn.sportmonks.com/images/soccer/teams/9/2825.png",
  "awayTeamLogoUrl": "https://cdn.sportmonks.com/images/soccer/teams/27/411.png",
  "leagueLogoUrl":   "https://cdn.sportmonks.com/images/soccer/leagues/29/573.png",
  "leagueName":      "Allsvenskan",
  "playingTime":     0
} ] }
```

| Trường | Kiểu | Bắt buộc | App dùng làm gì |
|---|---|---|---|
| `id` | int | **Có** | Khoá khử trùng, tham số cho `match-centre-live` |
| `kickoffEpoch` | int, **giây** | **Có** | Lọc theo ngày địa phương, sắp xếp, hiện giờ đá. Sai trường này là trận biến mất khỏi Home |
| `leagueId` | int | **Có** | Gom nhóm theo giải, tra DB để biết giải top / có phải bóng đá |
| `leagueName` | string | **Có** | Tiêu đề nhóm. `"World Cup"` (không phân biệt hoa thường) được ép lên đầu danh sách |
| `state` | int | **Có** | Trạng thái trận — bảng mã ở §4.1 |
| `homeId` / `awayId` | int | **Có** | Đối chiếu đội yêu thích để đẩy trận lên đầu |
| `homeName` / `awayName` | string | **Có** | Tên hiển thị |
| `score` | string | Không | `"2 - 1"`. Tách bằng `-` rồi `trim`, nên `"2-1"` cũng được. Thiếu hoặc không parse được → không hiện tỷ số |
| `playingTime` | int | Không | Phút đang đá, chỉ hiện khi `state` thuộc nhóm LIVE |
| `groupName` | string | Không | Tên bảng. **Cũng dùng để đoán môn khác**: giải lạ có `groupName` thì lấy làm tên nhánh |
| `homeTeamLogoUrl`… | string | Không | URL **đầy đủ**, không phải đường dẫn tương đối |
| `date`, `countryId`, `seasonId`, `nameVenue`, `kickoffUtc`, `lengthMinutes`, `roundName`, `homeShortName`, `awayShortName` | | Không | Parse nhưng màn Home không hiển thị |

`kickoffUtc` là chuỗi `"YYYY-MM-DD HH:mm:ss"` — không phải ISO-8601, không có `T`, không có `Z`.

### 3.2 `GET /live-score/match-centre-live?fixture_id=`

Một lần gọi trả cả 5 khối cho màn chi tiết trận. `data` là **object**, không phải mảng. `data == null` → app coi như không có trận.

```json
{ "success": true, "data": {
    "match":      { … },
    "events":     [ … ],
    "lineups":    [ … ],
    "statistics": [ … ],
    "h2h":        [ … ] } }
```

Bốn mảng đều **không bắt buộc** — thiếu thì tab tương ứng rỗng, không lỗi.

**`data.match`** — y hệt `Match` ở §3.1, chỉ khác: bỏ `date`/`countryId`, thêm `time` (mốc thời gian server, mili-giây — app parse nhưng không dùng). Chỉ `id`, `homeId`, `awayId`, `leagueId`, `seasonId` là bắt buộc.

**`data.events`** — diễn biến, một phần tử một sự kiện, hai đội chung mảng:

```json
{ "id": 157926696, "fixtureId": 19667159, "teamId": 6188,
  "typeName": "Yellowcard", "minute": 7, "extraMinute": null,
  "playerId": 218531, "playerName": "Bressan", "relatedPlayerName": "" }
```

- `teamId` phải khớp `match.homeId` để app biết vẽ bên trái hay phải.
- `typeName` là **enum chuỗi phân biệt hoa thường** — bảng ở §4.2.
- `extraMinute` chỉ hiện khi > 0 (dạng `45+2`).
- `relatedPlayerName` là cầu thủ vào sân khi `typeName = "Substitution"`; so khớp **theo tên**, không theo id — nên tên ở đây phải trùng ký tự với `playerName` trong `lineups`.

**`data.lineups`** — một phần tử một cầu thủ, cả hai đội chung mảng, lọc theo `teamId`:

```json
{ "id": 14674700927, "fixtureId": 19667159, "teamId": 2352,
  "playerId": 37577104, "playerName": "Marcelo Alixandre Ajul",
  "playerImageUrl": "https://cdn.sportmonks.com/images/soccer/players/16/37577104.png",
  "jerseyNumber": 3, "formation": "4-2-3-1",
  "positionField": "2:4", "isCaptain": 0 }
```

- `formation` lặp lại ở mọi cầu thủ cùng đội — app lấy giá trị đầu tiên.
- `positionField` = `"hàng:cột"` để xếp sơ đồ sân. Cầu thủ dự bị để `null` hoặc bỏ hẳn trường.
- `isCaptain` là **`0`/`1` kiểu int**, không phải boolean. App so `== 1`.
- App **không đọc** mảng `stats[]` của backend hiện tại. Đưa vào cũng không hiển thị.

**`data.statistics`** — đúng 2 phần tử, mỗi đội một, phân biệt bằng `teamId`:

```json
{ "id": 996521978, "fixtureId": 19667159, "teamId": 2352,
  "shotOnTarget": 3, "shotOffTarget": 5, "blockerShots": 3,
  "possession": 57, "cornerKicks": 3, "offsides": 2, "fouls": 7,
  "throwIn": 21, "yellowCards": 2, "redCards": 0 }
```

Tất cả đều không bắt buộc; thiếu chỉ số nào thì dòng đó không hiện. `possession` là **phần trăm dạng số nguyên** (57 = 57%), không phải 0.57.

**`data.h2h`** — đúng 1 phần tử, thống kê đối đầu:

```json
{ "fixtureId": 19667159, "team1Id": 6188, "team2Id": 2352,
  "totalWin": 2, "totalDraws": 1, "totalLoss": 1,
  "winLastFive": 2, "drawsLastFive": 1 }
```

`totalWin` / `totalLoss` tính **theo `team1Id`**.

### 3.3 `GET /live-score/standings?league_id=`

```json
{ "success": true, "data": [ {
  "id":              18443436,
  "position":        1,
  "points":          48,
  "result":          "equal",
  "name":            "Sirius",
  "image_path":      "https://cdn.sportmonks.com/images/soccer/teams/22/2678.png",
  "overall_matches": 21,
  "won": 15, "draw": 3, "lost": 3,
  "goalsFor": 50, "goalsAgainst": 27, "goal_difference": 23
} ] }
```

Chú ý: **`id` ở đây là id dòng bảng, không phải id đội.** App không suy ra id đội từ đây, nên bấm vào một dòng bảng xếp hạng không mở được trang đội. Nếu backend mới muốn sửa chuyện đó thì phải thêm trường mới **và** sửa app.

`result` là enum chuỗi: `"equal"` / `"up"` / `"down"` — hướng đổi thứ hạng. Giá trị lạ được xử lý như `"equal"`.

Trường này trộn hai kiểu đặt tên (`goalsFor` camelCase nhưng `goal_difference` snake_case) — parser đã khoá cứng theo đúng tên hiện tại, đổi là app đọc ra null.

### 3.4 `GET /live-score/list-fixtures-upcoming?league_id=`

```json
{ "success": true, "data": [ {
  "id":                19635911,
  "league_id":         573,
  "starting_at":       "2026-09-16 17:00:00",
  "home_name":         "Mjällby",
  "away_name":         "AIK",
  "home_image_path":   "https://cdn.sportmonks.com/images/soccer/teams/27/411.png",
  "away_image_path":   "https://cdn.sportmonks.com/images/soccer/teams/9/2825.png",
  "score":             "1 - 2"
} ] }
```

App chỉ đọc **8 trường** này. `league_name` và `league_image_path` mà backend hiện tại trả ra thì parser **bỏ qua hoàn toàn**.

**`score` là trường backend hiện tại không trả nhưng app đã sẵn sàng đọc** ([league_detail_screen.dart:115](../lib/presentation/screens/detail/league_detail_screen.dart#L115)). Backend mới cứ trả vào, tab Fixtures sẽ hiện tỷ số cho trận đã đá mà không cần sửa app — đây là thứ nên làm ngay.

Không có `state`, nên trận đã đá hay chưa chỉ suy được từ `starting_at`.

### 3.5 `GET /live-score/fixtures-by-date-for-team?team_id=`

Cùng hình dạng §3.4 nhưng parser **khác** — đọc thêm id đội và tên giải, và **không** đọc `score`:

```json
{ "success": true, "data": [ {
  "id":                19635911,
  "league_id":         573,
  "league_name":       "Allsvenskan",
  "league_image_path": "https://cdn.sportmonks.com/images/soccer/leagues/29/573.png",
  "starting_at":       "2026-09-16 17:00:00",
  "home_team_id":      411,
  "home_name":         "Mjällby",
  "home_image_path":   "…",
  "away_team_id":      2825,
  "away_name":         "AIK",
  "away_image_path":   "…"
} ] }
```

Hai endpoint 3.4 và 3.5 trả gần như cùng một thứ nhưng app đọc hai tập trường khác nhau — **cứ trả cả `score` lẫn `*_team_id` ở cả hai**, dư không hại gì, mà sau này gộp làm một endpoint thì dễ.

### 3.6 `GET /live-score/match-high-light?date=YYYY-MM-DD`

```json
{ "success": true, "data": [ {
  "id":               606458,
  "title":            "Primera B: Barranquilla vs Ind. Yumbo",
  "url":              "https://www.youtube.com/watch?v=-_j3gE1Rb0c",
  "imgUrl":           "https://i.ytimg.com/vi/-_j3gE1Rb0c/hqdefault.jpg",
  "source":           "youtube",
  "channel":          "Win Sports",
  "matchId":          1318733361,
  "matchDate":        1789509600000,
  "matchRound":       "Clausura - 9",
  "homeTeamId":       1248350,
  "homeTeamName":     "Barranquilla",
  "homeTeamLogo":     "…",
  "awayTeamId":       23327545,
  "awayTeamName":     "Ind. Yumbo",
  "awayTeamLogo":     "",
  "leagueId":         205024,
  "leagueName":       "Primera B",
  "leagueLogo":       "…",
  "leagueSeason":     2026,
  "matchCountryCode": "CO",
  "matchCountryName": "Colombia",
  "matchCountryLogo": "…"
} ] }
```

Hai cái bẫy:

1. **`matchDate` là mili-giây**, trong khi `kickoffEpoch` ở §3.1 là **giây**. Backend hiện tại để vậy vì hai nguồn dữ liệu khác nhau. Giữ nguyên nếu muốn app chạy không sửa.
2. `matchId` / `leagueId` / `homeTeamId` ở đây là hệ ID của nhà cung cấp highlight (Highlightly), **không map được** sang `fixture_id` Sportmonks. Nên app không nối được video với trận.

Backend mới nên map sang ID Sportmonks — nhưng đó là việc của backend, app không đổi gì. Làm được thì bấm vào highlight mở thẳng chi tiết trận.

`url` phải là link YouTube đầy đủ; app tự tách `videoId` để nhúng player.

### 3.7 `GET /live-score/match-forecast-new?fixture_id=&language=`

Endpoint đang hỏng ở backend cũ. App đã có parser đầy đủ, backend mới cứ theo đúng khuôn này là chạy:

```json
{ "success": true, "data": {
  "match_result":        { "home": 45, "draw": 28, "away": 27, "accuracy": true },
  "first_goal":          { "home": 52, "noGoal": 8, "away": 40, "accuracy": true },
  "match_score":         { "home": 2, "away": 1, "accuracy": false },
  "total_goals":         { "totalGoals": 3, "accuracy": true },
  "both_teams_to_score": { "Ft": true, "H1": false, "H2": true, "accuracy": true },
  "corner":              { "home": 6, "away": 4, "accuracy": false },
  "confidence":          { "percent": 72, "accuracy": true },
  "analysis":            { "text": "…", "accuracy": true } } }
```

| Khối | Trường | Kiểu | Màn Prediction hiển thị |
|---|---|---|---|
| `match_result` | `home`, `draw`, `away` | int (%) | Thanh 3 đoạn |
| `first_goal` | `home`, `noGoal`, `away` | int (%) | Thanh 3 đoạn |
| `match_score` | `home`, `away` | int | Thẻ `"2 - 1"` |
| `total_goals` | `totalGoals` | int | Thẻ một số |
| `corner` | `home`, `away` | int | Thẻ `"6 - 4"` |
| `both_teams_to_score` | `Ft`, `H1`, `H2` | bool | Thẻ Yes/No — **chỉ `Ft` được hiển thị**, `H1`/`H2` parse rồi bỏ |
| `confidence` | `percent` | int | Thẻ `"72%"` + dùng luôn trong tiêu đề |
| `analysis` | `text` | string | Thẻ văn bản dài — **đây là chỗ duy nhất `language` có ý nghĩa** |

Quy tắc bắt buộc nhớ:

- **`Ft` / `H1` / `H2` viết hoa chữ cái đầu.** Gửi `ft`/`h1`/`h2` thường là app đọc ra null.
- Mọi khối đều không bắt buộc. **Thiếu cả 8 khối → app coi như chưa có dự đoán** và hiện trạng thái rỗng, không lỗi.
- `accuracy` là bool chấm đúng/sai sau trận. App parse nhưng **chưa màn nào hiển thị** — có thể bỏ ở v1.
- Ba khối phần trăm nên cộng lại bằng 100; app không kiểm tra nhưng thanh vẽ ra sẽ lệch.

Có một nhánh lỗi thứ ba mà app xử lý riêng — kế thừa từ backend cũ:

```json
{ "success": true, "data": { "error": true, "message": "…" } }
```

`data.error == true` → app coi như không có dự đoán. Backend mới **không cần dùng nhánh này**; cứ trả `data: null` cho gọn.

Chưa có dự đoán thì trả `200` + `data: null`, **đừng trả 500** — xem §1.4.

### 3.8 `GET /live-score/match-centre-vote?fixture_id=`

```json
{ "success": true, "data": {
    "fixtureId": 19667159,
    "countTeam1Win": 0, "countTeam2Win": 1, "countDraws": 1 } }
```

`countTeam1Win` là đội **nhà**, `countTeam2Win` là đội **khách**. App tự tính phần trăm; cả ba bằng 0 thì hiện 0% chứ không chia cho 0.

Parser có nhánh dự phòng: nếu không có `data` thì đọc thẳng các trường ở gốc response ([football_models.dart:707](../lib/data/models/football/football_models.dart#L707)). Nên `{"countTeam1Win":0,…}` phẳng cũng chạy — nhưng cứ theo vỏ chuẩn cho nhất quán.

### 3.9 `POST /live-score/match-centre-vote-team-win`

Tham số nằm ở **query string**, không có body. Đúng một cờ `=1` tuỳ lựa chọn:

```
POST /live-score/match-centre-vote-team-win?fixture_id=19667159&home_win=1
POST /live-score/match-centre-vote-team-win?fixture_id=19667159&draw=1
POST /live-score/match-centre-vote-team-win?fixture_id=19667159&away_win=1
```

App **không đọc response** — chỉ cần mã < 400. Bỏ phiếu xong app gọi lại §3.8 để lấy số mới.

Không có định danh người dùng nào được gửi lên. Muốn chặn bỏ phiếu trùng thì backend chỉ có IP để dựa vào, hoặc phải sửa app để gửi device id.

### 3.10 `GET /live-score/list-player?team_id=`

```json
{ "success": true, "data": [ {
  "name":          "Hervé Matthys",
  "position_name": "Defender",
  "image_path":    "https://cdn.sportmonks.com/images/soccer/players/9/63049.png",
  "height":        186,
  "weight":        77,
  "date_of_birth": "1996-01-19",
  "jersey_number": 3,
  "nationality":   "Belgium"
} ] }
```

Đây là endpoint **duy nhất app kiểm tra `success`** — `success: false` trả mảng rỗng bất kể `data` có gì.

- Không có `player_id`; app không cần, nhưng cũng vì thế không mở được trang cầu thủ.
- `position_name` là chuỗi hiển thị thẳng: `Goalkeeper` / `Defender` / `Midfielder` / `Attacker`. Thiếu → `"N/A"`.
- `name` được `trim()`; thiếu → `"Unknown"`.
- `height`/`weight` = `0` hoặc thiếu → app hiện `"-"`, nên không cần gửi `0` giả.
- `date_of_birth` phải là `YYYY-MM-DD` để `DateTime.tryParse` đọc được; app tự tính tuổi.
- `national_path` backend cũ có trả nhưng **parser bỏ qua**.

---

## 4. Bảng enum

### 4.1 `state` — mã trạng thái trận

Bảng này app khoá cứng ([match_status.dart:19](../lib/core/utils/match_status.dart#L19)). Backend mới **phải dùng đúng những con số này**, không tự đặt lại.

| `state` | Nhãn | Ý nghĩa |
|---|---|---|
| `1`, `26` | `NS` | Chưa bắt đầu |
| `2`, `4`, `6`, `21`, `22`, `23` | `LIVE` | Đang đá — hiện `playingTime` kèm dấu phút |
| `3` | `HT` | Nghỉ giữa hiệp |
| `5`, `8`, `17` | `FT` | Kết thúc |
| `7` | `AET` | Kết thúc sau hiệp phụ |
| `9`, `25` | `PEN` | Kết thúc sau luân lưu |
| `10`, `11`, `16`, `18` | `POSTP` | Hoãn |
| `12`, `14`, `15`, `20` | `CANCL` | Huỷ |
| `13`, `19` | `TBD` | Chưa xác định |
| còn lại | `TBD` | Mặc định |

Màn Live lọc theo danh sách riêng: `[2, 3, 4, 6, 7, 9, 21, 22, 23, 25]` — tức HT, AET, PEN cũng nằm trong "đang diễn ra".

Thứ tự sắp xếp trong một giải: `FT` → `POSTP` → `NS` → còn lại.

Backend làm tối thiểu thì chỉ cần 5 mã: **`1` chưa đá · `2` đang đá · `3` nghỉ giữa hiệp · `5` kết thúc · `10` hoãn.**

### 4.2 `typeName` — loại sự kiện trong `events`

Phân biệt hoa thường, so khớp chính xác ([match_lineup_tab.dart:347](../lib/presentation/screens/detail/tabs/match_lineup_tab.dart#L347)):

| `typeName` | Timeline | Huy hiệu trên sơ đồ đội hình |
|---|---|---|
| `Goal` | icon bóng | chấm bàn thắng |
| `Penalty` | icon bóng | chấm bàn thắng |
| `Yellowcard` | thẻ vàng | thẻ vàng |
| `Redcard` | thẻ đỏ | thẻ đỏ |
| `Yellowred` | (icon mặc định) | thẻ đỏ |
| `Substitution` | icon thay người | mũi tên ra/vào |
| khác | icon bóng mặc định | không có |

Icon timeline tra bằng **chữ thường** nên `GOAL` cũng ra icon bóng — nhưng huy hiệu đội hình so khớp **nguyên dạng**, nên `GOAL` sẽ mất huy hiệu. Cứ viết đúng như bảng.

### 4.3 Enum nhỏ

| Trường | Giá trị |
|---|---|
| `result` (standings) | `equal` · `up` · `down` |
| `isCaptain` (lineups) | `0` · `1` — int, không phải bool |
| `source` (highlight) | `youtube` |
| `position_name` (squad) | `Goalkeeper` · `Defender` · `Midfielder` · `Attacker` |

---

## 5. Định dạng thời gian — ba kiểu trong cùng một API

| Trường | Kiểu | Ví dụ |
|---|---|---|
| `kickoffEpoch` | int, **giây** | `1789578000` |
| `matchDate` (highlight) | int, **mili-giây** | `1789509600000` |
| `time` (match centre) | int, **mili-giây** | `1789526607307` |
| `kickoffUtc`, `starting_at` | string `"YYYY-MM-DD HH:mm:ss"` UTC | `"2026-09-16 17:00:00"` |
| `date` | string `"YYYY-MM-DD"` | `"2026-09-16"` |
| `date_of_birth` | string `"YYYY-MM-DD"` | `"1996-01-19"` |

Không có trường nào dùng ISO-8601 chuẩn. App tính giờ hiển thị **chỉ từ `kickoffEpoch`**; các chuỗi thời gian còn lại gần như chỉ để tham khảo.

---

## 6. Ảnh

Mọi trường URL ảnh (`homeTeamLogoUrl`, `image_path`, `leagueLogo`…) app dùng **nguyên văn**, không ghép base URL. Backend phải trả URL tuyệt đối.

Ngoại lệ: khoá Remote Config `image_base_url` chỉ dùng cho ảnh tra từ SQLite đóng gói (màn chọn giải/đội), không dính đến response API.

Ảnh thiếu thì trả **chuỗi rỗng hoặc bỏ trường**, app tự hiện placeholder. Đừng trả URL 404 — app sẽ đợi hết timeout rồi mới bỏ cuộc.

---

## 7. Nếu dựng mới, nên sửa gì

Những thứ dưới đây **đều phải sửa app kèm theo**. Xếp theo tỷ lệ lợi ích trên công sửa.

| # | Vấn đề hiện tại | Nên làm | Phải sửa gì trong app |
|---:|---|---|---|
| 1 | `list-fixtures-upcoming` không có `score` | Trả `score` | **Không cần sửa** — parser đã đọc sẵn |
| 2 | Trả `500` khi chỉ là không có dữ liệu | `200` + `data: null` | Không cần sửa |
| 3 | Highlight dùng hệ ID khác | Map sang `fixture_id` Sportmonks | Không cần sửa; mở thêm được đường nối highlight ↔ trận |
| 4 | `standings.id` là id dòng, không phải id đội | Thêm `team_id` | Thêm 1 trường vào `StandingTeamDto`, sửa màn bảng xếp hạng |
| 5 | `list-player` không có `player_id` | Thêm `player_id` | Thêm 1 trường vào `SquadPlayerDto` |
| 6 | Ba kiểu đặt tên trường lẫn lộn | Thống nhất một kiểu | Sửa toàn bộ `football_models.dart` |
| 7 | Home phải gọi 3 ngày một lúc | Endpoint nhận `from`/`to` | Sửa `getLeagueLive` + repository |
| 8 | Bỏ phiếu không định danh người dùng | Nhận `device_id` | Sửa `voteTeam` |
| 9 | Hai endpoint lịch trùng nhau | Gộp làm một | Bỏ một DTO, sửa 2 màn |

Một điều **không nên đổi**: hệ ID phải giữ Sportmonks, vì SQLite 64.452 đội trong app đã theo hệ đó (§1.7). Đổi ID = phải xuất lại DB và build lại app, kéo theo mất hết giải/đội yêu thích người dùng đã chọn.

---

## 8. Danh sách kiểm tra khi backend mới chạy thử

1. `league-live` một ngày có trận → app hiện đủ trận, đúng giờ địa phương, giải top nằm trên.
2. `league-live` một ngày không có trận → `200` + `data: []`, app hiện trạng thái rỗng, **không phải màn lỗi**.
3. Đổi ngày trên Home → backend nhận **3 request** cho 3 ngày liền nhau.
4. Trận đang đá `state = 2` + `playingTime = 67` → thẻ hiện `67'`.
5. `match-centre-live` thiếu `lineups` → tab Lineup rỗng, 3 tab còn lại vẫn chạy.
6. `typeName = "Substitution"` với `relatedPlayerName` khớp tên trong `lineups` → mũi tên ra/vào hiện đúng cả hai cầu thủ.
7. `match-forecast-new` trả `data: null` → màn Prediction hiện trạng thái rỗng, không lỗi.
8. `match-forecast-new` trả đủ 8 khối, `Ft` viết hoa → tất cả thẻ hiện.
9. Bỏ phiếu → `POST` trả < 400, app gọi lại endpoint đọc, số tăng.
10. `list-player` với `success: false` → màn Squad rỗng (đúng thiết kế).
11. Tắt mạng giữa chừng → app hiện lỗi mạng, không treo quá 30 giây.
