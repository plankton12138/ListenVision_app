package com.example.flutter_application_1

import android.app.*
import android.content.*
import android.media.*
import android.media.session.MediaSession
import android.media.session.PlaybackState
import android.os.*
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

// 让前台服务与 Activity 共用唯一 Flutter 引擎，退出 Activity 不销毁正在播放的引擎。
class MainActivity : FlutterActivity() {
    override fun provideFlutterEngine(context: Context): FlutterEngine = PlaybackRuntime.engine(context)
    override fun shouldDestroyEngineWithHost(): Boolean = false
}

object PlaybackRuntime {
    private var flutterEngine: FlutterEngine? = null
    lateinit var channel: MethodChannel
    var snapshot: Map<String, Any?> = emptyMap()
    var service: PlaybackService? = null
    val pending = mutableListOf<MethodChannel.Result>()

    fun engine(context: Context): FlutterEngine {
        flutterEngine?.let { return it }
        val app = context.applicationContext
        val engine = FlutterEngine(app)
        flutterEngine = engine
        channel = MethodChannel(engine.dartExecutor.binaryMessenger, "listenvision/background_audio")
        channel.setMethodCallHandler { call, result ->
            @Suppress("UNCHECKED_CAST")
            when (call.method) {
                "modernStorage" -> result.success(Build.VERSION.SDK_INT >= 30)
                "update" -> {
                    snapshot = (call.arguments as? Map<String, Any?>) ?: emptyMap()
                    service?.update()
                    result.success(null)
                }
                "prepare" -> {
                    snapshot = (call.arguments as? Map<String, Any?>) ?: snapshot
                    pending.add(result)
                    try {
                        val intent = Intent(app, PlaybackService::class.java).setAction("prepare")
                        if (Build.VERSION.SDK_INT >= 26) app.startForegroundService(intent) else app.startService(intent)
                    } catch (error: Exception) {
                        pending.remove(result)
                        result.error("BACKGROUND_START_FAILED", error.message, null)
                    }
                }
                "abandonFocus" -> { service?.abandonFocus(); result.success(null) }
                "stop" -> { service?.stopSelf(); result.success(null) }
                else -> result.notImplemented()
            }
        }
        engine.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())
        return engine
    }
    fun attached(): Boolean = ::channel.isInitialized

    fun command(action: String, position: Long? = null) {
        if (::channel.isInitialized) channel.invokeMethod("command", mapOf("action" to action, "position" to position))
    }
}

