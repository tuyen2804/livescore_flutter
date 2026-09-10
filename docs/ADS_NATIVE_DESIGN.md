# Native Ads — thiết kế + tình trạng cài đặt (v7)

> Trạng thái: **đã code xong và chạy được trên Android** (10/09/2026). Xem mục 16. Cập nhật 10/09/2026 sau khi đọc
> `nativead_sdk_guide.html` (SDK v12.7.0). Mọi con số đếm từ mã nguồn và
> `placement_config.json` thật.
>
> **v6 sửa gì:** chốt quy ước tên layout (mục 6.1) và chốt iOS làm song song
> nhưng không build từ máy này. Thêm mục 15 — mediation đã gắn xong.
>
> **v5 sửa gì:** làm rõ ý nghĩa **slot vs id** (mục 5.1) — số slot quyết định
> số quảng cáo hiện cùng lúc, còn nhiều id trong một slot chỉ là chuỗi dự phòng
> high-floor cho **một** quảng cáo. Đổi cách thử lại khi nạp hỏng sang **backoff
> luỹ thừa 2, trần 64 giây** (mục 3).
>
> **v4 làm gì:** giữ **nguyên cấu trúc config cũ** — `unions[] → slots[]`,
> `button_sequence[]`, `load_policy{}`, `style{}`. Chỉ bỏ những trường **thực sự
> không dùng**, quyết định dựa trên thống kê giá trị chứ không phải cảm tính
> (mục 2). Bỏ hẳn `load_prepare_mode` vì app tự gọi preload (mục 3).

---

## 1. Vấn đề gốc: không port thẳng được

Interstitial / App-Open / Reward dùng thẳng `com.google.android.gms.ads` nên
port sang `google_mobile_ads` là ánh xạ 1-1. **Native thì không.**

`app/build.gradle.kts` nạp 4 thư viện nhị phân đóng trong `app/libs/`
(`CustomNativeAdsApi`, `AdsCore`, `UtilityHelper`, `ViewHandleApi`) cộng file mã
hoá `nativeads_class_release.bin`, `ck.dat`, `pk.dat`. Toàn bộ phần render
native, đọc `placement_config`, xoay union/slot, chuỗi nút của fullscreen đều
nằm trong đó. Không mã nguồn, không bản Flutter.

→ **Viết lại từ đầu** bằng `google_mobile_ads` + code nền tảng.

---

## 2. Bỏ trường nào — dựa trên thống kê thật

Tôi đếm giá trị của từng trường trên cả 15 placement. Trường nào **toàn null/0**
hoặc **chỉ có đúng một giá trị** thì không phải cấu hình, chỉ là hằng số chép
đi chép lại → cứng vào code.

### 2.1 Bỏ vì toàn null hoặc chỉ một giá trị

| Trường | Xuất hiện | Giá trị | Xử lý |
|---|---:|---|---|
| `border_color` | 14 | toàn `null` | bỏ |
| `border_width_dp` | 14 | toàn `0` | bỏ |
| `corner_radius_dp` | 14 | toàn `0` | bỏ |
| `body_text_size_sp` | 13 | toàn `14` | cứng = 14sp |
| `bg_color` (trong `cta_config`) | 13 | toàn `#FFA600` | cứng |
| `text_color` (trong `cta_config`) | 13 | toàn `#FFFFFF` | cứng |
| `ctaCornerRadius` | 2 | toàn `24` | suy từ `cta_shape` |
| `mediaCornerRadius` | 2 | toàn `12` | cứng |
| `iconCornerRadius` | 2 | toàn `8` | cứng |
| `adLabelColor` | 2 | toàn `#FFD740` | cứng |
| `starRatingColor` | 2 | toàn `#FFC107` | cứng |
| `display_mode` | 2 | toàn `OVERLAY` | cứng |
| `reload_delay_ms` | 1 | `1000` | cứng |
| `show_readiness` | 1 | `FIRST_SLOT` | cứng |
| `max_retries` | 1 | `5` | cứng |

### 2.2 Bỏ theo yêu cầu của bạn

