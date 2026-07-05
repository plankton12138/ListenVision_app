# Task 3 Report: 播放状态与 UI — 三行展示

## Status: DONE

## Steps Completed

### Step 1: PlaybackState 新增 albumTitle + _updatePlayableState 透传
- **File:** `frontend_flutter/lib/presentation/viewmodels/player/playback_viewmodel.dart`
- Added `String? albumTitle` field to `PlaybackState` freezed factory constructor (after `title`, before `artist`)
- Added `albumTitle: playable.albumTitle` to `_updatePlayableState()` method
- Build runner regenerated `playback_viewmodel.freezed.dart` and `playback_viewmodel.g.dart` successfully

### Step 2: AudioInfo — 三行展示
- **File:** `frontend_flutter/lib/presentation/widgets/audio_info.dart`
- Line 1: Main title (page title) — maxLines: 1, bold
- Line 2: Album title (video title, conditional) — shown only when `albumTitle != null && isNotEmpty`, grey, small font
- Line 3: Artist (UP主) — grey, small font, with fallback to '未知艺术家'
- Changed `maxLines: 2` to `maxLines: 1` for the title Text widget

### Step 3: search_page.dart — 在线分P播放时传递 albumTitle
- **File:** `frontend_flutter/lib/presentation/views/discovery/search_page.dart`
- `_playSingleAudio`: added optional `String? albumTitle` parameter, passed to `Audio(albumTitle: albumTitle)`
- `_playAllPages`: added required `String albumTitle` parameter, passed to each `Audio(albumTitle: albumTitle)`
- `onPlayPage` callback: passes `albumTitle: item.title` (video title)
- `onPlayAll` callback: passes `albumTitle: item.title` (video title)

### Step 4: build_runner
- Ran `dart run build_runner build --delete-conflicting-outputs`
- Successfully regenerated 40 outputs including `playback_viewmodel.freezed.dart` and `playback_viewmodel.g.dart`
- Verified generated code includes `String? albumTitle` in all copyWith/call/toString/hashCode methods

### Step 5: flutter analyze
- Ran `flutter analyze --no-fatal-infos --no-fatal-warnings`
- **No errors or warnings introduced by Task 3 changes**
- Two pre-existing `error` level issues in `dio_client.dart` and `error_handler.dart` (DioExceptionType non-exhaustive switch) — unrelated to this task
- Info-level unnecessary import warnings in `search_page.dart` — pre-existing and harmless

## Issues or Concerns

None. All changes are clean and isolated. The three modified files (`playback_viewmodel.dart`, `audio_info.dart`, `search_page.dart`) compile without errors and pass flutter analyze cleanly.