@Suppress("DEPRECATION")
class PlaybackService : Service() {
    private lateinit var session: MediaSession
    private lateinit var audio: AudioManager
    private lateinit var wakeLock: PowerManager.WakeLock
    private var focusRequest: AudioFocusRequest? = null
    private var hasFocus = false
    private var interrupted = false
    private var foreground = false
    private val channelId = "listenvision_playback"
    private val notificationId = 1701
    private val noisy = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == AudioManager.ACTION_AUDIO_BECOMING_NOISY) {
                interrupted = false
                PlaybackRuntime.command("pause")
            }
        }
    }
    private val focusListener = AudioManager.OnAudioFocusChangeListener { change ->
        when (change) {
            AudioManager.AUDIOFOCUS_GAIN -> {
                hasFocus = true
                if (interrupted) {
                    interrupted = false
                    PlaybackRuntime.command("resumeAfterInterruption")
                }
            }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT, AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                hasFocus = false
                interrupted = true
                PlaybackRuntime.command("pauseForInterruption")
            }
            AudioManager.AUDIOFOCUS_LOSS -> {
                hasFocus = false
                interrupted = false
                PlaybackRuntime.command("pause")
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        PlaybackRuntime.service = this
        audio = getSystemService(AUDIO_SERVICE) as AudioManager
        wakeLock = (getSystemService(POWER_SERVICE) as PowerManager)
            .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "ListenVision:playback")
        wakeLock.setReferenceCounted(false)
        if (Build.VERSION.SDK_INT >= 26) {
            (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).createNotificationChannel(
                NotificationChannel(channelId, "音频播放", NotificationManager.IMPORTANCE_LOW))
        }
        session = MediaSession(this, "ListenVision")
        session.setFlags(MediaSession.FLAG_HANDLES_MEDIA_BUTTONS or MediaSession.FLAG_HANDLES_TRANSPORT_CONTROLS)
        session.setCallback(object : MediaSession.Callback() {
            override fun onPlay() { PlaybackRuntime.command("play") }
            override fun onPause() { PlaybackRuntime.command("pause") }
            override fun onStop() { PlaybackRuntime.command("stop") }
            override fun onSkipToNext() { PlaybackRuntime.command("next") }
            override fun onSkipToPrevious() { PlaybackRuntime.command("previous") }
            override fun onSeekTo(position: Long) { PlaybackRuntime.command("seek", position) }
        })
        session.isActive = true
        val filter = IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY)
        if (Build.VERSION.SDK_INT >= 33) registerReceiver(noisy, filter, RECEIVER_NOT_EXPORTED)
        else registerReceiver(noisy, filter)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (!PlaybackRuntime.attached()) { stopSelf(); return START_NOT_STICKY }
        if (intent?.action == "prepare") {
            // 必须先进入前台，再申请 targetSdk 35+ 的音频焦点。
            startForeground(notificationId, notification())
            foreground = true
            val granted = requestFocus()
            PlaybackRuntime.pending.toList().forEach { it.success(granted) }
            PlaybackRuntime.pending.clear()
            if (granted) update() else stopSelf()
        } else {
            when (intent?.action) {
                "play", "pause", "previous", "next", "stop" -> PlaybackRuntime.command(intent.action!!)
            }
        }
        return START_NOT_STICKY
    }

    private fun requestFocus(): Boolean {
        if (hasFocus) return true
        val result = if (Build.VERSION.SDK_INT >= 26) {
            if (focusRequest == null) focusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                .setAudioAttributes(AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC).build())
                .setWillPauseWhenDucked(true)
                .setOnAudioFocusChangeListener(focusListener).build()
            audio.requestAudioFocus(focusRequest!!)
        } else audio.requestAudioFocus(focusListener, AudioManager.STREAM_MUSIC, AudioManager.AUDIOFOCUS_GAIN)
        hasFocus = result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        return hasFocus
    }

    fun abandonFocus() {
        interrupted = false
        if (Build.VERSION.SDK_INT >= 26) focusRequest?.let { audio.abandonAudioFocusRequest(it) }
        else audio.abandonAudioFocus(focusListener)
        hasFocus = false
        if (foreground && PlaybackRuntime.snapshot["playing"] != true && PlaybackRuntime.snapshot["loading"] != true) {
            stopForeground(STOP_FOREGROUND_DETACH)
            foreground = false
        }
    }

    fun update() {
        val data = PlaybackRuntime.snapshot
        if (data["hasContent"] != true) { stopSelf(); return }
        val playing = data["playing"] == true
        val loading = data["loading"] == true
        val position = (data["position"] as? Number)?.toLong() ?: 0L
        val speed = (data["speed"] as? Number)?.toFloat() ?: 1f
        session.setMetadata(MediaMetadata.Builder()
            .putString(MediaMetadata.METADATA_KEY_TITLE, data["title"] as? String ?: "ListenVision")
            .putString(MediaMetadata.METADATA_KEY_ARTIST, data["artist"] as? String ?: "")
            .putString(MediaMetadata.METADATA_KEY_ALBUM, data["album"] as? String ?: "")
            .putLong(MediaMetadata.METADATA_KEY_DURATION, (data["duration"] as? Number)?.toLong() ?: 0L).build())
        val state = if (loading) PlaybackState.STATE_BUFFERING else if (playing) PlaybackState.STATE_PLAYING else PlaybackState.STATE_PAUSED
        session.setPlaybackState(PlaybackState.Builder().setActions(
            PlaybackState.ACTION_PLAY or PlaybackState.ACTION_PAUSE or PlaybackState.ACTION_PLAY_PAUSE or
            PlaybackState.ACTION_STOP or PlaybackState.ACTION_SKIP_TO_NEXT or PlaybackState.ACTION_SKIP_TO_PREVIOUS or PlaybackState.ACTION_SEEK_TO)
            .setState(state, position, if (playing) speed else 0f, SystemClock.elapsedRealtime()).build())
        if (playing || loading) {
            if (!wakeLock.isHeld) wakeLock.acquire(10 * 60 * 1000L)
        } else {
            if (wakeLock.isHeld) wakeLock.release()
            if (!interrupted) abandonFocus()
            if (foreground && !interrupted) { stopForeground(STOP_FOREGROUND_DETACH); foreground = false }
        }
        (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).notify(notificationId, notification())
    }

    private fun action(name: String): PendingIntent = PendingIntent.getService(this, name.hashCode(),
        Intent(this, PlaybackService::class.java).setAction(name), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

    private fun notification(): Notification {
        val data = PlaybackRuntime.snapshot
        val playing = data["playing"] == true
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(this, channelId) else Notification.Builder(this)
        val open = PendingIntent.getActivity(this, 0, Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        return builder.setSmallIcon(android.R.drawable.ic_media_play)
            .setContentTitle(data["title"] as? String ?: "ListenVision")
            .setContentText(data["artist"] as? String ?: "")
            .setContentIntent(open).setDeleteIntent(action("stop")).setOnlyAlertOnce(true)
            .setVisibility(Notification.VISIBILITY_PUBLIC).setOngoing(playing || data["loading"] == true)
            .addAction(Notification.Action.Builder(android.R.drawable.ic_media_previous, "上一首", action("previous")).build())
            .addAction(Notification.Action.Builder(if (playing) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play,
                if (playing) "暂停" else "播放", action(if (playing) "pause" else "play")).build())
            .addAction(Notification.Action.Builder(android.R.drawable.ic_media_next, "下一首", action("next")).build())
            .setStyle(Notification.MediaStyle().setMediaSession(session.sessionToken).setShowActionsInCompactView(0, 1, 2))
            .build()
    }

    override fun onDestroy() {
        PlaybackRuntime.service = null
        PlaybackRuntime.pending.toList().forEach { it.success(false) }
        PlaybackRuntime.pending.clear()
        abandonFocus()
        if (wakeLock.isHeld) wakeLock.release()
        unregisterReceiver(noisy)
        session.isActive = false
        session.release()
        stopForeground(STOP_FOREGROUND_REMOVE)
        (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).cancel(notificationId)
        super.onDestroy()
    }
    override fun onBind(intent: Intent?): IBinder? = null
}
