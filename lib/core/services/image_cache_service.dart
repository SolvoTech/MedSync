import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ImageCacheService {
  const ImageCacheService._();

  static Future<void> clearAll() async {
    imageCache.clear();
    imageCache.clearLiveImages();
    await DefaultCacheManager().emptyCache();
  }

  static Future<void> evictUrl(String? url) async {
    final normalized = url?.trim();
    if (normalized == null || normalized.isEmpty) {
      return;
    }

    imageCache.evict(NetworkImage(normalized));
    await CachedNetworkImage.evictFromCache(normalized);
    await DefaultCacheManager().removeFile(normalized);
  }
}
