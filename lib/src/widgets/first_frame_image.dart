import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Wraps another [ImageProvider] and only delivers its first frame.
///
/// This way an animated GIF, WebP or PNG is shown as a still image: it is
/// how [AdImage] enforces the "no flashing ads" rule.
@immutable
class FirstFrameImage extends ImageProvider<FirstFrameImageKey> {
  const FirstFrameImage(this.inner);

  final ImageProvider inner;

  @override
  Future<FirstFrameImageKey> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(FirstFrameImageKey(inner, configuration));

  @override
  ImageStreamCompleter loadImage(
    FirstFrameImageKey key,
    ImageDecoderCallback decode,
  ) {
    final completer = Completer<ImageInfo>();
    final stream = key.inner.resolve(key.configuration);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        // Removing the listener stops the original provider from advancing frames.
        stream.removeListener(listener);
        if (completer.isCompleted) {
          info.dispose();
        } else {
          completer.complete(info);
        }
      },
      onError: (error, stackTrace) {
        stream.removeListener(listener);
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace ?? StackTrace.current);
        }
      },
    );
    stream.addListener(listener);
    return OneFrameImageStreamCompleter(completer.future);
  }

  @override
  bool operator ==(Object other) =>
      other is FirstFrameImage && other.inner == inner;

  @override
  int get hashCode => inner.hashCode;
}

/// Cache key of [FirstFrameImage].
@immutable
class FirstFrameImageKey {
  const FirstFrameImageKey(this.inner, this.configuration);

  final ImageProvider inner;
  final ImageConfiguration configuration;

  @override
  bool operator ==(Object other) =>
      other is FirstFrameImageKey &&
      other.inner == inner &&
      other.configuration == configuration;

  @override
  int get hashCode => Object.hash(inner, configuration);
}
