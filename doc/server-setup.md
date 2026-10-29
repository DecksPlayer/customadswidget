# Ad Server Setup

This guide explains what the client has to publish so their banners show up in the Flutter web app.

In short: **an HTTPS URL that returns a JSON file**. The app downloads it, picks the banner to show in each spot on the page, and loads the images from the URLs in the JSON.

```
https://cdn.client.com/ads/ads.json   ← JSON with the list of banners
https://cdn.client.com/ads/banners/…  ← banner images
```

It can be a static file (S3, a CDN, a folder on your hosting) or an API endpoint that generates the JSON. It makes no difference to the app.

---

## 1. JSON format

```json
{
  "version": 1,
  "placements": {
    "home_top": {
      "rotationSeconds": 30,
      "ads": [
        {
          "id": "summer-2026",
          "alt": "Summer sale: 50% off everything",
          "targetUrl": "https://client.com/deals",
          "startAt": "2026-12-01T00:00:00-03:00",
          "endAt": "2027-01-31T23:59:59-03:00",
          "assets": [
            { "url": "banners/summer-728x90.jpg", "width": 728, "height": 90 },
            { "url": "banners/summer-320x50.jpg", "width": 320, "height": 50 }
          ]
        }
      ]
    },
    "sidebar": {
      "ads": [
        {
          "id": "flutter-course",
          "alt": "Flutter Web course",
          "targetUrl": "https://client.com/course",
          "assets": [
            { "url": "banners/course-300x250.png", "width": 300, "height": 250 }
          ]
        }
      ]
    }
  }
}
```

### `placements`

Each key (`home_top`, `sidebar`, …) is a **spot on the page**. The names are agreed with the web team: in the app, each spot is an `AdSlot(placement: 'home_top')`.

If a placement isn't in the JSON, or has no active banners, that spot isn't shown (it leaves no gap).

