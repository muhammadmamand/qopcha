import { LottieLight } from 'lottie-react'
import packing from '../assets/lottie/order_packed.json' with { type: 'json' }

const animation = packing as object

export function PreparingBanner({ shopName }: { shopName?: string }) {
  const shop = (shopName || '').trim()
  return (
    <div className="prep-banner" dir="rtl">
      <LottieLight
        src={animation}
        className="prep-lottie"
        autoplay
        loop
        aria-hidden
      />
      <div className="prep-copy">
        <p>
          ئامادە دەکرێت
          <span className="prep-dots">
            <span />
            <span />
            <span />
          </span>
        </p>
        <p>
          {shop
            ? `دووکانی ${shop} جلەکە دەپێچێتەوە و ئامادەی دەکات`
            : 'دووکان جلەکە دەپێچێتەوە و ئامادەی دەکات'}
        </p>
      </div>
    </div>
  )
}

export function PreparingItemMark() {
  return (
    <LottieLight
      src={animation}
      className="prep-item-lottie"
      autoplay
      loop
      aria-hidden
    />
  )
}
