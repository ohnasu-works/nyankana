import SceneKit
import UIKit

/// How one stage's street looks: time of day, weather and what lines the pavement.
/// Every normal stage of an area gets a different mix, so the long courses never look the same twice in a row.
struct StageLook {
    enum Time { case day, morning, evening, night, cloudy }
    enum Weather { case clear, petals, rain, leaves, snow, confetti, fireflies, sparkles, bubbles, digital }
    enum Props { case mixed, trees, lamps, flowers }

    var time: Time = .day
    var weather: Weather = .clear
    var props: Props = .mixed
    /// tree colour for .trees (green, cherry pink, autumn orange, snowy white)
    var treeColor: Int = 0x6CC06A
    /// building height multiplier
    var height: Float = 1
    /// lab light colour (Logic Lab is indoors: the light changes instead of the sky)
    var labLight: Int = 0xFFFFFF
    var title: String = ""

    static func of(_ area: Area, _ stage: Int) -> StageLook {
        // mid boss / boss stages fight in their own arena: keep the plain street
        if stage % 10 == 0 { return StageLook() }
        let looks = list(area)
        return looks[(stage - 1) % looks.count]
    }

    private static func make(_ t: Time, _ w: Weather, _ p: Props, tree: Int = 0x6CC06A, h: Float = 1, lab: Int = 0xFFFFFF,
                             _ ja: String, _ ko: String, _ zh: String) -> StageLook {
        StageLook(time: t, weather: w, props: p, treeColor: tree, height: h, labLight: lab, title: T(ja, ko, zh))
    }

    private static func list(_ a: Area) -> [StageLook] {
        switch a {
        case .lv1: return [
            make(.morning, .clear, .mixed, "朝の|通り", "아침 거리", "早晨的街道"),
            make(.day, .petals, .trees, tree: 0xFFB7D5, h: 0.8, "さくら|並木", "벚꽃 가로수길", "櫻花大道"),
            make(.cloudy, .rain, .lamps, "雨の|商店街", "비 오는 상점가", "下雨的商店街"),
            make(.evening, .leaves, .trees, tree: 0xF29A3E, "夕やけの|並木道", "노을 진 가로수길", "夕陽林蔭道"),
            make(.night, .clear, .lamps, h: 1.2, "夜の|町", "밤의 마을", "夜晚的小鎮"),
            make(.day, .snow, .trees, tree: 0xF4F8FF, h: 0.9, "雪の|通学路", "눈 오는 등굣길", "下雪的上學路"),
            make(.day, .clear, .flowers, h: 0.7, "花だんの|ある道", "화단이 있는 길", "有花圃的路"),
        ]
        case .lv2: return [
            make(.day, .clear, .mixed, "未来の|大通り", "미래의 큰길", "未來大道"),
            make(.night, .digital, .lamps, h: 1.3, "ネオンの|夜", "네온의 밤", "霓虹之夜"),
            make(.cloudy, .rain, .lamps, "雨の|ハイウェイ", "비 오는 하이웨이", "下雨的高速路"),
            make(.evening, .sparkles, .mixed, h: 1.2, "夕やけ|タワー街", "노을 타워 거리", "夕陽高塔街"),
            make(.morning, .clear, .trees, tree: 0x7FE0D0, "朝の|エコ通り", "아침의 에코 거리", "早晨的環保街"),
            make(.night, .snow, .lamps, "雪の|サイバー街", "눈 오는 사이버 거리", "下雪的網路街"),
        ]
        case .lv3: return [
            make(.day, .confetti, .flowers, "お祭りの|広場", "축제 광장", "慶典廣場"),
            make(.night, .sparkles, .lamps, "花火の|夜", "불꽃놀이 밤", "煙火之夜"),
            make(.day, .petals, .trees, tree: 0xFFB7D5, "春の|運動会", "봄 운동회", "春季運動會"),
            make(.evening, .confetti, .lamps, "夕やけ|パレード", "노을 퍼레이드", "夕陽遊行"),
            make(.morning, .clear, .mixed, "朝の|スタジアム前", "아침의 경기장 앞", "早晨的體育場前"),
            make(.night, .fireflies, .lamps, "夏祭りの|夜", "여름 축제의 밤", "夏日祭之夜"),
        ]
        case .lv4: return [
            make(.evening, .clear, .mixed, "夕ぐれの|ホテル街", "해 질 녘 호텔 거리", "黃昏的飯店街"),
            make(.day, .bubbles, .flowers, h: 0.8, "泡の|リゾート", "거품 리조트", "泡泡度假村"),
            make(.night, .sparkles, .lamps, h: 1.2, "夜景の|ホテル街", "야경의 호텔 거리", "夜景飯店街"),
            make(.morning, .clear, .trees, tree: 0x5FC46A, "ヤシの木|通り", "야자수 거리", "椰子樹大道"),
            make(.cloudy, .rain, .lamps, "雨の|ホテル街", "비 오는 호텔 거리", "下雨的飯店街"),
            make(.day, .snow, .trees, tree: 0xF4F8FF, "冬の|リゾート", "겨울 리조트", "冬季度假村"),
        ]
        case .lv5: return [
            make(.day, .petals, .flowers, "花ふぶきの|庭", "꽃보라 정원", "花吹雪庭園"),
            make(.night, .fireflies, .lamps, "ホタルの|小道", "반딧불이 오솔길", "螢火蟲小徑"),
            make(.cloudy, .rain, .trees, tree: 0x4FA85A, "雨の|森", "비 오는 숲", "下雨的森林"),
            make(.evening, .leaves, .trees, tree: 0xE8833A, "紅葉の|庭", "단풍 정원", "楓葉庭園"),
            make(.morning, .sparkles, .flowers, "朝つゆの|花畑", "아침 이슬 꽃밭", "晨露花田"),
            make(.day, .snow, .trees, tree: 0xF4F8FF, "雪の|庭園", "눈 덮인 정원", "雪之庭園"),
        ]
        case .lv6: return [
            make(.day, .clear, .mixed, lab: 0xFFFFFF, "研究所の|ろうか", "연구소 복도", "研究所走廊"),
            make(.day, .bubbles, .mixed, lab: 0x9FF0D0, "実験室A", "실험실 A", "實驗室A"),
            make(.day, .sparkles, .lamps, lab: 0xA8C8FF, "電気の|部屋", "전기실", "電氣室"),
            make(.day, .snow, .mixed, lab: 0xCDEBFF, "冷とう|保管庫", "냉동 보관고", "冷凍保管庫"),
            make(.day, .digital, .lamps, lab: 0xFF9A9A, "警報が|鳴る通路", "경보가 울리는 통로", "警報響起的通道"),
            make(.day, .bubbles, .mixed, lab: 0xE0B8FF, "ふしぎな|薬品室", "신비한 약품실", "神奇藥品室"),
        ]
        case .graduation: return [
            make(.day, .sparkles, .mixed, "雲の上の|橋", "구름 위의 다리", "雲上之橋"),
            make(.night, .sparkles, .lamps, "星空の|橋", "별하늘 다리", "星空之橋"),
            make(.day, .snow, .mixed, "雪の|天空橋", "눈 내리는 하늘 다리", "下雪的天空橋"),
            make(.evening, .petals, .mixed, "夕やけの|城門前", "노을 진 성문 앞", "夕陽城門前"),
        ]
        }
    }

