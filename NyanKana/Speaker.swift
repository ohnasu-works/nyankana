import AVFoundation
import CryptoKit
import UIKit

/// English speech. Uses pre-generated native voice files (tts_<key>.m4a, Google Cloud TTS) when
/// they are bundled; until then falls back to the system voice.
@MainActor
final class Speaker: NSObject {
    static let shared = Speaker()

    struct Voice {
        var pitch: Float = 1
        var rate: Float = 1
        static let normal = Voice()
        static let ken = Voice(pitch: 0.85, rate: 0.95)
        static let rin = Voice(pitch: 1.2, rate: 0.95)
        static let nyan = Voice(pitch: 1.6, rate: 1.05)
        static let bee = Voice(pitch: 1.55, rate: 0.95)
        static let beeFree = Voice(pitch: 1.3, rate: 0.95)
        static let stapler = Voice(pitch: 0.55, rate: 0.85)
    }

    private let synth = AVSpeechSynthesizer()
    /// plays directly through the system when rendering to our engine fails (seen on some iPads)
    private let liveSynth = AVSpeechSynthesizer()

    private func copy(_ u: AVSpeechUtterance) -> AVSpeechUtterance {
        let c = AVSpeechUtterance(string: u.speechString)
        c.voice = u.voice; c.rate = u.rate; c.pitchMultiplier = u.pitchMultiplier; c.volume = u.volume
        return c
    }
    /// speak through the system directly (fallback)
    private func speakLive(_ u: AVSpeechUtterance) {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.mixWithOthers, .duckOthers])
        liveSynth.stopSpeaking(at: .immediate)
        liveSynth.speak(copy(u))
    }
    private lazy var enVoice: AVSpeechSynthesisVoice? = {
        let all = AVSpeechSynthesisVoice.speechVoices().filter { $0.language == "ja-JP" }
        return all.first { $0.quality == .premium } ?? all.first { $0.quality == .enhanced } ?? AVSpeechSynthesisVoice(language: "ja-JP")
    }()
    private var token = 0
    /// Rendering the line first and then playing it starts a beat late on iPad, so there the
    /// system speaks directly. Also switched on for good once rendering fails on a device.
    static var directOnly = UIScale.isPad
    /// にゃんカナ: never use the system (iPhone) voice
    static let recordedOnly = true

    override private init() {
        super.init()
        DispatchQueue.global(qos: .utility).async { RecordedVoice.preload() }
    }

    /// - gender: which recorded (Google) voice to use. Plain lines with no character voice use the
    ///   female one; character voices (pitch changed) always use the system voice.
    func say(_ raw: String, voice v: Voice? = nil, slow: Bool? = nil, gender: Gender? = nil) {
        // a lone kanji is read by its usual reading (日 → にち), not guessed by the speech engine
        // a kanji word has its own recording (橋 and 箸 sound different); otherwise read it by its kana
        let text = (KJSimilar.hasKanji(raw) && raw.count > 1 && RecordedVoice.has(raw, role: "f")) ? raw : (KJData.yomi(raw) ?? raw)
        let voice = v ?? .normal
        let s = AppState.shared.settings
        guard s.voiceOn, !text.isEmpty else { return }
        stop()
        let isSlow = slow ?? s.slowVoice
        token += 1
        let t = token
        let vol = Float(s.voiceVolume)
        // recorded natural voice first
        if let v, gender == nil {
            // a character: the female or male recording, pitched / sped to keep the character's feel
            let g: Gender = v.pitch < 0.98 ? .male : .female
            var shift = v.pitch / (g == .male ? 0.85 : 1.15)
            if (0.92...1.1).contains(shift) || (g == .female && v.pitch < 1.25) { shift = 1 }
            let cents = max(-500, min(300, 1200 * log2(shift)))   // big shifts sound robotic
            if let b = RecordedVoice.buffer(text, g),
               AudioManager.shared.playVoiceChecked(b, volume: vol, rate: v.rate * (isSlow ? 0.75 : 1), cents: cents) { return }
        } else {
            let g = gender ?? .female
            if let b = RecordedVoice.buffer(text, g), AudioManager.shared.playVoiceChecked(b, volume: vol, rate: isSlow ? 0.75 : 1) { return }
        }
        // にゃんカナ: only recorded (Google) voices — the other recording, or nothing; never the iPhone voice
        for r in ["f", "m", "n"] {
            if let b = RecordedVoice.buffer(text, role: r), AudioManager.shared.playVoiceChecked(b, volume: vol, rate: isSlow ? 0.75 : 1) { return }
        }
        #if DEBUG
        print("[voice] missing:", text)
        #endif
        if Speaker.recordedOnly { return }
        let u = AVSpeechUtterance(string: text)
        u.voice = enVoice
        if gender == .male { u.voice = manVoice ?? enVoice; if manVoice == nil { u.pitchMultiplier = 0.8 } }
        u.rate = AVSpeechUtteranceDefaultSpeechRate * voice.rate * (isSlow ? 0.7 : 1)
        if gender != .male || manVoice != nil { u.pitchMultiplier = max(0.5, min(2, voice.pitch)) }
        // iPad (or any device where rendering already failed): speak straight away, no waiting
        if Speaker.directOnly {
            u.volume = vol
            speakLive(u)
            return
        }
        // render the line to audio, then play it through our own engine
        let got = Flag()
        let collector = VoiceCollector(target: AudioManager.shared.engineFormat) { buf in
            got.set()
            Task { @MainActor in
                guard t == Speaker.shared.token else { return }
                if UIApplication.shared.applicationState == .background { return }   // the app was closed meanwhile
                if let buf, AudioManager.shared.playVoiceChecked(buf, volume: vol) { return }
                Speaker.directOnly = true
                u.volume = vol
                Speaker.shared.speakLive(u)
            }
        }
        synth.write(u, toBufferCallback: VoiceCollector.handler(collector))
        // nothing came back: speak through the system instead
        later(1.5) { if !got.isSet && t == Speaker.shared.token { Speaker.directOnly = true; u.volume = vol; Speaker.shared.synth.stopSpeaking(at: .immediate); Speaker.shared.speakLive(u) } }
    }

    /// a line recorded for one speaker (にゃんカナ: "n" narrator, "y" Nyan, "s" Sora, or a side character's id).
    /// Falls back to the normal voice when the clip is missing.
    func sayRole(_ text: String, role: String) {
        let s = AppState.shared.settings
        guard s.voiceOn, !text.isEmpty else { return }
        if let b = RecordedVoice.buffer(text, role: role) {
            stop()
            if AudioManager.shared.playVoiceChecked(b, volume: Float(s.voiceVolume), rate: s.slowVoice ? 0.75 : 1) { return }
        }
        say(text, gender: role == "s" ? .male : .female)
    }

    /// Load the voice and the speech engine once at launch, so the first line in a game does not stutter.
    func warmUp() {
        _ = enVoice
        let u = AVSpeechUtterance(string: "はい")
        u.voice = enVoice
        let collector = VoiceCollector(target: AudioManager.shared.engineFormat) { _ in }
        synth.write(u, toBufferCallback: VoiceCollector.handler(collector))
    }

    // MARK: listening tests (TOEIC): several speakers, one after another

    enum Who { case man, woman, narrator }
    enum Gender: String { case female = "f", male = "m" }
    private lazy var manVoice: AVSpeechSynthesisVoice? = pick(.male)
    private lazy var womanVoice: AVSpeechSynthesisVoice? = pick(.female)
    private func pick(_ g: AVSpeechSynthesisVoiceGender) -> AVSpeechSynthesisVoice? {
        let all = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix("ja") && $0.gender == g }
        let us = all.filter { $0.language == "ja-JP" }
        let pool = us.isEmpty ? all : us
        return pool.first { $0.quality == .premium } ?? pool.first { $0.quality == .enhanced } ?? pool.first
    }

    /// Plays the lines in order (always, even when the voice setting is off), then calls `done`.
    func sayLines(_ lines: [(Who, String)], gap: Double = 0.45, done: (() -> Void)? = nil) {
        stop()
        token += 1
        let t = token
        playLine(lines, 0, t, gap, done)
    }

    private func playLine(_ lines: [(Who, String)], _ i: Int, _ t: Int, _ gap: Double, _ done: (() -> Void)?) {
        guard t == token else { return }
        guard i < lines.count else { done?(); return }
        let (who, text) = lines[i]
        // recorded natural voice first (narrator / woman / man)
        let role = who == .man ? "m" : who == .woman ? "f" : "n"
        if let b = RecordedVoice.buffer(text, role: role),
           AudioManager.shared.playVoiceChecked(b, volume: Float(max(0.6, AppState.shared.settings.voiceVolume))) {
            let wait = Double(b.frameLength) / b.format.sampleRate
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64((wait + gap) * 1_000_000_000))
                Speaker.shared.playLine(lines, i + 1, t, gap, done)
            }
            return
        }
        if Speaker.recordedOnly {
            // no recording: skip the line (never the iPhone voice), keep the timing
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64((max(1.0, Double(text.count) * 0.12) + gap) * 1_000_000_000))
                Speaker.shared.playLine(lines, i + 1, t, gap, done)
            }
            return
        }
        let u = AVSpeechUtterance(string: text)
        switch who {
        case .man: u.voice = manVoice ?? enVoice; u.pitchMultiplier = manVoice == nil ? 0.8 : 1
        case .woman: u.voice = womanVoice ?? enVoice; u.pitchMultiplier = womanVoice == nil ? 1.25 : 1
        case .narrator: u.voice = enVoice
        }
        u.rate = AVSpeechUtteranceDefaultSpeechRate * 0.95
        let vol = Float(max(0.6, AppState.shared.settings.voiceVolume))
        let got = Flag()
        // rough length of a line spoken through the system (fallback)
        let est = max(1.0, Double(text.count) * 0.075)
        let collector = VoiceCollector(target: AudioManager.shared.engineFormat) { buf in
            guard got.setOnce() else { return }
            Task { @MainActor in
                guard t == Speaker.shared.token else { return }
                var wait = est
                if let buf, AudioManager.shared.playVoiceChecked(buf, volume: vol) {
                    wait = Double(buf.frameLength) / buf.format.sampleRate
                } else {
                    Speaker.shared.speakLive(u)
                }
                try? await Task.sleep(nanoseconds: UInt64((wait + gap) * 1_000_000_000))
                Speaker.shared.playLine(lines, i + 1, t, gap, done)
            }
        }
        synth.write(u, toBufferCallback: VoiceCollector.handler(collector))
        later(2.0) {
            guard got.setOnce(), t == Speaker.shared.token else { return }
            Speaker.shared.synth.stopSpeaking(at: .immediate)
            Speaker.shared.speakLive(u)
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64((est + gap) * 1_000_000_000))
                Speaker.shared.playLine(lines, i + 1, t, gap, done)
            }
        }
    }

    func stop() {
        token += 1
        synth.stopSpeaking(at: .immediate)
        liveSynth.stopSpeaking(at: .immediate)
        AudioManager.shared.stopVoice()
    }
}