| Field | Type | Required | Description |
|---|---|---|---|
| `ads` | list | yes | Banners for this spot. |
| `rotationSeconds` | number | no (30) | When several banners are active, how many seconds between them. **Minimum 30**: a lower value is raised to 30. `0` shows only the first one. |
| `dismissible` | bool | no (false) | Shows a close button so the user can hide the banner. |
| `format` | text | no (`creative`) | `creative` = your own image (the usual case). See [Template banners](#template-banners). |

### Each banner (`ads[]`)

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | text | yes | Unique identifier. It's what analytics receives for impressions and clicks. |
| `assets` | list | yes | One image per size (see below). |
| `alt` | text | recommended | Alt text for accessibility and screen readers. |
| `targetUrl` | URL | no | Where a click leads. Opens in a new tab. Without this field, the banner doesn't navigate. |
| `startAt` / `endAt` | ISO 8601 date | no | Schedule. Outside that range the banner isn't shown. Include the time zone (`-03:00` or `Z`). |
| `badge` | text | no ("Ad") | Label shown on the banner, for example `"Sponsored"`. The text can be changed but not removed: with `null` or empty, "Ad" is shown. |

If a banner is malformed (for example, it has no `id`), only that banner is dropped and the rest keep showing.

### Images (`assets[]`)

| Field | Type | Description |
|---|---|---|
| `url` | URL | Absolute (`https://…`) or relative to the JSON URL. |
| `width` / `height` | number | The size it **is displayed at**, in CSS pixels. |

How the image is picked: the app uses **the widest one that fits** the available space and follows the [non-intrusive ads rules](#non-intrusive-ads-rules). In the `home_top` example:

- on desktop, the 728x90 is shown;
- on a 390px-wide phone, the 320x50 is shown;
- if none fits, the smallest one is shown, scaled down proportionally.

That's why it's best to send at least one desktop version and one mobile version.

**Image recommendations:**

- **Formats:** **static** JPG, PNG or WebP. Animated images (animated GIF, WebP or PNG) are shown frozen on their first frame, so that frame has to work as a complete banner.
- **Retina screens:** export the file at twice the declared size. For example, a 1456x180 file declared as `"width": 728, "height": 90`.
- **Weight:** ideally under 150 KB per image.
- **Relative paths:** resolved against the JSON URL. If the JSON is at `https://cdn.client.com/ads/ads.json`, the path `banners/x.jpg` is read from `https://cdn.client.com/ads/banners/x.jpg`.
- **Image changes:** rename the file (for example `summer-v2.jpg`) instead of overwriting it, so nobody keeps seeing the old cached version.

**Common sizes:**

| Use | Desktop | Mobile |
|---|---|---|
| Top banner | 728x90 | 320x50 |
| Side / in-content | 300x250 | 300x250 |
| Vertical column | 160x600 | — (not shown on mobile; also send a 320x50) |
| Hero | 1200x250 | 600x200 |

### Non-intrusive ads rules

The app only shows non-intrusive ads, following the [Better Ads Standards](https://www.betterads.org/standards/) and the [Acceptable Ads](https://acceptableads.com/standard/) criteria. These rules can't be turned off, so design banners with them in mind:

| Rule | What the app does |
|---|---|
| **Visible label** | Every banner shows "Ad" (or the `badge` text) in the top-left corner. Keep that corner free of important text. |
| **Maximum height: 30% of the screen** | A landscape or rectangular banner taller than 30% of the screen is scaled down proportionally. For example, on a 900px-tall screen the maximum is 270px, and on a 700px phone it's 210px. |
| **Vertical banners only as side ads** | Banners taller than wide (such as 160x600) only show on screens at least 1024px wide, and at most 350px wide. On narrow screens another asset of the same banner is used, or the banner isn't shown. |
| **No animations** | Animated images are frozen on their first frame. |
| **Slow rotation** | At least 30 seconds between banners in the same spot. |
| **No invasive formats** | There are no pop-ups, interstitials, sticky banners covering content, video or sound. |

The web team can tune the thresholds (for example, lower the maximum height to 25%), but not turn the rules off.

### Template banners

If, instead of a finished image, you want the app to build the banner from text, a button and a photo, use `"format": "card"` (or `leaderboard`, `mediumRectangle`, `skyscraper`, `hero`) and these fields:

```json
"blog_card": {
  "format": "card",
  "ads": [
    {
      "id": "blog-coffee",
      "title": "Specialty coffee at your door",
      "description": "Subscribe and get freshly roasted beans.",
      "imageUrl": "banners/coffee.jpg",
      "ctaLabel": "Subscribe",
      "targetUrl": "https://client.com/coffee",
      "sponsor": "South Roasters"
    }
  ]
}
```

---

## 2. Required HTTP headers

The Flutter web app runs on a different domain than the JSON, so the browser **blocks the download if the server doesn't allow CORS**. This is the most common mistake.

Headers the JSON URL has to return:

```
Content-Type: application/json; charset=utf-8
Access-Control-Allow-Origin: https://www.flutter-site.com
Cache-Control: public, max-age=300
```

| Header | Why |
|---|---|
| `Access-Control-Allow-Origin` | **Required.** The domain the Flutter web app runs on. `*` is fine if the JSON is public. For several domains, the server has to return the origin that made the request. |
| `Content-Type` | JSON in UTF-8, so accented characters display correctly. |
| `Cache-Control` | How long the browser reuses the JSON. With 5 minutes (`300`), a change takes at most that long to show up. The app also requests it again periodically. |

**Images:** they also need `Access-Control-Allow-Origin`. The app decodes each image to freeze animations, and the browser only allows that with CORS. Without that header, a gray rectangle is shown instead of the banner. If the images are on another domain or CDN, set up CORS there too.

**HTTPS:** the app is served over HTTPS, and the browser blocks JSON or images served over `http://`.

### Examples per server

**Nginx**

```nginx
location /ads/ {
    add_header Access-Control-Allow-Origin "https://www.flutter-site.com" always;
    add_header Cache-Control "public, max-age=300";
    types { application/json json; }
    charset utf-8;
}
```

**Apache (`.htaccess` in the `ads/` folder)**

```apache
<IfModule mod_headers.c>
    Header set Access-Control-Allow-Origin "https://www.flutter-site.com"
    Header set Cache-Control "public, max-age=300"
</IfModule>
AddType "application/json; charset=utf-8" .json
```

**Node / Express (JSON generated by an API)**

```js
app.get('/ads/ads.json', (req, res) => {
  res.set({
    'Access-Control-Allow-Origin': 'https://www.flutter-site.com',
    'Cache-Control': 'public, max-age=300',
  });
  res.json(buildAdsConfig()); // Express already sends application/json; charset=utf-8
});
```

**AWS S3 (bucket CORS configuration)**

```json
[
  {
    "AllowedOrigins": ["https://www.flutter-site.com"],
    "AllowedMethods": ["GET", "HEAD"],
    "AllowedHeaders": ["*"],
    "MaxAgeSeconds": 3600
  }
]
```

With CloudFront in front, you also need to forward the `Origin` header (the "CORS-S3Origin" cache policy).

**Netlify / Cloudflare Pages (`_headers` file)**

```
/ads/*
  Access-Control-Allow-Origin: https://www.flutter-site.com
  Cache-Control: public, max-age=300
```

**Firebase Hosting (`firebase.json`)**

```json
"headers": [{
  "source": "/ads/**",
  "headers": [
    { "key": "Access-Control-Allow-Origin", "value": "https://www.flutter-site.com" },
    { "key": "Cache-Control", "value": "public, max-age=300" }
  ]
}]
```

### If the endpoint requires authentication

The app can send extra headers, for example `X-Api-Key`. In that case the server also has to:

- answer the `OPTIONS` request (the browser sends it before the `GET`);
- include `Access-Control-Allow-Headers: X-Api-Key` in the response.

Keep in mind that any key used by the web app is visible to users. It identifies the client; it doesn't protect data.

---

## 3. How to check

```bash
curl -I -H "Origin: https://www.flutter-site.com" https://cdn.client.com/ads/ads.json
```

The response must have `HTTP/2 200`, `content-type: application/json` and `access-control-allow-origin`.

To check the content, paste the JSON into any validator (for example jsonlint.com) and make sure that:

- every banner has an `id` and at least one asset with `url`, `width` and `height`;
- dates include the time zone;
- the image URLs open in the browser.

---

## 4. App side (reference for the web team)

```dart
// Once, at the top of the app
CustomAdScope(
  source: RemoteAdSource(
    Uri.parse('https://cdn.client.com/ads/ads.json'),
    refreshInterval: const Duration(minutes: 5),
    // headers: {'X-Api-Key': '...'},
  ),
  onImpression: (ad) => analytics.log('ad_impression', ad.id),
  onClick: (ad) => analytics.log('ad_click', ad.id),
  child: MyApp(),
)

// On any screen, wherever each spot goes
const AdSlot(placement: 'home_top')
const AdSlot(placement: 'sidebar')
```

---

## 5. Troubleshooting

| Symptom | Likely cause |
|---|---|
| No banner shows up and the browser console mentions "CORS" | The JSON is missing `Access-Control-Allow-Origin`. |
| No banner shows up and there's no CORS error | The placement name doesn't match the `AdSlot`, or every banner is outside its `startAt`/`endAt`. |
| A gray rectangle shows instead of the image | The images have no `Access-Control-Allow-Origin`, the URL returns 404, or it uses `http://`. |
| The banner looks small on desktop | The wide version is missing from `assets`, or the banner is taller than 30% of the screen and was scaled down. |
| A vertical banner doesn't show on mobile | Expected: vertical banners only show on desktop. Add a landscape asset (for example 320x50). |
| The GIF doesn't move | Expected: animations are frozen on the first frame. |
| Banners rotate slower than configured | `rotationSeconds` has a minimum of 30. |
| It looks blurry | The image wasn't exported at 2x. |
| A JSON change takes a while to show up | Caching: check `Cache-Control` and the app's refresh interval. |
| Broken accented characters | The JSON isn't saved as UTF-8. |
