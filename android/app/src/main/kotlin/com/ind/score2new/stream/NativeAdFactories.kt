package com.ind.score2new.stream

import android.content.Context
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.util.TypedValue
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin
import io.flutter.plugins.googlemobileads.NativeAdFactory

/**
 * Dựng view cho native ad. Mỗi layout trong `placement_config` ứng với một
 * factoryId đăng ký ở đây — xem `docs/ADS_NATIVE_DESIGN.md` mục 6.
 *
 * Style đến từ Dart qua `customOptions`, đã gọt còn 5 khoá:
 * `bg_color`, `headline_color`, `body_color`, `headline_text_size_sp`,
 * `cta_shape`. Các giá trị màu là Int ARGB.
 */
class LiveScoreNativeAdFactory(
    private val context: Context,
    private val layoutRes: Int,
    /** Kênh báo chiều cao thật lên Dart (`NativeAdHeights`). */
    private val heightChannel: MethodChannel?,
    /** Ad inline cao đúng bằng nội dung; fullscreen thì lấp cả khung. */
    private val wrapsContent: Boolean,
) : NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?,
    ): NativeAdView {
        val adView = LayoutInflater.from(context)
            .inflate(layoutRes, null) as NativeAdView

        val headline = adView.findViewById<TextView>(R.id.ad_headline)
        val body = adView.findViewById<TextView>(R.id.ad_body)
        val cta = adView.findViewById<Button>(R.id.ad_call_to_action)
        val icon = adView.findViewById<ImageView>(R.id.ad_icon)
        val media = adView.findViewById<com.google.android.gms.ads.nativead.MediaView>(
            R.id.ad_media
        )

        adView.headlineView = headline
        adView.bodyView = body
        adView.callToActionView = cta
        adView.iconView = icon
        adView.mediaView = media

        headline?.text = nativeAd.headline

        if (nativeAd.body == null) {
            body?.visibility = View.INVISIBLE
        } else {
            body?.visibility = View.VISIBLE
            body?.text = nativeAd.body
        }

        if (nativeAd.callToAction == null) {
            cta?.visibility = View.INVISIBLE
        } else {
            cta?.visibility = View.VISIBLE
            cta?.text = nativeAd.callToAction
        }

        val iconAsset = nativeAd.icon
        if (iconAsset == null) {
            icon?.visibility = View.GONE
        } else {
            icon?.setImageDrawable(iconAsset.drawable)
            icon?.visibility = View.VISIBLE
        }

        media?.mediaContent = nativeAd.mediaContent

        applyStyle(adView, headline, body, cta, customOptions)

        adView.setNativeAd(nativeAd)
        reportHeight(adView, customOptions)
        return adView
    }

    /**
     * Đo chiều cao nội dung rồi báo lên Dart để ô Flutter co đúng bằng nó.
     *
     * Plugin gọi factory **trước** khi báo `onAdLoaded`, nên Dart có chiều
     * cao trước khi ad hiện. Ad luôn full chiều rộng nên đo theo chiều rộng
     * màn hình; khung thật khác (xoay màn, tablet…) thì đo lại khi view đổi
     * chiều rộng.
     */
    private fun reportHeight(adView: NativeAdView, customOptions: MutableMap<String, Any>?) {
        val channel = heightChannel ?: return
        val slotId = customOptions?.get("slot_id") as? String ?: return
        if (!wrapsContent) return

        var measuredWidth = context.resources.displayMetrics.widthPixels
        sendHeight(channel, adView, slotId, measuredWidth)
        adView.addOnLayoutChangeListener { view, left, _, right, _, _, _, _, _ ->
            val width = right - left
            if (width > 0 && width != measuredWidth) {
                measuredWidth = width
                view.post { sendHeight(channel, view, slotId, width) }
            }
        }
    }

    private fun sendHeight(channel: MethodChannel, view: View, slotId: String, widthPx: Int) {
        view.measure(
            View.MeasureSpec.makeMeasureSpec(widthPx, View.MeasureSpec.EXACTLY),
            View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED),
        )
        val heightDp = view.measuredHeight / context.resources.displayMetrics.density
        channel.invokeMethod(
            "height",
            mapOf("slot_id" to slotId, "height" to heightDp.toDouble()),
        )
        // measure() vừa ghi đè kích thước đo; xin layout lại theo khung thật.
        if (view.isAttachedToWindow) view.requestLayout()
    }

    private fun applyStyle(
        adView: NativeAdView,
        headline: TextView?,
        body: TextView?,
        cta: Button?,
        options: MutableMap<String, Any>?,
    ) {
        if (options == null) return

        (options["bg_color"] as? Number)?.let {
            adView.setBackgroundColor(it.toInt())
        }
        (options["headline_color"] as? Number)?.let {
            headline?.setTextColor(it.toInt())
        }
        (options["body_color"] as? Number)?.let {
            body?.setTextColor(it.toInt())
        }
        (options["headline_text_size_sp"] as? Number)?.let {
            headline?.setTextSize(TypedValue.COMPLEX_UNIT_SP, it.toFloat())
        }

        // Bo góc CTA suy từ shape: PILL = 24dp, ROUNDED_RECT = 10dp.
        // Màu nền/chữ của CTA cố định vì config chỉ có một giá trị duy nhất.
        val shape = (options["cta_shape"] as? String)?.trim()?.uppercase()
        val radiusDp = if (shape == "PILL") 24f else 10f
        cta?.background = GradientDrawable().apply {
            cornerRadius = radiusDp * context.resources.displayMetrics.density
            setColor(CTA_BG_COLOR)
        }
        cta?.setTextColor(Color.WHITE)
    }

    companion object {
        /** `cta_config.bg_color` trong config chỉ có đúng một giá trị. */
        private val CTA_BG_COLOR = Color.parseColor("#FFA600")

        /** factoryId phải khớp `NativeLayouts._factoryIds` bên Dart. */
        private val FACTORIES = mapOf(
            "ctaMediaInfo" to R.layout.native_cta_media_info,
            "infoMediaCta" to R.layout.native_info_media_cta,
            "mediaInfoCta" to R.layout.native_media_info_cta,
            "bannerInfoCta" to R.layout.native_banner_info_cta,
            "bannerIconMediaInfo" to R.layout.native_banner_icon_media_info,
            "fullscreenMediaInfoCta" to R.layout.native_fullscreen_media_info_cta,
        )

        /** Phải khớp `NativeAdHeights._channel` bên Dart. */
        private const val HEIGHT_CHANNEL = "live_score/native_ad_height"

        fun registerAll(engine: io.flutter.embedding.engine.FlutterEngine, context: Context) {
            val heightChannel = MethodChannel(engine.dartExecutor.binaryMessenger, HEIGHT_CHANNEL)
            FACTORIES.forEach { (id, layoutRes) ->
                GoogleMobileAdsPlugin.registerNativeAdFactory(
                    engine,
                    id,
                    LiveScoreNativeAdFactory(
                        context,
                        layoutRes,
                        heightChannel,
                        wrapsContent = id != "fullscreenMediaInfoCta",
                    ),
                )
            }
        }

        fun unregisterAll(engine: io.flutter.embedding.engine.FlutterEngine) {
            FACTORIES.keys.forEach {
                GoogleMobileAdsPlugin.unregisterNativeAdFactory(engine, it)
            }
        }
    }
}
