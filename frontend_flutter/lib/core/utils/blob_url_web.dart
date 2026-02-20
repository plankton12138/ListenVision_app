import 'dart:html' as html;
import 'dart:typed_data';

String createBlobUrl(Uint8List bytes, {String mimeType = 'application/octet-stream'}) {
  final blob = html.Blob(<Object>[bytes], mimeType);
  return html.Url.createObjectUrlFromBlob(blob);
}

void revokeBlobUrl(String url) {
  html.Url.revokeObjectUrl(url);
}