    /// The sky for this time of day (the area's own sky in daytime).
    func sky(_ t: WorldTheme) -> (UIColor, UIColor, UIColor) {
        let c = Tex.rgb
        switch time {
        case .day: return (t.skyTop, t.skyBottom, t.fog)
        case .morning: return (c(0x9ED8FF), c(0xFFE9D6), c(0xFDEBDD))
        case .evening: return (c(0x6E4FA8), c(0xFFA36B), c(0xF6C7A6))
        case .night: return (c(0x0F1736), c(0x2C3A6E), c(0x1E2850))
        case .cloudy: return (c(0x7F8AA0), c(0xC9D0DA), c(0xB8C0CC))
        }
    }

    var ambient: CGFloat { time == .night ? 330 : time == .cloudy ? 520 : 650 }
    var sunLight: CGFloat { time == .night ? 180 : time == .evening ? 520 : time == .cloudy ? 380 : 650 }
    var sunColor: UIColor {
        switch time {
        case .evening: return Tex.rgb(0xFFC48A)
        case .night: return Tex.rgb(0x9FB4FF)
        case .morning: return Tex.rgb(0xFFF1DE)
        default: return .white
        }
    }

    // MARK: weather

    /// Particles that fall (or float) around the camera.
    func particles() -> SCNParticleSystem? {
        let p = SCNParticleSystem()
        p.emitterShape = SCNBox(width: 26, height: 1, length: 30, chamferRadius: 0)
        p.birthLocation = .volume
        p.particleLifeSpan = 5
        p.blendMode = .alpha
        p.isAffectedByGravity = false
        p.particleColor = .white
        p.emittingDirection = SCNVector3(0, -1, 0)
        p.spreadingAngle = 12
        switch weather {
        case .clear: return nil
        case .petals:
            p.particleImage = StageLook.dot(0xFFB7D5, petal: true); p.birthRate = 40; p.particleSize = 0.16
            p.particleVelocity = 1.4; p.particleVelocityVariation = 0.6; p.acceleration = SCNVector3(0.3, -0.5, 0)
            p.particleAngularVelocity = 90; p.particleAngularVelocityVariation = 180
        case .rain:
            p.particleImage = StageLook.streak(); p.birthRate = 260; p.particleSize = 0.12
            p.particleVelocity = 14; p.particleVelocityVariation = 2; p.particleLifeSpan = 1.4
            p.stretchFactor = 0.08
        case .leaves:
            p.particleImage = StageLook.dot(0xF29A3E, petal: true); p.birthRate = 30; p.particleSize = 0.2
            p.particleVelocity = 1.2; p.particleVelocityVariation = 0.6; p.acceleration = SCNVector3(-0.4, -0.6, 0)
            p.particleAngularVelocity = 120; p.particleAngularVelocityVariation = 200
            p.particleColorVariation = SCNVector4(0.08, 0.2, 0.2, 0)
        case .snow:
            p.particleImage = StageLook.dot(0xFFFFFF, petal: false); p.birthRate = 120; p.particleSize = 0.09
            p.particleSizeVariation = 0.05; p.particleVelocity = 1.6; p.particleVelocityVariation = 0.5; p.particleLifeSpan = 7
        case .confetti:
            p.particleImage = StageLook.square(); p.birthRate = 70; p.particleSize = 0.12
            p.particleVelocity = 2; p.particleVelocityVariation = 1; p.particleColor = Tex.rgb(0xFF7A93)
            p.particleColorVariation = SCNVector4(1, 0.5, 0.2, 0)
            p.particleAngularVelocity = 200; p.particleAngularVelocityVariation = 300
        case .fireflies:
            p.particleImage = StageLook.glow(0xFFF27A); p.birthRate = 18; p.particleSize = 0.12; p.blendMode = .additive
            p.particleVelocity = 0.4; p.particleVelocityVariation = 0.4; p.particleLifeSpan = 6; p.spreadingAngle = 180
            p.emitterShape = SCNBox(width: 20, height: 5, length: 26, chamferRadius: 0)
            p.particleColorVariation = SCNVector4(0, 0, 0, 0.5)
        case .sparkles:
            p.particleImage = StageLook.glow(0xFFFFFF); p.birthRate = 30; p.particleSize = 0.1; p.blendMode = .additive
            p.particleVelocity = 0.5; p.particleVelocityVariation = 0.5; p.spreadingAngle = 180
            p.particleColor = Tex.rgb(0xFFE7A0); p.particleColorVariation = SCNVector4(0.3, 0.3, 0, 0)
            p.emitterShape = SCNBox(width: 24, height: 8, length: 28, chamferRadius: 0)
        case .bubbles:
            p.particleImage = StageLook.bubble(); p.birthRate = 22; p.particleSize = 0.22; p.particleSizeVariation = 0.12
            p.particleVelocity = 0.9; p.particleVelocityVariation = 0.4; p.acceleration = SCNVector3(0, 1.2, 0)
            p.emittingDirection = SCNVector3(0, 1, 0)
            p.emitterShape = SCNBox(width: 22, height: 1, length: 26, chamferRadius: 0)
        case .digital:
            p.particleImage = StageLook.square(); p.birthRate = 45; p.particleSize = 0.08; p.blendMode = .additive
            p.particleVelocity = 2.4; p.particleVelocityVariation = 0.8
            p.particleColor = Tex.rgb(0x5CF2FF); p.particleColorVariation = SCNVector4(0.15, 0.3, 0, 0)
        }
        return p
    }

