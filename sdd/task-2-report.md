### Task 2 Report

**Status:** DONE

**Files modified:**
1. `frontend_flutter/lib/data/database/app_database.dart` — Bumped version 11 to 12, added `album_title` column to `download_tasks` table, added `_upgradeToV12` migration
2. `frontend_flutter/lib/services/bilibili_downloader.dart` — Added `albumTitle` parameter to `download()`, changed metadata logic: when `albumTitle` is set, use `fileName` as title and `albumTitle` as album; when null, use video title as title and null album
3. `frontend_flutter/lib/services/metadata_writer.dart` — Changed `album: metadata.album ?? 'Bilibili'` to `album: metadata.album` (nullable pass-through)
4. `frontend_flutter/lib/data/repositories/download_repository.dart` — Added `albumTitle` parameter to `addDownloadTask`, stored in DB, passed `task.albumTitle` to `downloader.download()`
5. `frontend_flutter/lib/presentation/views/discovery/search_page.dart` — Updated `_downloadPage` to accept and pass `albumTitle`; updated `_downloadAllPages` to use `page.title` as filename and pass `albumTitle: title`; updated callback
6. `frontend_flutter/lib/presentation/viewmodels/system/download_viewmodel.dart` — Added `albumTitle` parameter to `addDownload()`, passed to repository

**flutter analyze result:** No new errors. All pre-existing errors/warnings unchanged.

**Issues/Concerns:** None.