/// thread-safe one-shot flag
nonisolated final class Flag: @unchecked Sendable {
    private let lock = NSLock()
    private var v = false
    var isSet: Bool { lock.lock(); defer { lock.unlock() }; return v }
    func set() { lock.lock(); v = true; lock.unlock() }
    /// true only for the first caller
    func setOnce() -> Bool { lock.lock(); defer { lock.unlock() }; if v { return false }; v = true; return true }
}

/// Collects the speech engine's audio chunks (on its own thread) and hands back one buffer in the engine format.
nonisolated final class VoiceCollector: @unchecked Sendable {
    private let target: AVAudioFormat
    private let done: @Sendable (AVAudioPCMBuffer?) -> Void
    private var chunks: [AVAudioPCMBuffer] = []
    private var finished = false

    init(target: AVAudioFormat, done: @escaping @Sendable (AVAudioPCMBuffer?) -> Void) {
        self.target = target; self.done = done
    }

    static func handler(_ c: VoiceCollector) -> (AVAudioBuffer) -> Void {
        return { b in c.add(b) }
    }

    private func add(_ b: AVAudioBuffer) {
        guard !finished, let pcm = b as? AVAudioPCMBuffer else { return }
        if pcm.frameLength == 0 { finished = true; done(merge()); return }
        // make a float copy at the voice's own rate (no resampling yet, so chunks join cleanly)
        guard let f = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: pcm.format.sampleRate, channels: pcm.format.channelCount, interleaved: false),
              let conv = AVAudioConverter(from: pcm.format, to: f),
              let out = AVAudioPCMBuffer(pcmFormat: f, frameCapacity: pcm.frameLength) else { return }
        try? conv.convert(to: out, from: pcm)
        chunks.append(out)
    }

    private func merge() -> AVAudioPCMBuffer? {
        guard let first = chunks.first else { return nil }
        let total = chunks.reduce(0) { $0 + Int($1.frameLength) }
        guard total > 0, let all = AVAudioPCMBuffer(pcmFormat: first.format, frameCapacity: AVAudioFrameCount(total)) else { return nil }
        let ch = Int(first.format.channelCount)
        var at = 0
        for c in chunks {
            let n = Int(c.frameLength)
            for k in 0..<ch { memcpy(all.floatChannelData![k] + at, c.floatChannelData![k], n * MemoryLayout<Float>.size) }
            at += n
        }
        all.frameLength = AVAudioFrameCount(total)
        // short fade at both ends (no click)
        let fade = min(220, total / 4)
        for k in 0..<ch {
            let p = all.floatChannelData![k]
            for i in 0..<fade { let g = Float(i) / Float(fade); p[i] *= g; p[total - 1 - i] *= g }
        }
        // resample / upmix to the engine format
        guard let conv = AVAudioConverter(from: all.format, to: target),
              let dst = AVAudioPCMBuffer(pcmFormat: target, frameCapacity: AVAudioFrameCount(Double(total) * target.sampleRate / all.format.sampleRate) + 1024) else { return nil }
        var given = false
        conv.convert(to: dst, error: nil) { _, status in
            if given { status.pointee = .endOfStream; return nil }
            given = true; status.pointee = .haveData; return all
        }
        return dst
    }
}

