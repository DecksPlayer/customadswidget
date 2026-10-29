import 'package:customadswidget/customadswidget.dart';

/// Template ads: text + photo, the app builds the design.
const templateAds = [
  AdData(
    id: 'coffee',
    title: 'Specialty coffee at your door',
    description: 'Subscribe and get freshly roasted beans every week.',
    imageUrl: 'https://picsum.photos/seed/coffee/800/450',
    ctaLabel: 'Subscribe',
    targetUrl: 'https://example.com/coffee',
    sponsor: 'South Roasters',
  ),
  AdData(
    id: 'course',
    title: 'Learn Flutter Web in 4 weeks',
    description: 'A hands-on course with real projects and live mentoring.',
    imageUrl: 'https://picsum.photos/seed/laptop/800/450',
    ctaLabel: 'Sign up',
    targetUrl: 'https://example.com/course',
    sponsor: 'Dev Academy',
  ),
  AdData(
    id: 'travel',
    title: 'Weekend getaways',
    description: 'Up to 30% off mountain cabins when you book this month.',
    imageUrl: 'https://picsum.photos/seed/mountain/800/450',
    ctaLabel: 'See deals',
    targetUrl: 'https://example.com/travel',
    sponsor: 'Andes Travel',
    badge: 'Sponsored',
  ),
];

const textOnlyAd = AdData(
  id: 'black-friday',
  title: 'Black Friday: buy one, get one free',
  description: 'Only for 48 hours. Online only.',
  ctaLabel: 'Shop now',
  targetUrl: 'https://example.com/black-friday',
);

/// URL of a banner served from web/ads/banners.
String bannerUrl(String file) =>
    Uri.base.resolve('ads/banners/$file').toString();

/// Image banner built in code (usually it comes from the JSON).
final creativeAd = AdData(
  id: 'summer-code',
  title: 'Summer sale: 50% off everything',
  targetUrl: 'https://example.com/summer',
  assets: [
    AdAsset(url: bannerUrl('summer-728x90.png'), width: 728, height: 90),
    AdAsset(url: bannerUrl('summer-320x50.png'), width: 320, height: 50),
  ],
);

/// Image banner whose images are bundled as Flutter assets.
const localCreativeAd = AdData(
  id: 'local-asset',
  title: 'Local banner bundled as an asset',
  targetUrl: 'https://example.com/local',
  assets: [
    AdAsset(url: 'assets/banners/local-300x250.png', width: 300, height: 250),
  ],
);