    /// where the emitter sits relative to the camera (bubbles rise from below, the rest fall from above)
    var emitterY: Float { weather == .bubbles ? -1.5 : weather == .fireflies || weather == .sparkles ? 2 : 9 }

    private static func dot(_ hex: Int, petal: Bool) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 32, height: 32)).image { _ in
            Tex.rgb(hex).setFill()
            if petal { UIBezierPath(ovalIn: CGRect(x: 4, y: 9, width: 24, height: 14)).fill() }
            else { UIBezierPath(ovalIn: CGRect(x: 4, y: 4, width: 24, height: 24)).fill() }
        }
    }
    private static func streak() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 8, height: 64)).image { _ in
            UIColor(red: 0.75, green: 0.85, blue: 1, alpha: 0.7).setFill()
            UIBezierPath(roundedRect: CGRect(x: 2, y: 0, width: 4, height: 64), cornerRadius: 2).fill()
        }
    }
    private static func square() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 16, height: 16)).image { _ in UIColor.white.setFill(); UIRectFill(CGRect(x: 0, y: 0, width: 16, height: 16)) }
    }
    private static func glow(_ hex: Int) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 32, height: 32)).image { ctx in
            let cs = CGColorSpaceCreateDeviceRGB()
            let c = Tex.rgb(hex)
            let g = CGGradient(colorsSpace: cs, colors: [c.cgColor, c.withAlphaComponent(0).cgColor] as CFArray, locations: [0, 1])!
            ctx.cgContext.drawRadialGradient(g, startCenter: CGPoint(x: 16, y: 16), startRadius: 0, endCenter: CGPoint(x: 16, y: 16), endRadius: 16, options: [])
        }
    }
    private static func bubble() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 32, height: 32)).image { _ in
            UIColor(red: 0.85, green: 0.95, blue: 1, alpha: 0.35).setFill()
            UIBezierPath(ovalIn: CGRect(x: 2, y: 2, width: 28, height: 28)).fill()
            UIColor.white.withAlphaComponent(0.9).setStroke()
            let b = UIBezierPath(ovalIn: CGRect(x: 3, y: 3, width: 26, height: 26)); b.lineWidth = 2; b.stroke()
            UIColor.white.setFill(); UIBezierPath(ovalIn: CGRect(x: 8, y: 7, width: 7, height: 5)).fill()
        }
    }
}