// MARK: - Recorded voices (Google Chirp 3 HD, made beforehand)

/// voice0.pack … voice3.pack hold the clips (Opus in CAF) one after another; voice.idx lists "key pack offset length".
/// key = first 16 hex of SHA1("f|text" or "m|text"). Text keys: the word (kanji and kana), the example sentence,
/// and "w:<id>" / "e:<id>". Missing lines fall back to the system voice.
nonisolated enum RecordedVoice {
    private static let packURLs: [URL?] = (0..<10).map { Bundle.main.url(forResource: "voice\($0)", withExtension: "pack") }
    private static let index: [String: (pack: Int, offset: UInt64, length: Int)] = {
        guard let url = Bundle.main.url(forResource: "voice", withExtension: "idx"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return [:] }
        var out: [String: (Int, UInt64, Int)] = [:]
        out.reserveCapacity(100_000)
        for line in text.split(separator: "\n") {
            let f = line.split(separator: " ")
            guard f.count == 4, let p = Int(f[1]), let o = UInt64(f[2]), let l = Int(f[3]) else { continue }
            out[String(f[0])] = (p, o, l)
        }
        return out
    }()
    static func preload() { _ = index.count }
    static func key(_ role: String, _ text: String) -> String {
        let d = Insecure.SHA1.hash(data: Data("\(role)|\(text)".utf8))
        return String(d.map { String(format: "%02x", $0) }.joined().prefix(16))
    }
    static func has(_ text: String, role: String) -> Bool { index[key(role, text)] != nil }
    @MainActor static func buffer(_ text: String, _ g: Speaker.Gender) -> AVAudioPCMBuffer? { buffer(text, role: g.rawValue) }
    /// the clip in the engine format, or nil ("f" woman, "m" man, "n" narrator)
    @MainActor static func buffer(_ text: String, role: String) -> AVAudioPCMBuffer? {
        guard let e = index[key(role, text)], e.pack < packURLs.count, let packURL = packURLs[e.pack],
              let h = try? FileHandle(forReadingFrom: packURL) else { return nil }
        defer { try? h.close() }
        guard (try? h.seek(toOffset: e.offset)) != nil, let data = try? h.read(upToCount: e.length), data.count == e.length else { return nil }
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("v-\(UUID().uuidString).caf")
        defer { try? FileManager.default.removeItem(at: tmp) }
        guard (try? data.write(to: tmp)) != nil else { return nil }
        return AudioManager.decode(tmp, to: AudioManager.shared.engineFormat)
    }
}
