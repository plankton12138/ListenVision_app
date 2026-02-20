import 'dart:typed_data';

String createBlobUrl(Uint8List bytes, {String mimeType = 'application/octet-stream'}) {
  throw UnsupportedError('Blob URL only supported on web');
}

void revokeBlobUrl(String url) {
  // noop
}
