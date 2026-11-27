import AVFoundation
import UIKit
import QuartzCore

/// Sound effects + BGM on AVAudioEngine (native audio: no web-audio crackle).
/// SE play through a small pool of player nodes so combo hits can overlap.
/// BGM ducks automatically while English speech is playing.
@MainActor
final class AudioManager {
    static let shared = AudioManager()

    /// Sound effects. The hit / shot sounds are the ones from the web prototype (they felt the best).
    /// "sx_" sounds were made with Higgsfield; some have two candidates picked in the developer sound test.
    enum SE: String, CaseIterable {
        // buttons: one clean pop each
        case tap = "se_ui_tap", decide = "se_ui_decide", back = "se_ui_back"
        // battle (prototype set)
        case shoot = "se_shot1", hitSmall = "se_punch_high1", hitBig = "se_punch_high2", superHit = "se_super_arts_hit1"
        case kira = "se_kira1", eyeShine = "se_eye_shine1", blast = "se_bomb1"
        case rescue = "se_cute_pose1", damage = "se_bite1", wrong = "se_incorrect1"
        case bossAppear = "se_emergency_alert1_short", bossDefeat = "se_ko1", clear = "se_clear_wa", clearShort = "se_clear_wa_short"
        case spawn = "se_jump_anime1", gameOver = "se_doon1", bossLand = "se_boss_land", sad = "se_cute_sad1", levelUp = "se_levelup1"
        case papa = "se_papa1", boyon = "se_boyon1", sparkle = "se_kira1x"
        // study mode: calm classroom-style sounds
        // big boss finish: thunder + fanfare (synthesized)
        case thunder = "se_thunder", victory = "se_victory", win = "se_win", winBoss = "se_win_boss", finish = "se_finish", boom = "se_boom", fanfareBoss = "se_fanfare_boss", fever = "se_fever"
        case studyOK = "se_st_ok", studyNG = "se_st_ng", studyClear = "se_st_clear", studyCombo = "se_st_combo"
        // items (new set)
        case itemGet = "item_get", timeStop = "time_stop", heal = "heal", bomb = "bomb"
        // mini-games (synthesized)
        case mgSlap = "se_mg_slap", mgSplash = "se_mg_splash", mgReel = "se_mg_reel", mgBrush = "se_mg_brush", mgStamp = "se_mg_stamp"
        case mgCount = "se_mg_count", mgGo = "se_mg_go", mgWhoosh = "se_mg_whoosh", mgBloop = "se_mg_bloop"
        case mgPokon = "se_mg_pokon", mgClink = "se_mg_clink", mgSlash = "se_mg_slash", mgPoof = "se_mg_poof"
        case mgDon = "se_mg_don", mgKa = "se_mg_ka", mgHorn = "se_mg_horn", mgSizzle = "se_mg_sizzle"
        case mgCrack = "se_mg_crack", mgFlip = "se_mg_flip", mgArrow = "se_mg_arrow", mgGallop = "se_mg_gallop"

        var isNew: Bool { !rawValue.hasPrefix("se_") }
        static var newSet: [SE] { allCases.filter(\.isNew) }
        var candidates: [Int] { isNew ? [1, 2].filter { Bundle.main.url(forResource: "sx_\(rawValue)_\($0)", withExtension: "m4a") != nil } : [] }
        var chosen: Int {
            get {
                let v = UserDefaults.standard.integer(forKey: "sfx.\(rawValue)")
                let c = candidates
                return c.contains(v) ? v : (c.first ?? 1)
            }
            nonmutating set { UserDefaults.standard.set(newValue, forKey: "sfx.\(rawValue)") }
        }
        var file: String { self == .sparkle ? "se_kira1" : isNew ? "sx_\(rawValue)_\(chosen)" : rawValue }
        var label: String {
            switch self {
            case .itemGet: "アイテム獲得"; case .timeStop: "タイムストップ"; case .heal: "回復"; case .bomb: "ボム"
            default: rawValue
            }
        }
    }

