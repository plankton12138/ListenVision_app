import 'dart:convert';

import 'package:demo/utils/show_notes.dart';
import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/foundation.dart';

class DownloadManager with ChangeNotifier {
  late Database _database;
  List<Map<String, dynamic>> downloads = [];
  final Map<int, CancelToken> _cancelTokens = {};
  
  Future<void> _loadDownloads() async {
    downloads = await _database.query('downloads');
    notifyListeners();
  }

  // get the response from the url
  Future<http.Response> _getResponse(String url) async {
    debugPrint('url: $url');
    return await http.get(
      Uri.parse(url),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36',
        'Referer': 'https://www.bilibili.com/',
      },
    );
  }

  // let user select save location
  Future<String?> _pickDirectory() async {
    try {
      final directory = await getDirectoryPath();
      return directory;
    } catch (e) {
      return null;
    }
  }  

  Future<void> initDatabase() async {
    final directy = await getApplicationDocumentsDirectory();
    debugPrint('database path: ${join(directy.path, 'downloads.db')}');
    _database = await openDatabase(
      join(directy.path, 'downloads.db'),
      onCreate: (db, version) {
        return db.execute(
          '''CREATE TABLE downloads(
          id INTEGER PRIMARY KEY AUTOINCREMENT, 
          url TEXT, 
          savePath TEXT, 
          downloadedBytes INTEGER, 
          totalBytes INTEGER, 
          isPaused INTEGER,
          originalUrl TEXT,
          title TEXT
          )''',
        );
      },
      version: 1, 
    );
  }

  Future<void> addDownload(BuildContext context, String url) async {
    // check if the url is a bilibili video
    if (!url.startsWith('https://www.bilibili.com/video/') &&
        !url.startsWith('http://www.bilibili.com/video/')) {
      debugPrint('not a bilibili video');
      showMySnackBar(context, 'download failed, not a bilibili video', Colors.red, 500);
      return;
    }

    try {
      // get the html content
      final response = await _getResponse(url);
      // parse html content
      final document = parse(response.body);
      final title = document.querySelector('h1.video-title')?.attributes['title'];
      final sanitizedTitle = sanitizeTitle(title!);
      // check script with window.__playinfo__
      final scripts = document.querySelectorAll('script');
      String? playInfoScript;
      for (final script in scripts) {
        if (script.text.contains('window.__playinfo__')) {
          playInfoScript = script.text;
          break;
        }
      }
      if (playInfoScript == null) return;
      // get audio baseurl
      final jsonStr = playInfoScript.split('window.__playinfo__=')[1].split(';')[0].trim();
      final playInfo = jsonDecode(jsonStr);
      final audioBaseUrl = playInfo['data']['dash']['audio'][0]['baseUrl'];
      debugPrint("audio baseUrl: $audioBaseUrl");

      // get save location
      final savePath = await _pickDirectory();
      if (savePath == null) return; // user cancel

      final audioFilePath = File('$savePath/$sanitizedTitle.m4a');
      // add download to database
      int id = await _database.insert(
        'downloads',
        {
          'url': audioBaseUrl,
          'savePath': audioFilePath.path,
          'downloadedBytes': 0,
          'totalBytes': 0,
          'isPaused': 0,
          'originalUrl': url,
          'title': title,
        },
      );
      showMySnackBar(context, 'add download list: $title', Colors.green, 1000);
      await startDownload(audioBaseUrl, audioFilePath.path, url, id);
      _loadDownloads(); // notify listeners

    } catch (e) {
      debugPrint('download failed: $e');
      showMySnackBar(context, 'download failed: $e', Colors.red, 1000);
    }
  }

  Future<void> startDownload(
    String audioBaseUrl, String savePath, String originalUrl, int id) async {

    final cancelToken = CancelToken();
    _cancelTokens[id] = cancelToken;
    RandomAccessFile? raf;
    int totalBytes = 0;

    try {
      var response = await _database.query(
        'downloads',
        where: 'id = ?',
        whereArgs: [id],
      );
      int downloadedBytes = response.first['downloadedBytes'] as int;
      totalBytes = response.first['totalBytes'] as int;
      // bool isPaused = response.first['isPaused'] as bool;

      // check if the file already downloaded
      if (downloadedBytes >= totalBytes && totalBytes > 0) {
        debugPrint('already downloaded');
        await _database.update(
          'downloads',
          {'isPaused': 0},
          where: 'id = ?',
          whereArgs: [id],
        );
        return;
      }

      // start downloading
      var dio = Dio();
      var options = Options(
        headers: {
          'Range': totalBytes > 0 ? 'bytes=$downloadedBytes-' : 'bytes=0-',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36',
          'Referer': 'https://www.bilibili.com/',
        },
        responseType: ResponseType.stream,
      );

      var resp = await dio.getUri(
        Uri.parse(audioBaseUrl),
        options: options,
        cancelToken: cancelToken,
      );
      
      // handle content-range 
      final contentRange = resp.headers.value('content-range');
      if (contentRange != null) {
        totalBytes = int.parse(contentRange.split('/').last);
      } else {
        totalBytes = int.parse(resp.headers.value('content-length')!);
      }

      // initialize file
      final file = File(savePath);
      raf = await file.open(mode: FileMode.writeOnlyAppend);

      await for (var chunk in resp.data.stream) {
        // check if download is paused
        if (cancelToken.isCancelled ||
            (await _database.query('downloads', where: 'id = ?', whereArgs: [id]))
            .first['isPaused'] == 1) {
              break;
        }
        
        await raf.writeFrom(chunk);
        downloadedBytes += chunk.length as int;

        // update progress
        await _database.update(
          'downloads',
          {
            'downloadedBytes': downloadedBytes,
            'totalBytes': totalBytes,
          },
          where: 'id = ?',
          whereArgs: [id],
        );
        notifyListeners();
      }

      // download complete
      if (downloadedBytes >= totalBytes) {
        await _database.update(
          'downloads',
          {'isPaused': 0},
          where: 'id = ?',
          whereArgs: [id],
        );
        await afterDownload(originalUrl, savePath);
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse && e.response?.statusCode == 416) {
        debugPrint('download complete , ');
        await _database.update(
          'downloads',
          {
            'downloadedBytes': totalBytes,
            'totalBytes': totalBytes,
            'isPaused': 0,
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    } finally {
      await raf?.close();
      _cancelTokens.remove(id);
      // notifyListeners();
      _loadDownloads(); // notify listeners
    }
  }

  Future<List<Map<String, dynamic>>> getDownloads() async {
    return await _database.query('downloads');
  }

  Future<void> pauseDownload(int id) async {
    await _database.update(
      'downloads',
      {'isPaused': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    _cancelTokens[id]?.cancel();
    _cancelTokens.remove(id);
    await _loadDownloads(); // notify listeners
  }

  Future<void> resumeDownload(int id) async {
    await _database.update(
      'downloads',
      {'isPaused': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    var download = await _database.query(
      'downloads',
      where: 'id = ?',
      whereArgs: [id],
    );
    String url = download.first['url'] as String;
    String savePath = download.first['savePath'] as String;
    String originalUrl = download.first['originalUrl'] as String;
    startDownload(url, savePath, originalUrl, id);
    _loadDownloads(); // notify listeners
  }

  Future<void> deleteDownload(int id) async {
    await _database.delete(
      'downloads',
      where: 'id = ?',
      whereArgs: [id],
    );
    _loadDownloads(); // notify listeners
  }

  // sanitize the title string
  String sanitizeTitle(String input) {
    const pattern = r'[^\u4e00-\u9fa5a-zA-Z0-9\s（）\(\)【】\[\]{}《》“”‘’·！？，。：；、—…]';
    final sanitized = input.replaceAll(RegExp(pattern), '');
    return sanitized.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Future<void> afterDownload(String url, String audioFilePath) async {
    debugPrint('afterDownload: $audioFilePath');
    // get audio info
    final response = await _getResponse(url);
    final document = parse(response.body);

    final title = document.querySelector('h1.video-title')?.attributes['title'];
    final author = document.querySelector('meta[itemprop="author"][name="author"]')?.attributes['content'];
    final imageMeta = document.querySelector('meta[itemprop="image"]');
    String imageUrl = imageMeta?.attributes['content'] ?? '';
    if (imageUrl.startsWith('//')) {
      imageUrl = 'https:$imageUrl';
    }

    debugPrint("audio author: $author");
    debugPrint("audio title: $title");
    debugPrint("audio imageUrl: $imageUrl");

    // download image file
    final imageResponse = await _getResponse(imageUrl);

    // write metadata to file using audio_metadata_reader
    try {
      final audioFile = File(audioFilePath);
      updateMetadata(
        audioFile,
        (metadata) {
          metadata.setTitle(title);
          metadata.setArtist(author);
          metadata.setAlbum(url); // album name is the video url
          metadata.setPictures([
            Picture(
              Uint8List.fromList(imageResponse.bodyBytes),
              "image/jpeg",
              PictureType.coverFront,
            )
          ]);
        },
      );
      debugPrint('【afterDownload】Metadata written successfully');
    } catch (e) {
      debugPrint('【afterDownload】Failed to write metadata: $e');
    }
  }
}