| Trường | Xuất hiện | Giá trị | Lý do |
|---|---:|---|---|
| `native_width` | 12 | 340 ×7, 400 ×2, 320, 150 | Kích thước ads — layout tự co theo khung chứa |
| `native_height` | 2 | toàn `800` | nt |
| `cta_config.size_dp` | 13 | 60 ×12, 30 | Kích thước nút CTA |
| `cta_config.text_size_sp` | 13 | 20 ×10, 19 ×2, 14 | nt |
| `cta_config.corner_radius_dp` | 13 | 10 ×10, 24 ×3 | Suy được từ `shape`: ROUNDED_RECT→10, PILL→24 |
| `load_prepare_mode` | 15 | ON_DEMAND ×14, MANUAL ×1 | Xem mục 3 |

### 2.3 Giữ — vì thật sự có nhiều giá trị

| Trường | Số giá trị | Các giá trị |
|---|---:|---|
| `ids` | — | 10/15 placement có 2 id (high-floor) |
| `layout` | 5 | xem mục 6 |
| `bg_color` | 2 | `#1F1E23` ×13, `#1A2744` |
| `headline_color` | 1 | `#FFFFFF` — giữ vì là màu chữ chính, sẽ cần khi đổi theme |
| `body_color` | 2 | `#FFFF00` ×10, `#CCCCCC` ×3 |
| `headline_text_size_sp` | 3 | 17 ×10, 19 ×2, 14 |
| `cta_shape` | 2 | `ROUNDED_RECT` ×10, `PILL` ×3 |
| `type` | 2 | INLINE ×13, FULLSCREEN ×2 |
| `gravity` | 2 | `TOP\|CENTER_HORIZONTAL` ×2, `BOTTOM\|CENTER_HORIZONTAL` |
| `bg_alpha` | 2 | 0.95, 0.85 |
| `reload_mode` | 4 | xem mục 7 |
| `reload_interval_sec` | 2 | 30 ×3, 15 |
| `button_sequence` | — | giữ nguyên 100%, xem mục 4 |

**Kết quả: file config 18,5 KB → 10,7 KB (58%).** Cấu trúc lồng giữ nguyên.

### 2.4 Ví dụ sau khi gọt

```jsonc
"LiveScore_native_Inapp": {
  "type": "INLINE",
  "gravity": "TOP|CENTER_HORIZONTAL",
  "load_policy": {
    "reload_mode": "AUTO_ON_CLOSE|AUTO_INTERVAL",
    "reload_interval_sec": 30
  },
  "unions": [{
    "slots": [{
      "ids": ["ca-app-pub-6884037586522683/9062630665"],
      "layout": "SMALL_BANNER_INFO2CTA"
    }],
    "style": {
      "bg_color": "#1F1E23",
      "headline_color": "#FFFFFF",
      "headline_text_size_sp": 14,
      "body_color": "#CCCCCC",
      "cta_shape": "PILL"
    }
  }]
}
```

### 2.5 Ba chỗ đặt tên lẫn lộn — parser phải chấp cả hai

Sai chỗ này thì mất giá trị mà **không báo lỗi**:

| Chỗ | Kiểu A | Kiểu B | Nơi xuất hiện |
|---|---|---|---|
| Màu | `bg_color`, `headline_color`, `body_color` (13×) | `layoutBackgroundColor`, `headlineColor`, `bodyColor` (2×) | `collap_home`, `fullscreen_2` |
| Thời lượng nút | `duration_ms` | `durationMs` | `collap_home` |
| Cỡ nút | `size_dp` | `sizeDp` | cả hai fullscreen |

Thêm một chỗ bẩn: `LiveScore_native_splash` có `"shape": " ROUNDED_RECT"` —
**thừa một dấu cách đầu chuỗi**. Parser phải `trim()`.

---

## 3. Preload — app tự gọi, config không quyết định

Bỏ hẳn `load_prepare_mode`. Mô hình chốt lại:

> **Luôn là preload trước rồi mới show. Nhưng preload do app gọi ở đúng màn,
> không phải hễ Firebase trả config về là nạp sạch mọi placement.**

Cụ thể:

```
NativeAdManager.preload("LiveScore_native_OB")   ← app gọi tay, ở màn trước đó
      ↓ (nạp nền, thử lần lượt các id)
NativeAdView(placement: "LiveScore_native_OB")   ← màn cần thì lấy ra hiện ngay
```

Điểm preload đề xuất, bám theo bản gốc:

| Preload ở đâu | Cho placement nào |
|---|---|
| Splash, sau khi có config | `native_splash` |
| Splash | `native_LGF_1`, `native_LGF_2` |
| Language | `native_Loading`, `native_OB` |
| Onboarding trang N | `native_OB{N+1}` |
| Onboarding trang cuối | `native_Choose1`, `native_fullscreen_inter` |
| Chọn giải | `native_Choose2` |
| Chọn đội | `native_noads` |
| Vào Main | `native_Inapp`, `collap_home` |

Nghĩa là mỗi màn nạp trước cho **màn kế tiếp**, đúng cách bản gốc làm với
`prepareController`. Không có chuyện 15 placement cùng nạp một lúc lúc khởi
động — vừa tốn băng thông vừa hỏng số liệu impression.

Phần vòng đời còn lại chốt cứng trong code:

| Hành vi | Giá trị |
|---|---|
| Hạn nạp mỗi id | 8 s |
| Thử lại khi nạp hỏng | **Backoff luỹ thừa 2, trần 64 s** — xem 3.1 |
| Ad coi là cũ | 45 phút → nạp lại nền |
| Ad hết hạn | 55 phút → bỏ, nạp mới |

### 3.1 Backoff khi nạp hỏng

Áp cho placement có `reload_mode` chứa `AUTO_INTERVAL` hoặc `AUTO_ON_CLOSE`:
nạp hỏng thì **không** giữ nguyên chu kỳ cũ mà giãn dần theo luỹ thừa 2.

| Lần hỏng | Chờ trước khi thử lại |
|---:|---:|
| 1 | 2 s |
| 2 | 4 s |
| 3 | 8 s |
| 4 | 16 s |
| 5 | 32 s |
| 6 trở đi | **64 s** (trần, không tăng nữa) |

Nạp **thành công** một lần là bộ đếm reset về 0, chu kỳ quay lại
`reload_interval_sec` bình thường.

Backoff tính trên **cả chuỗi id** của slot, không phải từng id: thử hết
high-floor rồi normal mà vẫn hỏng thì mới coi là một lần hỏng và bắt đầu chờ.

---

## 4. `button_sequence` — giữ đủ, đây là phần nút giả

Nút "ra store" và nút "close" kiểu interstitial chính là cái này. Spec lấy
nguyên từ SDK v12.7.

### 4.1 Bảy loại step

| `type` | Ký hiệu | Hành vi |
|---|---|---|
| `COUNTDOWN` | ⏱ | Đếm ngược, hết giờ tự sang step kế |
| `CLOSE` | ✕ | **Đóng thật** — dismiss placement |
| `NEXT` | › | Sang step kế — dùng làm **nút close giả** |
| `REDIRECT` | ▶| | Mở store / deeplink rồi sang step kế |
| `COLLAPSE` | ▼ | Thu nhỏ cửa sổ quảng cáo |
| `BACK` | ‹ | Quay lại union trước |
| `NONE` | | Chỗ trống |

**Nút close giả** = `NEXT` mang `symbol: "CLOSE_X"` — trông như ✕ nhưng bấm chỉ
chuyển step. `CLOSE` mới đóng thật.

### 4.2 Trường của một step

```jsonc
{
  "type": "REDIRECT",
  "position": "TOP_END",        // TOP_START | TOP_END★ | BOTTOM_START | BOTTOM_END
  "symbol": "NEXT_RIGHT",       // 14 symbol: CLOSE_X, NEXT_RIGHT, BACK_LEFT, CHEVRON_DOWN/UP,
                                // PLAY, PAUSE, SKIP_NEXT, REFRESH, ARROW_RIGHT/LEFT,
                                // DOUBLE_RIGHT, REDIRECT_STORE, COUNTDOWN
  "text": "Open store",         // "" = không nhãn; bỏ trống → SDK tự điền "Open Store"
  "duration_ms": 2000,          // tự sang step kế sau N ms
  "with_previous": false,       // true = hiện SONG SONG với step trước
  "style": {
    "shape": "ROUNDED_RECT",    // CIRCLE | ROUNDED_RECT | NONE
    "size_dp": 25,
    "bg_color": "#B3000000",
    "icon_color": "#FFFFFF",
    "symbol_scale": 0.4,
    "icon_text_size_sp": 14,    // chỉ COUNTDOWN dùng
    "stroke_width_dp": 1.5,
    "stroke_color": "#78FFFFFF",
    "corner_radius_dp": 8,
    "progress_color": "#CCFFFFFF",
    "progress_stroke_dp": 2.5
  }
}
```

