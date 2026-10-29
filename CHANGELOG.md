## 1.0.0

Initial release.

- `AdSlot`: shows the ads of a placement from a remote JSON, with rotation, scheduling and an optional placeholder.
- `CustomAd`: a single ad in six formats (`creative`, `leaderboard`, `mediumRectangle`, `skyscraper`, `card`, `hero`), with hover effects, click handling, viewable impression tracking, an optional close button and a fully custom `builder`.
- `CustomAdRotator`: rotates several ads in the same space and pauses on hover.
- `CustomAdScope`: shared source, style, policy and analytics callbacks, with `CustomAdScope.merge` for per-section overrides.
- `RemoteAdSource`: downloads and refreshes the ads JSON, merges simultaneous requests and keeps the last valid configuration on errors.
- `AdPolicy`: non-intrusive rules based on the Better Ads Standards and Acceptable Ads (mandatory label, height cap, side-only vertical ads, frozen animations, minimum rotation interval).
- `AdData`, `AdAsset`, `AdConfig`, `AdPlacement` and `AdStyle` models, plus the `AdImage`, `AdCta` and `AdMetaLine` building blocks.