    enum BGM: Equatable {
        case home, study, area(Area), boss, final, ending
        /// study tracks: "study_a" (flash / review), "study_b" (word training), "study_c" (listening & writing), "study_toeic"
        case track(String)
        /// file name in Sounds/ (falls back to the first stage track when a file is missing)
        var file: String {
            let want: String
            switch self {
            case .home: want = "bgm_home"
            case .study: want = "bgm_study"
            case .area(let a): want = a == .lv1 ? "bgm_stage1" : a == .graduation ? "bgm_grad" : "bgm_lv\(a.rawValue)"
            case .boss: want = "bgm_boss"
            case .final: want = "bgm_final"
            case .ending: want = "bgm_ending"
            case .track(let n): want = "bgm_" + n
            }
            if Bundle.main.url(forResource: want, withExtension: "m4a") != nil { return want }
            if case .track = self { return "bgm_study" }
            return "bgm_stage1"
        }
    }

    var seVolume: Float = 0.9 { didSet { seMixer.outputVolume = seVolume * 0.85 } }
    var bgmVolume: Float = 0.6 { didSet { applyBGMVolume() } }

    private let engine = AVAudioEngine()
    private let seMixer = AVAudioMixerNode()
    /// English voice lines are rendered to audio and played here, inside our own engine
    /// (letting the speech engine play by itself reconfigures the audio session and makes the engine restart = crackle)
    private let voicePlayer = AVAudioPlayerNode()
    /// slows recorded voices down for "slow reading" without lowering the pitch
    private let voiceStretch = AVAudioUnitTimePitch()
    private var sePlayers: [AVAudioPlayerNode] = []
    private var seVarispeed: [AVAudioUnitVarispeed] = []
    private var nextPlayer = 0
    private var buffers: [String: AVAudioPCMBuffer] = [:]

    private let bgmPlayer = AVAudioPlayerNode()
    private var currentBGM: String?
    private var ducked = false
    private var started = false

    private init() {}

    private var starting = false

    /// Activating the audio session can block, so it runs off the main thread; the engine starts afterwards.
    func start() {
        guard !started, !starting else { return }
        starting = true
        Task {
            await Task.detached(priority: .userInitiated) {
                let session = AVAudioSession.sharedInstance()
                try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
                // a slightly larger I/O buffer: no crackle when the 3D stage is being built
                try? session.setPreferredIOBufferDuration(0.023)
                try? session.setActive(true)
            }.value
            self.startEngine()
            if let pending = self.pendingBGM { self.pendingBGM = nil; self.playBGM(pending) }
        }
    }

    private var pendingBGM: BGM?
    private var lastUI: CFTimeInterval = 0
    private var busyUntil: [CFTimeInterval] = Array(repeating: 0, count: 10)
    private let limiter = AVAudioUnitEffect(audioComponentDescription: AudioComponentDescription(
        componentType: kAudioUnitType_Effect, componentSubType: kAudioUnitSubType_PeakLimiter,
        componentManufacturer: kAudioUnitManufacturer_Apple, componentFlags: 0, componentFlagsMask: 0))
    private var nodeFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!

    private func startEngine() {
        started = true

        engine.attach(seMixer)
        engine.attach(bgmPlayer)
        // sound effects go through a peak limiter so layered hits never clip
        engine.attach(limiter)
        engine.connect(seMixer, to: limiter, format: nodeFormat)
        engine.connect(limiter, to: engine.mainMixerNode, format: nodeFormat)
        let fmt = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        nodeFormat = fmt
        engine.connect(bgmPlayer, to: engine.mainMixerNode, format: fmt)
        voiceStretch.overlap = 32   // best quality (fewer robotic artifacts)
        engine.attach(voicePlayer); engine.attach(voiceStretch)
        engine.connect(voicePlayer, to: voiceStretch, format: fmt)
        engine.connect(voiceStretch, to: engine.mainMixerNode, format: fmt)
        for _ in 0..<10 {
            let p = AVAudioPlayerNode(), v = AVAudioUnitVarispeed()
            engine.attach(p); engine.attach(v)
            engine.connect(p, to: v, format: fmt)
            engine.connect(v, to: seMixer, format: fmt)
            sePlayers.append(p); seVarispeed.append(v)
        }
        let s = AppState.shared.settings
        seVolume = Float(s.seVolume); bgmVolume = Float(s.bgmVolume)
        try? engine.start()
        for p in sePlayers { p.play() }
        voicePlayer.play()
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { _ in
            Task { @MainActor in AudioManager.shared.restartIfNeeded() }
        }
        NotificationCenter.default.addObserver(forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main) { _ in
            Task { @MainActor in AudioManager.shared.restartIfNeeded() }
        }
        // back from the home screen: the engine may have been stopped while away — bring it and the BGM back
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { _ in
            Task { @MainActor in AudioManager.shared.wakeUp() }
        }
        // decode all sound effects up front, off the main thread (doing it on the main thread made the
        // first screen stutter); a sound asked for before it is ready is decoded on demand as before
        let names = SE.allCases.map(\.file)
        let box = SendableBox(nodeFormat)
        Task.detached(priority: .utility) {
            var out: [String: AVAudioPCMBuffer] = [:]
            for n in names {
                guard let url = Bundle.main.url(forResource: n, withExtension: "m4a"),
                      let b = AudioManager.decode(url, to: box.value) else { continue }
                out[n] = b
            }
            let done = SendableBox(out)
            await MainActor.run {
                for (k, v) in done.value where AudioManager.shared.buffers[k] == nil { AudioManager.shared.buffers[k] = v }
            }
        }
    }