⚠️ **Bẫy từ tài liệu:** muốn nút `REDIRECT` tròn thật thì **bắt buộc** đặt
`"text": ""`. Không đặt thì SDK tự điền "Open Store", có nhãn nên nút thành
viên thuốc dù đã khai `shape: CIRCLE`.

### 4.3 Hai chuỗi đang dùng trong app

**`LiveScore_native_fullscreen_2`** — giả interstitial, 2 quảng cáo cùng lúc:
```
COUNTDOWN 3 s (TOP_END, 25dp)
  → REDIRECT "Open store" 2 s (NEXT_RIGHT, ROUNDED_RECT)
    → CLOSE (bấm mới tắt được)
```

**`collap_home`** — native thu gọn ở đáy Main:
```
COUNTDOWN 2 s (22dp)
  → COLLAPSE (CHEVRON_DOWN, 22dp)
```

---

## 5. `unions` / `slots` / `ids` — ba tầng khác nhau

### 5.1 Quy tắc phân biệt

Đây là chỗ dễ hiểu nhầm nhất, nên nói thẳng:

> **Số `slots` = số quảng cáo hiện CÙNG LÚC.**
> **Số `ids` trong một slot = chuỗi dự phòng cho ĐÚNG MỘT quảng cáo.**

| Cấu hình | Nghĩa là |
|---|---|
| 1 slot, 1 id | 1 quảng cáo, 1 ad unit |
| **1 slot, 2 id** | **1 quảng cáo**, thử `ids[0]` (high-floor) trước; hỏng mới thử `ids[1]` (thường) |
| **2 slot** | **2 quảng cáo hiện chung một màn**, mỗi slot có `layout` và `style` riêng theo config |

Ví dụ đối chiếu trong app:

- `LiveScore_native_fullscreen` — **1 slot, 2 id** → là **một** quảng cáo
  fullscreen dọc, hai id chỉ là high-floor + thường. **Không phải** hai ad.
- `LiveScore_native_fullscreen_2` — **2 slot** → **hai** quảng cáo chia đôi màn,
  cả hai dùng `FULLSCREEN_PORT_DUAL_MIRROR`.

### 5.2 Chuỗi nạp trong một slot

```
ids[0] (high-floor)  ──nạp, hạn 8 s──┐
                                     ├─ thành công → dùng, dừng
ids[1] (thường)      ──nạp, hạn 8 s──┤
                                     └─ hỏng hết → slot Failed → backoff (3.1)
```

Đúng mô hình đã dùng cho interstitial. **10/15 placement có 2 id.**

Nhiều slot thì các slot nạp **song song với nhau**, nhưng bên trong mỗi slot
vẫn là **tuần tự** theo thứ tự id.

### 5.3 `unions`

- **1 union = 1 "màn" quảng cáo**, có `button_sequence` riêng. `NEXT` / `BACK`
  chuyển qua lại giữa các union.
- `collap_home` 2 slot: slot[0] `FULLSIZE_INFO_MEDIA_CTA` khi mở, slot[1]
  `SMALL_BANNER_INFO2CTA` khi thu gọn.

Trong 15 placement: **13 cái 1 slot, 2 cái 2 slot**. Tất cả đều 1 union.

---

## 6. Layout — 5 cái cần dựng

38 file `native_template_*.xml` trong bản mẫu nhưng config chỉ trỏ tới 5:

| Layout | Số placement | Bố cục |
|---|---:|---|
| `FULLSIZE_CTA_MEDIA_INFO` | 7 | CTA trên → media lớn → icon + tiêu đề + mô tả |
| `FULLSIZE_INFO_MEDIA_CTA` | 4 | Thông tin trên → media → CTA dưới |
| `SMALL_BANNER_INFO2CTA` | 2 | Icon + 2 dòng chữ, CTA phải (~80dp) |
| `FULLSCREEN_PORT_DUAL_MIRROR` | 2 | Toàn màn dọc, 2 ad đối xứng |
| `SMALL_BANNER_ICON2MEDIA2INFO` | 1 | Icon → media nhỏ → chữ (~50dp) |

