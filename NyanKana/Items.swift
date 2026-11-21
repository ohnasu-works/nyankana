import Foundation

/// Items the player can hold (max 3). Used by tapping, or by voice: "Nyan, heart!"
enum ItemKind: String, CaseIterable, Identifiable, Codable {
    case heart, bomb, timeStop
    var id: String { rawValue }

    var icon: String {
        switch self { case .heart: "ui_heart|❤️"; case .bomb: "ui_bomb|💣"; case .timeStop: "ui_hourglass|⏳" }
    }
    var name: String {
        switch L10n.current {
        case .ja: switch self { case .heart: "ハート"; case .bomb: "ことばボム"; case .timeStop: "タイムストップ" }
        case .ko: switch self { case .heart: "하트"; case .bomb: "말 폭탄"; case .timeStop: "타임 스톱" }
        case .zhHant: switch self { case .heart: "愛心"; case .bomb: "語言炸彈"; case .timeStop: "時間暫停" }
        default: switch self { case .heart: Tr.text("ハート"); case .bomb: Tr.text("ことばボム"); case .timeStop: Tr.text("タイムストップ") }
        }
    }
    var desc: String {
        switch L10n.current {
        case .ja: switch self { case .heart: "ライフ1回復"; case .bomb: "答えずに|今の敵に|1回分の|ダメージ。|ザコ敵は|それで|助けられる。|ボスには|ハート1つ分|（スコアなし。|正解は|表示される）"; case .timeStop: "6秒間|メーターと|敵が|止まる" }
        case .ko: switch self { case .heart: "라이프 1 회복"; case .bomb: "답하지 않고 지금 적에게 1회분 대미지. 잡몹은 구할 수 있고, 보스는 하트 1개분（점수 없음）"; case .timeStop: "6초 동안 미터와 적이 멈춤" }
        case .zhHant: switch self { case .heart: "恢復1點生命"; case .bomb: "不作答直接對眼前的敵人造成1次傷害。小怪可直接救出，頭目扣1顆心（不計分）"; case .timeStop: "計時條與敵人停止6秒" }
        default: switch self {
            case .heart: Tr.text("ライフ1回復")
            case .bomb: Tr.text("答えずに|今の敵に|1回分の|ダメージ。|ザコ敵は|それで|助けられる。|ボスには|ハート1つ分|（スコアなし。|正解は|表示される）")
            case .timeStop: Tr.text("6秒間|メーターと|敵が|止まる")
            }
        }
    }
    /// what to say in voice mode
    var voiceCommand: String {
        switch self { case .heart: "\"Nyan, heart!\""; case .bomb: "\"Nyan, bomb!\""; case .timeStop: "\"Nyan, time stop!\"" }
    }
    /// words recognised for the voice command (after "Nyan")
    var voiceWords: [String] {
        switch self { case .heart: ["heart", "hart"]; case .bomb: ["bomb", "bom", "bum"]; case .timeStop: ["time stop", "timestop", "stop"] }
    }
}