    /// The engine stops after a call, Siri, the lock screen or headphones being plugged in.
    /// Playing a node on a stopped engine crashes, so restart first and report whether we can play.
    @discardableResult
    private func restartIfNeeded() -> Bool {
        // the app is going away (closed in the middle of a game): the system is stopping the engine,
        // and starting a player node now throws (that was the crash) — just stay quiet
        if UIApplication.shared.applicationState == .background { return false }
        if !engine.isRunning {
            let session = AVAudioSession.sharedInstance()
            try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try? session.setActive(true)
            try? engine.start()
            guard engine.isRunning else { return false }
            for p in sePlayers { p.play() }
            voicePlayer.play()
            if currentBGM != nil, let name = currentBGM, let b = buffers[name] {
                bgmPlayer.stop()
                bgmPlayer.scheduleBuffer(b, at: nil, options: [.loops], completionHandler: nil)
                bgmPlayer.play()
            }
        }
        return true
    }

    /// After the app comes back: restart the engine (a few tries — the session can need a moment) and the BGM.
    func wakeUp(_ attempt: Int = 0) {
        guard started else { return }
        if restartIfNeeded() {
            if let name = currentBGM, let b = buffers[name], !bgmPlayer.isPlaying {
                bgmPlayer.stop()
                bgmPlayer.scheduleBuffer(b, at: nil, options: [.loops], completionHandler: nil)
                bgmPlayer.play()
            }
            if currentBGM != nil { ducked = false; applyBGMVolume() }
            for p in sePlayers where !p.isPlaying { p.play() }
            if !voicePlayer.isPlaying { voicePlayer.play() }
        } else if attempt < 5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in self?.wakeUp(attempt + 1) }
        }
    }

    private func buffer(_ name: String) -> AVAudioPCMBuffer? {
        if let b = buffers[name] { return b }
        guard let url = Bundle.main.url(forResource: name, withExtension: "m4a"),
              let file = try? AVAudioFile(forReading: url) else { return nil }
        // always the format the player nodes were connected with (it must not change with the audio route)
        let outFmt = nodeFormat
        guard let src = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)) else { return nil }
        try? file.read(into: src)
        // convert to the engine's format so every node shares one format
        if src.format == outFmt { buffers[name] = src; return src }
        guard let conv = AVAudioConverter(from: src.format, to: outFmt) else { return nil }
        let ratio = outFmt.sampleRate / src.format.sampleRate
        guard let dst = AVAudioPCMBuffer(pcmFormat: outFmt, frameCapacity: AVAudioFrameCount(Double(src.frameLength) * ratio) + 1024) else { return nil }
        let feeder = OneShotFeeder(src)
        conv.convert(to: dst, error: nil, withInputFrom: feeder.next)
        buffers[name] = dst
        return dst
    }

    /// Play a sound effect. rate changes pitch+speed together (1 = normal).
    /// play one candidate directly (sound test)
    func preview(_ se: SE, _ n: Int) {
        guard started, let b = buffer("sx_\(se.rawValue)_\(n)") else { return }
        let p = sePlayers[nextPlayer % sePlayers.count]; nextPlayer += 1
        guard restartIfNeeded() else { return }
        p.stop(); p.play(); p.scheduleBuffer(b, at: nil, options: [], completionHandler: nil)
    }

    func se(_ se: SE, rate: Float = 1, volume: Float = 1) {
        guard started, let b = buffer(se.file) else { return }
        // a back / decide sound already covers the screen change that follows it
        let now = CACurrentMediaTime()
        if se == .tap && now - lastUI < 0.15 { return }
        if se == .tap || se == .back || se == .decide { lastUI = now }
        guard restartIfNeeded() else { return }
        // use a player that has finished; never cut a sound that is still ringing (that is the crackle)
        let r = max(0.5, min(2, rate))
        let free = busyUntil.indices.first { busyUntil[$0] <= now }
        let i = free ?? busyUntil.indices.min { busyUntil[$0] < busyUntil[$1] }!
        busyUntil[i] = now + Double(b.frameLength) / b.format.sampleRate / Double(r) + 0.05
        let p = sePlayers[i]
        seVarispeed[i].rate = r
        p.volume = volume * 0.8
        if !p.isPlaying { p.play() }
        // only when all ten are still ringing do we replace the oldest one
        p.scheduleBuffer(b, at: nil, options: free == nil ? [.interrupts] : [], completionHandler: nil)
    }

    /// where the music is now (seconds into the track, wraps when it loops); nil while nothing plays.
    /// The rhythm game lines its notes up with this.
    var bgmTime: Double? {
        guard bgmPlayer.isPlaying, let nt = bgmPlayer.lastRenderTime, let pt = bgmPlayer.playerTime(forNodeTime: nt), pt.sampleRate > 0 else { return nil }
        let t = Double(pt.sampleTime) / pt.sampleRate - AVAudioSession.sharedInstance().outputLatency
        guard let name = currentBGM, let b = buffers[name], b.format.sampleRate > 0 else { return t }
        let len = Double(b.frameLength) / b.format.sampleRate
        return len > 0 ? (t.truncatingRemainder(dividingBy: len) + len).truncatingRemainder(dividingBy: len) : t
    }
    /// the length of the track playing now (for the loop)
    var bgmLength: Double? {
        guard let name = currentBGM, let b = buffers[name], b.format.sampleRate > 0 else { return nil }
        return Double(b.frameLength) / b.format.sampleRate
    }

    func playBGM(_ bgm: BGM) {
        guard started else { pendingBGM = bgm; return }
        let name = bgm.file
        guard currentBGM != name else { return }
        currentBGM = name
        // fade the old track out (an abrupt stop clicks), then start the new one
        fadeBGM(to: 0, steps: 6) { [weak self] in
            guard let self, self.currentBGM == name else { return }
            self.bgmPlayer.stop()
            if let b = self.buffers[name] { self.startBGM(b); return }
            // decode off the main thread: a whole track takes a moment and would stutter the game start
            guard let url = Bundle.main.url(forResource: name, withExtension: "m4a") else { return }
            let box = SendableBox(self.nodeFormat)
            Task.detached(priority: .userInitiated) {
                let out = SendableBox(AudioManager.decode(url, to: box.value))
                await MainActor.run {
                    guard self.currentBGM == name, let b = out.value else { return }
                    // keep only the playing track in memory (a decoded track is tens of MB)
                    for k in self.buffers.keys where k.hasPrefix("bgm_") && k != name { self.buffers[k] = nil }
                    self.buffers[name] = b
                    self.startBGM(b)
                }
            }
        }
    }

    private func startBGM(_ b: AVAudioPCMBuffer) {
        bgmPlayer.stop()
        bgmPlayer.volume = 0
        bgmPlayer.scheduleBuffer(b, at: nil, options: [.loops], completionHandler: nil)
        guard restartIfNeeded() else { return }
        bgmPlayer.play()
        fadeBGM(to: bgmVolume * 0.5 * (ducked ? 0.4 : 1), steps: 12) {}
    }

    private var fadeToken = 0
    private func fadeBGM(to target: Float, steps: Int, then: @escaping @MainActor () -> Void) {
        fadeToken += 1
        let token = fadeToken, from = bgmPlayer.volume
        Task { @MainActor in
            if abs(from - target) > 0.001 {
                for k in 1...steps {
                    guard token == self.fadeToken else { return }
                    self.bgmPlayer.volume = from + (target - from) * Float(k) / Float(steps)
                    try? await Task.sleep(nanoseconds: 25_000_000)
                }
            }
            guard token == self.fadeToken else { return }
            then()
        }
    }

    /// Read a whole m4a into one buffer in the engine format (runs off the main thread).
    nonisolated static func decode(_ url: URL, to outFmt: AVAudioFormat) -> AVAudioPCMBuffer? {
        guard let file = try? AVAudioFile(forReading: url),
              let src = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)) else { return nil }
        try? file.read(into: src)
        if src.format == outFmt { return src }
        guard let conv = AVAudioConverter(from: src.format, to: outFmt) else { return nil }
        let ratio = outFmt.sampleRate / src.format.sampleRate
        guard let dst = AVAudioPCMBuffer(pcmFormat: outFmt, frameCapacity: AVAudioFrameCount(Double(src.frameLength) * ratio) + 1024) else { return nil }
        let feeder = OneShotFeeder(src)
        conv.convert(to: dst, error: nil, withInputFrom: feeder.next)
        return dst
    }

    /// Play one rendered voice line (already in the engine format).
    private var voiceToken = 0
    func playVoice(_ b: AVAudioPCMBuffer, volume: Float, rate: Float = 1, cents: Float = 0) {
        guard started, restartIfNeeded() else { return }
        voiceStretch.rate = rate
        voiceStretch.pitch = cents
        voiceStretch.bypass = rate == 1 && cents == 0   // untouched voices stay exactly as recorded
        voiceToken += 1
        let t = voiceToken
        voicePlayer.stop()
        voicePlayer.volume = volume
        duck(true)
        voicePlayer.scheduleBuffer(b, at: nil, options: [], completionCallbackType: .dataPlayedBack) { _ in
            Task { @MainActor in if t == AudioManager.shared.voiceToken { AudioManager.shared.duck(false) } }
        }
        voicePlayer.play()
    }
    /// plays the voice if the engine is running; false lets the caller fall back to the system voice
    func playVoiceChecked(_ b: AVAudioPCMBuffer, volume: Float, rate: Float = 1, cents: Float = 0) -> Bool {
        guard started, restartIfNeeded(), b.frameLength > 0 else { return false }
        playVoice(b, volume: volume, rate: rate, cents: cents)
        return true
    }
    func stopVoice() {
        voiceToken += 1
        voicePlayer.stop()
        duck(false)
    }
    var engineFormat: AVAudioFormat { nodeFormat }

    /// fade out every sound effect that is still ringing (e.g. a long fanfare when the stage is restarted)
    func fadeOutSE(_ seconds: Double = 0.35) {
        let full = seVolume * 0.85
        let steps = 7
        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + seconds * Double(i) / Double(steps)) { [weak self] in
                guard let self else { return }
                self.seMixer.outputVolume = full * Float(steps - i) / Float(steps)
                if i == steps {
                    for p in self.sePlayers { p.stop(); p.play() }
                    self.seMixer.outputVolume = self.seVolume * 0.85
                }
            }
        }
    }
    func stopBGM() { currentBGM = nil; fadeBGM(to: 0, steps: 6) { [weak self] in self?.bgmPlayer.stop() } }

    /// lower the BGM while English is spoken
    func duck(_ on: Bool) {
        guard ducked != on else { return }
        ducked = on
        // ramp instead of jumping (a sudden volume step clicks)
        let from = bgmPlayer.volume, to = bgmVolume * 0.5 * (on ? 0.4 : 1)
        rampToken += 1
        let token = rampToken
        Task { @MainActor in
            for k in 1...10 {
                guard token == self.rampToken else { return }
                self.bgmPlayer.volume = from + (to - from) * Float(k) / 10
                try? await Task.sleep(nanoseconds: 20_000_000)
            }
        }
    }
    private var rampToken = 0

    private func applyBGMVolume() { bgmPlayer.volume = bgmVolume * 0.5 * (ducked ? 0.4 : 1) }
}

/// Hands the source buffer to AVAudioConverter exactly once.
nonisolated private final class OneShotFeeder: @unchecked Sendable {
    private var buffer: AVAudioPCMBuffer?
    init(_ b: AVAudioPCMBuffer) { buffer = b }
    func next(_ count: AVAudioPacketCount, _ status: UnsafeMutablePointer<AVAudioConverterInputStatus>) -> AVAudioBuffer? {
        if let b = buffer { buffer = nil; status.pointee = .haveData; return b }
        status.pointee = .endOfStream; return nil
    }
}

/// Carries a non-Sendable value across a Task boundary (the value is not touched concurrently).
nonisolated final class SendableBox<T>: @unchecked Sendable {
    let value: T
    init(_ v: T) { value = v }
}