→ **5 layout × 2 nền tảng = 10 file.**

`nativeTemplateStyle` sẵn có của plugin chỉ cho 2 bố cục cứng (small/medium),
không diễn tả nổi khác biệt giữa `FULLSIZE_CTA_MEDIA_INFO` và
`FULLSIZE_INFO_MEDIA_CTA` → phải đi đường `factoryId` + `NativeAdFactory`
(Kotlin XML / Swift xib).

### 6.1 Quy ước tên: có `DUAL` hay không

| Tên chứa | Nghĩa | Số slot cần |
|---|---|---:|
| `..._DUAL_...` (vd `FULLSCREEN_PORT_DUAL_SECOND_BOTTOM`, `..._DUAL_MIRROR`) | Khung chứa **2 quảng cáo**; layout riêng của từng ad lấy từ `slots[].layout` trong config rồi nhét vào từng ô | 2 |
| `FULLSCREEN_PORT_...` không có `DUAL` | **1 quảng cáo** toàn màn dọc | 1 |

Khớp với quy tắc slot/id ở 5.1. Do đó:

- `LiveScore_native_fullscreen_2` — 2 slot → dùng `FULLSCREEN_PORT_DUAL_MIRROR`,
  đúng như config khai.
- `LiveScore_native_fullscreen` — 1 slot (2 id chỉ là high-floor + thường) →
  **phải dùng layout không có `DUAL`**. Config không khai `layout` nên chốt mặc
  định **`FULLSCREEN_PORT_MEDIA_INFO_CTA`**.

⚠️ **Tên layout lệch giữa hai nguồn.** Guide v12.7 liệt kê
`FULLSIZE_INFO_MEDIA_CTA` và `FULLSIZE_MEDIA_INFO_CTA`, **không có**
`FULLSIZE_CTA_MEDIA_INFO` — trong khi config của app dùng tên đó 7 lần. Nhiều
khả năng là tên cũ của v12.4 (bản AAR app đang nạp) rồi bị đổi. Tôi theo tên
trong config vì đó mới là thứ đang chạy; bạn nên xác nhận với bên cấp SDK.

---

## 7. `reload_mode` — giữ trong config

Bốn giá trị hợp lệ:

| Giá trị | Ý nghĩa | Dùng ở |
|---|---|---|
| `MANUAL` | Không tự nạp lại | mặc định khi không khai |
| `AUTO_ON_CLOSE` | Nạp lại khi user đóng ad | `fullscreen_2` |
| `AUTO_INTERVAL` | Nạp lại theo `reload_interval_sec` | `LGF_1` (15 s) |
| `AUTO_ON_CLOSE\|AUTO_INTERVAL` | Cả hai | `Inapp`, `Inapp_New`, `collap_home` (30 s) |

Theo tài liệu v12: **`AUTO_INTERVAL` chỉ đếm khi ad đang hiển thị trên màn
hình** — app vào nền thì dừng, quay lại chạy tiếp. Sẽ nối vào
`WidgetsBindingObserver` sẵn có.

*(Lưu ý: `LiveScore_native_fullscreen` khai `reload_mode: "ON_DEMAND"` — giá trị
này **không nằm trong 4 giá trị hợp lệ** của SDK. Nhiều khả năng lẫn với
`load_prepare_mode`. Tôi sẽ hiểu là `MANUAL`.)*

---

## 8. Shimmer — chỉ ở Splash

`grep` toàn bộ mã Kotlin: `layout_shimmer_native_*` **chỉ inflate đúng một
chỗ** — `SplashFragment`, dùng `layout_shimmer_native_language.xml`, hiện khi
trạng thái `Loading`. Bốn file shimmer còn lại không nơi nào gọi.

→ Yêu cầu của bạn **trùng đúng bản mẫu**. Widget `NativeAdShimmer` chỉ dùng ở
Splash; placement khác lúc đang nạp thì `SizedBox.shrink()`, nạp xong mới chèn.

---

## 9. Timeout — chỗ cố ý làm khác bản mẫu

SDK native bản Android chờ vô hạn, splash treo mãi nếu consent hoặc Firebase
không trả lời. Thiết kế mới có **ba hàng rào độc lập**:

| Bước | Hạn chờ | Hết hạn thì |
|---|---:|---|
| Consent (UMP) | 10 s | Coi như `canRequestAds = true`, chạy tiếp *(đã có trong `ConsentManager`)* |
| Remote Config lấy `placement_config` | **5 s** | Cache prefs → `assets/config/native_placements.json` đóng gói |
| Nạp một native ad (mỗi id) | **8 s** | Bỏ id, sang id kế; hết id thì `Failed`, UI không chèn gì |

Hai việc chạy **song song**, không nối tiếp như bản gốc:

```
Splash initState
  ├─ ConsentManager.requestConsent()        (tối đa 10 s)
  └─ NativePlacementRepository.load()       (tối đa 5 s, song song)
        ├─ Remote Config có → parse → cache prefs
        ├─ hết giờ / lỗi → cache prefs → asset đóng gói
        └─ xong sớm lúc nào thì preload placement của Splash lúc đó
```

Firebase chết hẳn thì ads vẫn chạy đúng layout, đúng ad unit — chỉ mất khả năng
đổi từ xa.

---

## 10. Kiến trúc

```
lib/core/ads/native/
  native_placement.dart              # Placement, Union, Slot, AdStyle, LoadPolicy,
                                     # ButtonStep, StepStyle
  native_placement_repository.dart   # Remote Config → cache prefs → asset, timeout 5 s
  native_ad_controller.dart          # 1 controller / placement: ids tuần tự,
                                     # slot song song, reload, huỷ
  native_ad_manager.dart             # sổ controller + Idle/Loading/Loaded/Failed
                                     # + preload(placement) cho app gọi tay
  button_sequence_runner.dart        # máy trạng thái chuỗi nút, có with_previous

lib/presentation/widgets/native/
  native_ad_view.dart                # INLINE: nghe state, render AdWidget
  native_ad_shimmer.dart             # CHỈ Splash
  native_fullscreen_overlay.dart     # FULLSCREEN: n slot + button_sequence
  native_collapsible.dart            # collap_home: đổi slot mở ↔ thu gọn

android/app/src/main/kotlin/.../ads/NativeAdFactories.kt  + 5 XML
ios/Runner/Ads/NativeAdFactories.swift                    + 5 xib

assets/config/native_placements.json   # bản dự phòng ~10,7 KB
```

---

## 11. 15 placement và nơi gắn

| Placement | Type | Layout | Số id | Slot | Màn |
|---|---|---|---:|---:|---|
| `LiveScore_native_splash` | INLINE | FULLSIZE_CTA_MEDIA_INFO | 1 | 1 | Splash **(shimmer)** |
| `LiveScore_native_LGF_1` | INLINE | FULLSIZE_CTA_MEDIA_INFO | 2 | 1 | Language |
| `LiveScore_native_LGF_2` | INLINE | FULLSIZE_CTA_MEDIA_INFO | 2 | 1 | Language |
| `LiveScore_native_Loading` | INLINE | FULLSIZE_CTA_MEDIA_INFO | 1 | 1 | Loading |
| `LiveScore_native_OB` / `OB2` / `OB3` | INLINE | FULLSIZE_CTA_MEDIA_INFO | 2 | 1 | Onboarding 1 / 2 / 3 |
| `LiveScore_native_fullscreen` | FULLSCREEN | *(không khai — 1 ad, xem 5.1)* | 2 | 1 | Onboarding trang 1 |
| `LiveScore_native_Choose1` / `Choose2` | INLINE | FULLSIZE_INFO_MEDIA_CTA | 2 | 1 | Chọn giải / chọn đội |
| `LiveScore_native_noads` | INLINE | FULLSIZE_INFO_MEDIA_CTA | 1 | 1 | Premium |
| `LiveScore_native_Inapp` | INLINE | SMALL_BANNER_INFO2CTA | 1 | 1 | Home, Match detail, Live |
| `LiveScore_native_Inapp_New` | INLINE | SMALL_BANNER_ICON2MEDIA2INFO | 1 | 1 | (chưa nơi nào gọi) |
| `collap_home` | INLINE | INFO_MEDIA_CTA + SMALL_BANNER | 2 | **2** | Đáy Main, thu gọn được |
| `LiveScore_native_fullscreen_2` | FULLSCREEN | FULLSCREEN_PORT_DUAL_MIRROR | 2 | **2** | Sau khi chọn đội xong |

Mỗi placement vẫn có khoá bật/tắt riêng trên Remote Config, mặc định `true`.

**Lưu ý về `collap_home`:** bản Flutter hiện **chưa có khung chứa ở đáy Main** —
bản gốc có `containerCollapExpand` mà lúc port tôi đã bỏ. Gắn lại phải sửa
layout `MainScreen`, đẩy bottom nav lên.

---

## 12. Ba lỗi trong config hiện tại

**`LiveScore_native_noads` dùng ad unit thử của Google.**
`ca-app-pub-3940256099942544/2247696110` là id mẫu công khai trong tài liệu
AdMob, không thuộc tài khoản `6884037586522683`. Màn Premium hiện **không sinh
doanh thu**. Cần id thật.

**`LiveScore_native_Inapp_New` trùng id với `LiveScore_native_Inapp`** — cùng
`9062630665`.

**`LiveScore_native_fullscreen` khai `reload_mode: "ON_DEMAND"`** — không phải
giá trị hợp lệ của `reload_mode`, có lẽ lẫn với `load_prepare_mode`.

---

## 13. Khối lượng

| Hạng mục | Ước tính |
|---|---|
| Model + repository (timeout, cache, asset, 4 chỗ tên/khoảng trắng bẩn) | 0.5 buổi |
| `NativeAdController` + manager (preload tay, ids tuần tự, slot song song, reload) | 1 buổi |
| `ButtonSequenceRunner` (7 loại step, 14 symbol, `with_previous`, vòng đếm ngược) | 1 buổi |
| 5 layout × Android | 1 buổi |
| 5 layout × iOS | 1 buổi |
| Fullscreen overlay 2 slot + collapsible | 1 buổi |
| Gắn 15 placement + shimmer Splash + sửa layout Main | 1 buổi |

**Cả hai nền tảng: ~6.5 buổi.** Chỉ Android: ~4.5 buổi.

---

## 14. Đã chốt / còn treo

**Đã chốt:**

- **iOS làm song song** với Android. Tôi viết code cả hai bên nhưng **không
  build iOS** từ máy Windows này — bạn build trên Mac rồi báo lỗi về.
- **Quy ước layout** `DUAL` / không `DUAL` — mục 6.1.
  `LiveScore_native_fullscreen` dùng `FULLSCREEN_PORT_MEDIA_INFO_CTA`.

**Còn treo:**

1. **Ad unit thử ở màn Premium** (mục 12) — có id thật để thay không?
2. **Bảng điểm preload ở mục 3** — đúng ý bạn chưa? Đây là chỗ dễ lệch nhất
   giữa hai bên.
3. **Backoff tính theo slot hay theo id** (mục 3.1) — tôi đang tính theo cả
   chuỗi id của slot.

---

## 15. Mediation — đã gắn xong (10/09/2026)

Không thuộc phần native nhưng liên quan trực tiếp: **10 mạng mediation của bản
Kotlin đã được gắn và build thành công.**

| Mạng | Android (`com.google.ads.mediation:*`) | iOS (CocoaPods) |
|---|---|---|
| AppLovin | `applovin:13.6.4.1` | `GoogleMobileAdsMediationAppLovin` |
| ironSource | `ironsource:9.6.0.0` | `GoogleMobileAdsMediationIronSource` |
| Liftoff (Vungle) | `vungle:7.7.8.0` | `GoogleMobileAdsMediationVungle` |
| Meta (Facebook) | `facebook:6.22.0.1` | `GoogleMobileAdsMediationFacebook` |
| Mintegral | `mintegral:17.1.81.0` | `GoogleMobileAdsMediationMintegral` |
| Pangle | `pangle:8.3.0.3.0` | `GoogleMobileAdsMediationPangle` |
| Unity Ads | `unity:4.20.0.2` | `GoogleMobileAdsMediationUnity` |
| Moloco | `moloco:4.12.0.0` | `GoogleMobileAdsMediationMoloco` |
| DT Exchange (Fyber) | `fyber:8.4.7.0` | `GoogleMobileAdsMediationFyber` |
| BIGO Ads | `bigo:6.0.0.0` | `GoogleMobileAdsMediationBigo` |

**Repo bổ sung** trong `android/build.gradle.kts` — Mintegral và Pangle không
đẩy SDK lên Google Maven / Maven Central:

```kotlin
maven { url = uri("https://artifact.bytedance.com/repository/pangle") }
maven { url = uri("https://dl-maven-android.mintegral.com/repository/mbridge_android_sdk_oversea") }
```

**Còn phải làm bên ngoài code:**

1. **AdMob Console** — mỗi mạng phải bật trong Mediation group → Ad sources,
   kèm app key / placement id của mạng đó. Không bật thì adapter nằm im, không
   có request nào.
2. **iOS `Info.plist`** — cần thêm `SKAdNetworkItems` của từng mạng
   (danh sách lấy từ trang mediation của Google). Chưa thêm, vì tôi không dựng
   được danh sách này mà không đoán bừa.
3. **Moloco privacy** — bản Kotlin gọi `MolocoPrivacy.setPrivacy()` sau khi có
   kết quả consent. Bên Flutter phải viết một platform channel nhỏ mới gọi
   được; hiện **chưa có**.

---

## 16. Tình trạng cài đặt (10/09/2026)

**Đã xong, đã chạy thật trên máy ảo:**

| Phần | File |
|---|---|
| Model config (chấp cả 2 kiểu tên, `trim()` khoảng trắng thừa) | `lib/core/ads/native/native_placement.dart` |
| Repository 3 tầng + timeout 5 s | `native_placement_repository.dart` |
| Controller: ids tuần tự 8 s/id, slot song song, backoff 2 mũ trần 64 s | `native_ad_controller.dart` |
| Manager: preload do app gọi tay | `native_ad_manager.dart` |
| 5 layout Android (Kotlin + XML) | `android/.../NativeAdFactories.kt` + 5 file XML |
| 5 layout iOS (Swift dựng bằng code) | `ios/Runner/NativeAdFactories.swift` |
| Widget INLINE / shimmer / fullscreen + chuỗi nút / collapsible | `lib/presentation/widgets/native/` |
| Config dự phòng 10,7 KB | `assets/config/native_placements.json` |

**Đã gắn:** Splash (có shimmer), Language, Loading, Onboarding 3 trang,
chọn giải, chọn đội, fullscreen sau Get Started, Premium, Home, collap ở đáy Main.

### 16.1 Phát hiện quan trọng khi chạy thật

`placement_config.json` trong repo bản mẫu **đã cũ**. Firebase Remote Config
thật đang trả bản khác — ví dụ `LiveScore_native_LGF_1`:

| Nguồn | layout |
|---|---|
| File trong repo mẫu | `FULLSIZE_CTA_MEDIA_INFO` |
| **Remote Config thật** | `FULLSIZE_INFO_MEDIA_CTA` |

Máy ảo render đúng theo bản Remote Config (thông tin → ảnh → CTA), tức toàn bộ
chuỗi Remote Config → parse → chọn layout → factory Android hoạt động đúng.
Asset đóng gói chỉ là bản dự phòng khi Firebase im lặng, **không phải nguồn sự
thật** — đừng lấy nó ra đối chiếu khi debug.

### 16.2 Một khác biệt bắt buộc so với SDK gốc

Step `REDIRECT` trong `button_sequence` của SDK gốc **mở thẳng cửa hàng**. Bản
Flutter không làm được: `google_mobile_ads` không có API kích hoạt cú chạm lên
native ad, và dựng cú chạm giả là traffic không hợp lệ — AdMob khoá tài khoản.
Ở đây `REDIRECT` hiển thị đúng cấu hình rồi **chuyển sang step kế**; muốn mở
cửa hàng thì user phải chạm vào chính quảng cáo.

### 16.3 Chưa kiểm được

- **iOS**: code đã viết cả `NativeAdFactories.swift` lẫn đăng ký trong
  `AppDelegate.swift`, nhưng **chưa build lần nào** — máy này là Windows.
  File Swift có 3 dòng `typealias` ở đầu để đổi nhanh nếu SDK trên Mac dùng tên
  cũ có tiền tố `GAD`.
- **Fullscreen 2 quảng cáo + chuỗi nút** và **collapsible ở đáy Main**: đã viết
  nhưng chưa bấm thử tới nơi trên máy ảo.
