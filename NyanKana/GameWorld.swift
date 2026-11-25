import SceneKit
import UIKit
import simd
import CoreImage

/// The 2.5D street (SceneKit). The street starts gray; every rescued Gobble brings colour back.
/// The camera walks along a "line" (origin + heading). A fork builds a T junction with streets
/// to BOTH sides, so whichever way the player turns there are buildings on both sides.
final class GameWorld {
    let scene = SCNScene()
    let rig = SCNNode()          // position + yaw
    let cam = SCNNode()          // pitch, height
    private let foeRoot = SCNNode()

    // street line
    private var lineOrigin = SIMD3<Float>(0, 0, 0)
    private var heading: Float = 0
    private var travelled: Float = 0
    private var builtUntil: Float = -12
    private var lineID = 0
    private var nextLineID = 1
    private var forkAt: Float?            // junction distance on the current line
    private var forkBranches: [Bool: Int] = [:]   // left? -> line id
    private var forkCenter = SIMD3<Float>(0, 0, 0)

    private struct Slot { let node: SCNNode; let line: Int }
    private var slots: [Slot] = []

    private struct Paint { let mats: [SCNMaterial]; let target: UIColor; let node: SCNNode; var on: Bool; let folk: SCNNode? }
    private var paints: [Paint] = []

    private var foes: [UUID: (holder: SCNNode, body: SCNNode, tint: UIColor)] = [:]
    /// where each foe stands after walking in (attacks always return here, so they never end up somewhere else)
    private var homes: [UUID: SCNVector3] = [:]
    /// throwers wait far back; this is where they walk to after the throw
    private var nearHomes: [UUID: SCNVector3] = [:]

    private let slotLen: Float = 6
    private let roadHalf: Float = 4
    static let gray = UIColor(red: 0.62, green: 0.63, blue: 0.69, alpha: 1)
    private static let palette: [Int] = [0xFF9CC8, 0x7EE3C3, 0xFFE07A, 0x8FD3FF, 0xFFB978, 0xC3A6FF, 0xB8EB8A, 0xFF9E9E]

    let theme: WorldTheme
    /// this stage's time of day, weather and pavement things
    let look: StageLook
    /// width / height of the 3D view (set by the view), used to crop the arena pictures
    var viewAspect: CGFloat = 0.9
    private var skylineNode: SCNNode?
    private var streetBackground: Any?
    private(set) var inArena = false

    init(area: Area = .lv1, stage: Int = 1) {
        look = StageLook.of(area, stage)
        var th = WorldTheme.of(area)
        if th.side == .city {
            th.heights = (th.heights.lowerBound * look.height)...(th.heights.upperBound * look.height)
        }
        if th.side != .lab {
            let (top, bottom, fog) = look.sky(th)
            th.skyTop = top; th.skyBottom = bottom; th.fog = fog
        }
        theme = th
        scene.background.contents = Tex.sky(theme.skyTop, theme.skyBottom)
        scene.fogStartDistance = theme.fogStart
        scene.fogEndDistance = theme.fogEnd
        scene.fogColor = theme.fog

        let camera = SCNCamera()
        camera.fieldOfView = 55
        camera.zNear = 0.1
        camera.zFar = 260
        cam.camera = camera
        cam.position = SCNVector3(0, 2.3, 0)
        cam.eulerAngles.x = -0.09
        rig.addChildNode(cam)
        scene.rootNode.addChildNode(rig)
        scene.rootNode.addChildNode(foeRoot)

        let amb = SCNNode(); amb.light = SCNLight(); amb.light!.type = .ambient; amb.light!.intensity = look.ambient
        if theme.side == .lab { amb.light!.color = Tex.rgb(look.labLight) }
        scene.rootNode.addChildNode(amb)
        let sun = SCNNode(); sun.light = SCNLight(); sun.light!.type = .directional; sun.light!.intensity = look.sunLight
        sun.light!.color = look.sunColor
        sun.eulerAngles = SCNVector3(-0.9, 0.6, 0)
        scene.rootNode.addChildNode(sun)

        // far skyline rides with the camera
        if theme.skyline, let img = UIImage(named: "skyline") {
            defer { skylineNode = rig.childNodes.last }
            let w: CGFloat = 300, h = w * img.size.height / max(1, img.size.width)
            let p = SCNPlane(width: w, height: h)
            p.firstMaterial = constantMaterial(img)
            let n = SCNNode(geometry: p)
            n.position = SCNVector3(0, Float(h) / 2 - 6, -175)
            n.renderingOrder = -10
            rig.addChildNode(n)
        }
        // weather rides with the camera
        if let ps = look.particles() {
            let pn = SCNNode()
            pn.position = SCNVector3(0, look.emitterY, -12)
            pn.addParticleSystem(ps)
            rig.addChildNode(pn)
        }
        ensureBuilt()
    }

    // MARK: - vectors

    private func fwd(_ h: Float) -> SIMD3<Float> { SIMD3(-sin(h), 0, -cos(h)) }
    private func side(_ h: Float) -> SIMD3<Float> { SIMD3(cos(h), 0, -sin(h)) }
    private var camPos: SIMD3<Float> { lineOrigin + fwd(heading) * travelled }

    /// world point relative to the camera: ahead / right / up
    func point(ahead: Float, right: Float = 0, up: Float = 0) -> SIMD3<Float> {
        camPos + fwd(heading) * ahead + side(heading) * right + SIMD3(0, up, 0)
    }

    // MARK: - building the street

    private func ensureBuilt() {
        let limit = forkAt.map { $0 - slotLen } ?? (travelled + 110)
        while builtUntil < min(limit, travelled + 110) {
            addSlot(line: lineID, origin: lineOrigin, heading: heading, d: builtUntil, buildings: true)
            builtUntil += slotLen
        }
    }

    private func addSlot(line: Int, origin: SIMD3<Float>, heading h: Float, d: Float, buildings: Bool) {
        let n = SCNNode()
        n.simdPosition = origin + fwd(h) * d
        n.eulerAngles.y = h
        let road = SCNNode(geometry: plane(CGFloat(roadHalf * 2), CGFloat(slotLen), theme.road, lit: false))
        road.eulerAngles.x = -.pi / 2
        road.position = SCNVector3(0, 0, -slotLen / 2)
        n.addChildNode(road)
        for s: Float in [-1, 1] {
            if theme.side == .rails {
                // stone bridge railing, nothing beyond it but sky
                let rail = SCNBox(width: 0.5, height: 0.9, length: CGFloat(slotLen), chamferRadius: 0.06)
                rail.firstMaterial?.diffuse.contents = theme.walk
                let rn = SCNNode(geometry: rail)
                rn.position = SCNVector3(s * (roadHalf + 0.25), 0.45, -slotLen / 2)
                n.addChildNode(rn)
                let post = SCNBox(width: 0.7, height: 1.3, length: 0.7, chamferRadius: 0.08)
                post.firstMaterial?.diffuse.contents = theme.walk
                let pn = SCNNode(geometry: post)
                pn.position = SCNVector3(s * (roadHalf + 0.25), 0.65, -0.2)
                n.addChildNode(pn)
                if buildings { addSkyDecor(to: n, side: s) }
                continue
            }
            let walk = SCNBox(width: 2.2, height: 0.16, length: CGFloat(slotLen), chamferRadius: 0)
            walk.firstMaterial?.diffuse.contents = theme.walk
            let wn = SCNNode(geometry: walk)
            wn.position = SCNVector3(s * (roadHalf + 1.1), 0.08, -slotLen / 2)
            n.addChildNode(wn)
            if buildings { addBuilding(to: n, side: s) }
        }
        if buildings { addOverhead(to: n, d: d) }
        scene.rootNode.addChildNode(n)
        slots.append(Slot(node: n, line: line))
    }

    private func addBuilding(to n: SCNNode, side s: Float) {
        let h = Float.random(in: theme.heights)
        let depth: CGFloat = theme.side == .hedges ? 1.6 : 5
        let box = SCNBox(width: depth, height: CGFloat(h), length: CGFloat(theme.side == .lab ? slotLen : slotLen - 0.5), chamferRadius: theme.side == .hedges ? 0.5 : 0.15)
        let m = SCNMaterial()
        m.diffuse.contents = theme.facade
        m.diffuse.wrapS = .repeat; m.diffuse.wrapT = .repeat
        m.diffuse.contentsTransform = SCNMatrix4MakeScale(theme.side == .hedges ? 2 : 1, h / 5, 1)
        m.multiply.contents = GameWorld.gray
        if look.time == .night && theme.side == .city {
            // lit windows at night
            m.emission.contents = theme.facade
            m.emission.wrapS = .repeat; m.emission.wrapT = .repeat
            m.emission.contentsTransform = m.diffuse.contentsTransform
            m.emission.intensity = 0.45
        }
        box.materials = [m]
        let b = SCNNode(geometry: box)
        let x = s * (roadHalf + 2.2 + Float(depth) / 2)
        b.position = SCNVector3(x, h / 2, -slotLen / 2)
        n.addChildNode(b)
        var mats = [m]

        // shop front on some buildings (faces the road)
        if theme.shops, Int.random(in: 0..<3) == 0, let img = UIImage(named: "shops_\(Int.random(in: 0..<4))") {
            let w: CGFloat = 4.6, hh = min(4, w * img.size.height / max(1, img.size.width))
            let pm = constantMaterial(img); pm.multiply.contents = GameWorld.gray
            let p = SCNNode(geometry: { let g = SCNPlane(width: w, height: hh); g.firstMaterial = pm; return g }())
            p.position = SCNVector3(s * (roadHalf + 2.2 - 0.03), Float(hh) / 2 + 0.16, -slotLen / 2)
            p.eulerAngles.y = s > 0 ? -.pi / 2 : .pi / 2
            n.addChildNode(p)
            mats.append(pm)
        }
        // street props (trees, benches, signs)
        if Int.random(in: 0..<5) < 2 {
            let names = (0..<8).map { "props_\($0)" } + (0..<6).map { "park_\($0)" }
            if let img = UIImage(named: names.randomElement()!) {
                let hh: CGFloat = 1.7, w = hh * img.size.width / max(1, img.size.height)
                let pm = constantMaterial(img); pm.multiply.contents = GameWorld.gray
                let p = billboard(SCNPlane(width: w, height: hh), pm)
                p.position = SCNVector3(s * (roadHalf + 1.2), Float(hh) / 2 + 0.16, -Float.random(in: 1...5))
                n.addChildNode(p)
                mats.append(pm)
            }
        }
        addLookProps(to: n, side: s)
        // townsfolk appear when colour returns
        var folk: SCNNode?
        if Int.random(in: 0..<4) == 0, let img = UIImage(named: "folks_\(Int.random(in: 0..<8))") {
            let hh: CGFloat = 1.5, w = hh * img.size.width / max(1, img.size.height)
            let f = billboard(SCNPlane(width: w, height: hh), constantMaterial(img))
            f.position = SCNVector3(s * (roadHalf + 0.9), Float(hh) / 2 + 0.16, -Float.random(in: 1...5))
            f.opacity = 0
            n.addChildNode(f)
            folk = f
        }
        let c = theme.palette.randomElement()!
        paints.append(Paint(mats: mats, target: c, node: b, on: false, folk: folk))
    }

    /// Street lamps, trees or flower beds along the pavement, depending on the stage.
    private func addLookProps(to n: SCNNode, side s: Float) {
        guard theme.side == .city || theme.side == .hedges else { return }
        let edge = s * (roadHalf + (theme.side == .hedges ? 0.6 : 1.7))
        switch look.props {
        case .mixed: return
        case .lamps:
            let pole = SCNCylinder(radius: 0.07, height: 3.2)
            pole.firstMaterial?.diffuse.contents = UIColor(red: 0.25, green: 0.26, blue: 0.33, alpha: 1)
            let pn = SCNNode(geometry: pole); pn.position = SCNVector3(edge, 1.6 + 0.16, -slotLen / 2)
            n.addChildNode(pn)
            let bulb = SCNSphere(radius: 0.3)
            let bm = SCNMaterial(); bm.lightingModel = .constant
            bm.diffuse.contents = look.time == .night || look.time == .evening ? Tex.rgb(0xFFE9A6) : Tex.rgb(0xFFF7E0)
            bulb.materials = [bm]
            let bn = SCNNode(geometry: bulb); bn.position = SCNVector3(edge, 3.3 + 0.16, -slotLen / 2)
            n.addChildNode(bn)
        case .trees:
            guard Int.random(in: 0..<10) < 7 else { return }
            let trunk = SCNCylinder(radius: 0.14, height: 1.6)
            trunk.firstMaterial?.diffuse.contents = Tex.rgb(0x8A5A3C)
            let z = -Float.random(in: 1...5)
            let tn = SCNNode(geometry: trunk); tn.position = SCNVector3(edge, 0.8 + 0.16, z)
            n.addChildNode(tn)
            let crown = SCNSphere(radius: CGFloat.random(in: 0.9...1.2)); crown.segmentCount = 12
            let cm = SCNMaterial(); cm.diffuse.contents = UIColor.white; cm.multiply.contents = GameWorld.gray
            crown.materials = [cm]
            let cn = SCNNode(geometry: crown); cn.position = SCNVector3(edge, 2.3 + 0.16, z)
            n.addChildNode(cn)
            paints.append(Paint(mats: [cm], target: Tex.rgb(look.treeColor), node: cn, on: false, folk: nil))
        case .flowers:
            guard Int.random(in: 0..<10) < 6 else { return }
            let bed = SCNBox(width: 1.1, height: 0.35, length: 2.2, chamferRadius: 0.1)
            bed.firstMaterial?.diffuse.contents = Tex.rgb(0x9C7458)
            let z = -Float.random(in: 1.5...4.5)
            let bn = SCNNode(geometry: bed); bn.position = SCNVector3(edge, 0.33, z)
            n.addChildNode(bn)
            let cols = [0xFF7A93, 0xFFD23F, 0xB18CFF, 0xFFFFFF, 0xFF9E5E]
            for k in 0..<5 {
                let f = SCNSphere(radius: 0.2); f.segmentCount = 8
                let fm = SCNMaterial(); fm.diffuse.contents = UIColor.white; fm.multiply.contents = GameWorld.gray
                f.materials = [fm]
                let fn = SCNNode(geometry: f)
                fn.position = SCNVector3(edge + Float.random(in: -0.3...0.3), 0.62, z - 0.9 + Float(k) * 0.45)
                n.addChildNode(fn)
                paints.append(Paint(mats: [fm], target: Tex.rgb(cols[k % cols.count]), node: fn, on: false, folk: nil))
            }
        }
    }

    /// Things hanging over the road: festival bunting (plaza) and rose arches (garden).
    private func addOverhead(to n: SCNNode, d: Float) {
        let k = Int((d / slotLen).rounded())
        if theme.bunting && k % 2 == 0 {
            let g = SCNPlane(width: CGFloat(roadHalf * 2 + 4), height: 1.2)
            g.firstMaterial = constantMaterial(Tex.bunting)
            g.firstMaterial?.isDoubleSided = true
            let b = SCNNode(geometry: g)
            b.position = SCNVector3(0, 6.2, -slotLen / 2)
            n.addChildNode(b)
        }
        if theme.arches && k % 2 == 1 {
            let t = SCNTorus(ringRadius: CGFloat(roadHalf + 0.9), pipeRadius: 0.22)
            let m = SCNMaterial(); m.diffuse.contents = Tex.roses; m.diffuse.wrapS = .repeat; m.diffuse.wrapT = .repeat
            m.diffuse.contentsTransform = SCNMatrix4MakeScale(8, 1, 1)
            m.multiply.contents = GameWorld.gray
            t.materials = [m]
            let a = SCNNode(geometry: t)
            a.eulerAngles.x = .pi / 2
            a.position = SCNVector3(0, 0, -slotLen / 2)
            n.addChildNode(a)
            paints.append(Paint(mats: [m], target: UIColor(red: 1, green: 0.75, blue: 0.85, alpha: 1), node: a, on: false, folk: nil))
        }
        if theme.side == .lab {
            // ceiling beams with lights
            let beam = SCNBox(width: CGFloat(roadHalf * 2 + 4.4), height: 0.35, length: 0.6, chamferRadius: 0)
            let m = SCNMaterial(); m.diffuse.contents = UIColor(white: 0.85, alpha: 1); m.multiply.contents = GameWorld.gray
            beam.materials = [m]
            let bn = SCNNode(geometry: beam)
            bn.position = SCNVector3(0, 7.2, -slotLen / 2)
            n.addChildNode(bn)
            paints.append(Paint(mats: [m], target: UIColor(red: 0.7, green: 0.95, blue: 1, alpha: 1), node: bn, on: false, folk: nil))
        }
    }

    /// Clouds and floating rocks around the sky bridge.
    private func addSkyDecor(to n: SCNNode, side s: Float) {
        if Int.random(in: 0..<2) == 0 {
            let w = CGFloat.random(in: 6...12)
            let c = billboard(SCNPlane(width: w, height: w * 0.45), constantMaterial(Tex.cloud))
            c.position = SCNVector3(s * Float.random(in: 8...18), Float.random(in: -6 ... -2), -Float.random(in: 0...6))
            n.addChildNode(c)
        }
        if Int.random(in: 0..<5) == 0 {
            let r = SCNSphere(radius: CGFloat.random(in: 0.6...1.6)); r.segmentCount = 7
            let m = SCNMaterial(); m.diffuse.contents = UIColor(red: 0.55, green: 0.5, blue: 0.6, alpha: 1)
            r.materials = [m]
            let rn = SCNNode(geometry: r)
            rn.position = SCNVector3(s * Float.random(in: 9...16), Float.random(in: 2...8), -Float.random(in: 0...6))
            rn.runAction(.repeatForever(.sequence([.moveBy(x: 0, y: 0.5, z: 0, duration: 1.6), .moveBy(x: 0, y: -0.5, z: 0, duration: 1.6)])))
            n.addChildNode(rn)
        }
    }

    /// Boss / mid boss battles happen in their own place: the street hides and an arena picture fills the view.
    func showArena(_ name: String) {
        guard !inArena, let img = UIImage(named: name) else { return }
        inArena = true
        streetBackground = scene.background.contents
        scene.background.contents = Tex.crop(img, aspect: viewAspect)
        for s in slots { s.node.isHidden = true }
        skylineNode?.isHidden = true
    }

    func hideArena() {
        guard inArena else { return }
        inArena = false
        scene.background.contents = streetBackground ?? Tex.sky(theme.skyTop, theme.skyBottom)
        for s in slots { s.node.isHidden = false }
        skylineNode?.isHidden = false
    }

    /// Bring colour back to the nearest gray buildings ahead.
    func restore(_ n: Int) {
        let p = camPos, f = fwd(heading)
        let cands = paints.indices.filter { i in
            guard !paints[i].on else { return false }
            let d = simd_dot(paints[i].node.simdWorldPosition - p, f)
            return d > 13 && d < 75   // only what is on screen
        }.sorted { simd_dot(paints[$0].node.simdWorldPosition - p, f) < simd_dot(paints[$1].node.simdWorldPosition - p, f) }
        for i in cands.prefix(n * 5) {
            paints[i].on = true
            let mats = paints[i].mats, target = paints[i].target, folk = paints[i].folk
            Task { @MainActor in
                for step in 1...12 {
                    let t = CGFloat(step) / 12
                    for (k, m) in mats.enumerated() { m.multiply.contents = GameWorld.mix(GameWorld.gray, k == 0 ? target : .white, t) }
                    folk?.opacity = t
                    try? await Task.sleep(nanoseconds: 40_000_000)
                }
            }
            paints[i].node.runAction(.sequence([.scale(to: 1.06, duration: 0.15), .scale(to: 1, duration: 0.25)]))
        }
    }

    static func mix(_ a: UIColor, _ b: UIColor, _ t: CGFloat) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0, r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        a.getRed(&r1, green: &g1, blue: &b1, alpha: &a1); b.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return UIColor(red: r1 + (r2 - r1) * t, green: g1 + (g2 - g1) * t, blue: b1 + (b2 - b1) * t, alpha: 1)
    }

    /// Prepare a T junction `distance` ahead of the camera, with streets on both sides.
    func prepareFork(distance: Float) {
        let J = (ceil((travelled + distance) / slotLen)) * slotLen
        forkAt = J
        // drop anything already built past the junction
        for s in slots where s.line == lineID {
            let d = simd_dot(s.node.simdPosition - lineOrigin, fwd(heading))
            if d >= J - slotLen - 0.01 { s.node.removeFromParentNode() }
        }
        slots.removeAll { $0.node.parent == nil }
        builtUntil = min(builtUntil, J - slotLen)
        ensureBuilt()
        addSlot(line: lineID, origin: lineOrigin, heading: heading, d: J - slotLen, buildings: false)
        builtUntil = J

        // crossing square + wall straight ahead
        let center = lineOrigin + fwd(heading) * (J + roadHalf)
        forkCenter = center
        let sq = SCNNode(geometry: plane(CGFloat(roadHalf * 2), CGFloat(roadHalf * 2), theme.square, lit: false))
        sq.eulerAngles = SCNVector3(-Float.pi / 2, heading, 0)
        sq.simdPosition = center + SIMD3(0, 0.001, 0)
        scene.rootNode.addChildNode(sq)
        slots.append(Slot(node: sq, line: lineID))
        let wallH: Float = 9
        let wall = SCNBox(width: CGFloat(roadHalf * 2 + 4.4), height: CGFloat(wallH), length: 5, chamferRadius: 0.15)
        let wm = SCNMaterial(); wm.diffuse.contents = theme.facade; wm.diffuse.wrapS = .repeat; wm.diffuse.wrapT = .repeat
        wm.diffuse.contentsTransform = SCNMatrix4MakeScale(2, wallH / 5, 1); wm.multiply.contents = GameWorld.gray
        wall.materials = [wm]
        let wn = SCNNode(geometry: wall)
        wn.simdPosition = center + fwd(heading) * (roadHalf + 2.2 + 2.5) + SIMD3(0, wallH / 2, 0)
        wn.eulerAngles.y = heading
        scene.rootNode.addChildNode(wn)
        slots.append(Slot(node: wn, line: lineID))
        paints.append(Paint(mats: [wm], target: UIColor(red: 1, green: 0.85, blue: 0.5, alpha: 1), node: wn, on: false, folk: nil))

        for left in [true, false] {
            let id = nextLineID; nextLineID += 1
            forkBranches[left] = id
            let h = heading + (left ? Float.pi / 2 : -Float.pi / 2)
            var d: Float = roadHalf
            while d < roadHalf + slotLen * 11 {
                addSlot(line: id, origin: center, heading: h, d: d, buildings: true)
                d += slotLen
            }
        }
    }

    /// Walk to the junction and turn. Returns how long it takes.
    @discardableResult
    func takeFork(left: Bool, fast: Bool) -> Double {
        guard let J = forkAt, let id = forkBranches[left] else { return 0 }
        let t1 = Double(max(0.6, (J + roadHalf - travelled) / 9)) * (fast ? 0.4 : 1)
        let t2 = 0.8 * (fast ? 0.5 : 1)
        let newH = heading + (left ? Float.pi / 2 : -Float.pi / 2)
        let into = forkCenter + fwd(newH) * 3
        let a1 = SCNAction.move(to: SCNVector3(forkCenter), duration: t1); a1.timingMode = .easeInEaseOut
        let turn = SCNAction.rotateTo(x: 0, y: CGFloat(newH), z: 0, duration: t2, usesShortestUnitArc: true)
        let a2 = SCNAction.group([turn, .move(to: SCNVector3(into), duration: t2)]); a2.timingMode = .easeInEaseOut
        rig.runAction(.sequence([a1, a2]))
        cam.runAction(bobAction(duration: t1))

        // the street state jumps to the new line; nodes catch up through the actions above
        let other = forkBranches[!left]
        lineOrigin = forkCenter; heading = newH; travelled = 3
        lineID = id; builtUntil = roadHalf + slotLen * 11
        forkAt = nil; forkBranches = [:]
        // the street not taken disappears once we have turned away from it
        let drop = slots.filter { $0.line == other }.map(\.node)
        later(t1 + t2 + 0.3) { drop.forEach { $0.removeFromParentNode() } }
        slots.removeAll { $0.line == other }
        return t1 + t2
    }

    /// Walk forward. Returns the duration.
    @discardableResult
    func walk(_ distance: Float, duration: Double) -> Double {
        var dist = distance
        if let J = forkAt { dist = min(dist, max(0, J - 8 - travelled)) }
        travelled += dist
        ensureBuilt()
        let a = SCNAction.move(to: SCNVector3(camPos), duration: duration)
        a.timingMode = .easeInEaseOut
        rig.runAction(a)
        cam.runAction(bobAction(duration: duration))
        cleanup()
        return duration
    }

    private func bobAction(duration: Double) -> SCNAction {
        let steps = max(1, Int(duration / 0.32))
        let up = SCNAction.moveBy(x: 0, y: 0.09, z: 0, duration: 0.16)
        let one = SCNAction.sequence([up, up.reversed()])
        return .repeat(one, count: steps)
    }

    private func cleanup() {
        let p = camPos
        for s in slots where simd_distance(s.node.simdWorldPosition, p) > 140 { s.node.removeFromParentNode() }
        slots.removeAll { $0.node.parent == nil }
        let root = scene.rootNode
        paints.removeAll { $0.node.parent == nil || ($0.node.parent !== root && $0.node.parent?.parent == nil) }
    }

    func shake(_ amount: Float = 0.25) {
        let a = SCNAction.sequence((0..<6).map { i in
            let s: CGFloat = CGFloat(amount) * (i % 2 == 0 ? 1 : -1) * CGFloat(1 - Float(i) / 6)
            return SCNAction.moveBy(x: s, y: s * 0.4, z: 0, duration: 0.035)
        } + [SCNAction.move(to: SCNVector3(0, 2.3, 0), duration: 0.05)])
        cam.runAction(a, forKey: "shake")
    }

    // MARK: - enemies

    /// Spawn an enemy. index/count place pack members side by side.
    /// colour-variant picture: hue turned half way round
    static func hueShift(_ img: UIImage?) -> UIImage? {
        guard let img, let ci = CIImage(image: img), let f = CIFilter(name: "CIHueAdjust") else { return img }
        f.setValue(ci, forKey: kCIInputImageKey)
        f.setValue(Float.pi * 0.9, forKey: kCIInputAngleKey)
        guard let out = f.outputImage, let cg = CIContext().createCGImage(out, from: out.extent) else { return img }
        return UIImage(cgImage: cg, scale: img.scale, orientation: img.imageOrientation)
    }

    func spawn(id: UUID, image: String, kind: Foe.Kind, path: EnemyPath, index: Int, count: Int, item: ItemKind?, fast: Bool, shiny: Bool = false, thrower: Bool = false) {
        let img = shiny ? GameWorld.hueShift(UIImage(named: image)) : UIImage(named: image)
        let hh: CGFloat = kind == .boss ? 4.9 : kind == .mid ? 4.1 : kind == .event ? 3.4 : kind == .kidnap ? 2.8 : kind == .rare ? 1.45 : 1.9
        let w = hh * (img.map { $0.size.width / max(1, $0.size.height) } ?? 1)
        let m = constantMaterial(img)
        let tint: UIColor = kind == .bonus ? UIColor(red: 1, green: 0.86, blue: 0.35, alpha: 1) : .white
        m.multiply.contents = tint
        let body = SCNNode(geometry: { let g = SCNPlane(width: w, height: hh); g.firstMaterial = m; return g }())
        if kind == .boss || kind == .mid || kind == .event || kind == .kidnap {
            // never let the road or buildings cut the big ones (their feet dip below the road while they move)
            m.readsFromDepthBuffer = false
            body.renderingOrder = 50
        }
        let holder = SCNNode()
        let bb = SCNBillboardConstraint(); bb.freeAxes = .Y
        holder.constraints = [bb]
        holder.addChildNode(body)
        holder.name = id.uuidString
        body.name = id.uuidString

        let station: Float = kind == .boss ? 9.5 : kind == .mid ? 9.5 : kind == .event ? 8.5 : kind == .kidnap ? 8.0 : 7.5
        // three in a row: a little closer together and a little further back, so the outer two never get cut by the screen edge
        let spread: Float = count >= 3 ? 2.0 : 1.8
        let x = count > 1 ? (Float(index) - Float(count - 1) / 2) * spread * 1.15 : 0
        let y: Float = kind == .boss ? 2.95 : kind == .mid ? 2.45 : kind == .event ? 2.1 : kind == .kidnap ? 1.8 : 1.6
        let near = point(ahead: station + (count >= 3 ? 2.5 : 0) + Float(index % 2) * 0.6, right: x, up: y)
        // a thrower pops out of purple smoke far down the street and throws from there (it walks in afterwards)
        let farSpot = point(ahead: 19, right: x * 1.2, up: 1.5)
        let to = thrower ? farSpot : near
        let from: SIMD3<Float>
        switch (kind, path) {
        case (.boss, _), (.mid, _): from = point(ahead: 45, right: 0, up: 12)
        case (.event, _): from = point(ahead: 8.5, right: 0, up: 2.1)
        case (.kidnap, _): from = point(ahead: 16, right: 11, up: 1.8)
        case (.rare, _): from = point(ahead: 11, right: -9, up: 1.4)
        case (_, .sky): from = point(ahead: 22, right: x, up: 9)
        case (_, .left): from = point(ahead: 13, right: -10, up: 1.6)
        case (_, .right): from = point(ahead: 13, right: 10, up: 1.6)
        default: from = point(ahead: 28, right: x, up: 1.4)
        }
        holder.simdPosition = thrower ? farSpot : from
        if thrower {
            nearHomes[id] = SCNVector3(near)
            holder.scale = SCNVector3(0.01, 0.01, 0.01)
            holder.runAction(.sequence([.wait(duration: 0.15), .scale(to: 1.15, duration: 0.18), .scale(to: 1, duration: 0.1)]))
            smoke(at: farSpot, color: UIColor(red: 0.62, green: 0.38, blue: 0.9, alpha: 0.95))
        }
        foeRoot.addChildNode(holder)
        foes[id] = (holder, body, tint)

        // enemies jumping in from the left / right come in quicker (one beat sooner) than the ones walking from the back
        let side = (path == .left || path == .right) && kind != .boss && kind != .mid && kind != .rare && kind != .kidnap && kind != .event
        let dur = (kind == .boss || kind == .mid ? 2.2 : kind == .rare ? 0.7 : kind == .event ? 0.4 : side ? 0.7 : 1.5) * (fast ? 0.4 : 1)
        let move = SCNAction.move(to: SCNVector3(to), duration: dur)
        move.timingMode = kind == .boss || kind == .mid || side ? .easeOut : .linear
        let arrive: [SCNAction] = [move]
        if path == .front && kind != .boss && kind != .mid && !thrower {
            let hop = SCNAction.sequence([.moveBy(x: 0, y: 1.6, z: 0, duration: dur / 6), .moveBy(x: 0, y: -1.6, z: 0, duration: dur / 6)])
            body.runAction(.repeat(hop, count: 3))
        }
        homes[id] = SCNVector3(to)
        holder.runAction(.group(arrive), forKey: "arrive")
        body.runAction(.sequence([.wait(duration: dur), idle(kind)]), forKey: "idle")

        if let item, let tex = Tex.emoji(item.icon) {
            let coin = billboard(SCNPlane(width: 0.7, height: 0.7), constantMaterial(tex))
            coin.position = SCNVector3(Float(w) / 2 + 0.1, Float(hh) / 2 + 0.2, 0.01)
            coin.name = "coin"
            coin.runAction(.repeatForever(.sequence([.moveBy(x: 0, y: 0.15, z: 0, duration: 0.4), .moveBy(x: 0, y: -0.15, z: 0, duration: 0.4)])))
            holder.addChildNode(coin)
        }
    }

    private func idle(_ kind: Foe.Kind) -> SCNAction {
        switch kind {
        case .mid:
            // stomps side to side and jumps
            let l = SCNAction.moveBy(x: -1.8, y: 0, z: 0, duration: 0.9), r = SCNAction.moveBy(x: 1.8, y: 0, z: 0, duration: 0.9)
            l.timingMode = .easeInEaseOut; r.timingMode = .easeInEaseOut
            let jump = SCNAction.sequence([.moveBy(x: 0, y: 0.9, z: 0, duration: 0.22), .moveBy(x: 0, y: -0.9, z: 0, duration: 0.18),
                                           .rotateBy(x: 0, y: 0, z: 0.12, duration: 0.06), .rotateBy(x: 0, y: 0, z: -0.12, duration: 0.06)])
            return .repeatForever(.sequence([l, jump, r, r, jump, l]))
        case .boss:
            let a = SCNAction.moveBy(x: 1.6, y: 0.35, z: 0, duration: 1.1), b = SCNAction.moveBy(x: -1.6, y: -0.35, z: 0, duration: 1.1)
            a.timingMode = .easeInEaseOut; b.timingMode = .easeInEaseOut
            let dash = SCNAction.sequence([.moveBy(x: 0, y: 0.3, z: 1.0, duration: 0.25), .moveBy(x: 0, y: -0.3, z: -1.0, duration: 0.5)])
            let spin = SCNAction.sequence([.rotateBy(x: 0, y: 0, z: 0.2, duration: 0.2), .rotateBy(x: 0, y: 0, z: -0.2, duration: 0.2)])
            return .repeatForever(.sequence([a, b, b, a, dash, spin]))
        case .rare:
            // nervous little side steps: about to run away
            let l = SCNAction.moveBy(x: -0.35, y: 0.12, z: 0, duration: 0.12), r = SCNAction.moveBy(x: 0.35, y: -0.12, z: 0, duration: 0.12)
            return .repeatForever(.sequence([l, r, r, l, .wait(duration: 0.15)]))
        case .event, .kidnap:
            let a = SCNAction.moveBy(x: 1.0, y: 0.2, z: 0, duration: 0.7), b = SCNAction.moveBy(x: -1.0, y: -0.2, z: 0, duration: 0.7)
            a.timingMode = .easeInEaseOut; b.timingMode = .easeInEaseOut
            return .repeatForever(.sequence([a, b, b, a]))
        default:
            let up = SCNAction.moveBy(x: 0, y: 0.18, z: 0, duration: 0.45); up.timingMode = .easeInEaseOut
            let tl = SCNAction.rotateBy(x: 0, y: 0, z: 0.08, duration: 0.45), tr = SCNAction.rotateBy(x: 0, y: 0, z: -0.08, duration: 0.45)
            return .repeatForever(.sequence([.group([up, tl]), .group([up.reversed(), tr])]))
        }
    }

    func foeID(of node: SCNNode) -> UUID? {
        var n: SCNNode? = node
        while let c = n { if let s = c.name, let id = UUID(uuidString: s), foes[id] != nil { return id }; n = c.parent }
        return nil
    }

    /// Fire a word orb at the enemy.
    /// a foe gets ready to throw something (pulses until the throw or the deflection)
    /// a thrower that waited far back walks up to its normal spot
    func approach(_ id: UUID, fast: Bool) {
        guard let f = foes[id], let near = nearHomes.removeValue(forKey: id) else { return }
        homes[id] = near
        let dur = fast ? 0.4 : 0.9
        let move = SCNAction.move(to: near, duration: dur); move.timingMode = .easeOut
        f.holder.removeAction(forKey: "arrive")
        f.holder.runAction(move, forKey: "arrive")
        f.body.runAction(.repeat(.sequence([.moveBy(x: 0, y: 1.2, z: 0, duration: dur / 6), .moveBy(x: 0, y: -1.2, z: 0, duration: dur / 6)]), count: 3))
    }

    func charge(_ id: UUID, _ on: Bool) {
        guard let f = foes[id] else { return }
        f.body.removeAction(forKey: "charge")
        if on {
            let pulse = SCNAction.sequence([.scale(to: 1.12, duration: 0.18), .scale(to: 1.0, duration: 0.18)])
            f.body.runAction(.repeatForever(pulse), forKey: "charge")
        } else {
            f.body.runAction(.scale(to: 1.0, duration: 0.1))
        }
    }

    func shoot(at id: UUID, color: UIColor = UIColor(red: 0.55, green: 0.95, blue: 1, alpha: 1)) {
        guard let f = foes[id] else { return }
        let s = SCNSphere(radius: 0.26)
        let m = SCNMaterial(); m.lightingModel = .constant; m.diffuse.contents = color; m.emission.contents = color
        s.firstMaterial = m
        let orb = SCNNode(geometry: s)
        orb.simdPosition = point(ahead: 1.2, right: 0, up: 1.5)
        scene.rootNode.addChildNode(orb)
        let target = f.holder.simdWorldPosition
        orb.runAction(.sequence([.move(to: SCNVector3(target), duration: 0.22), .removeFromParentNode()]))
        later(0.22) { [weak self] in
            self?.burst(at: target, color: color)
            self?.hurt(id)
        }
    }

    func hurt(_ id: UUID) {
        guard let f = foes[id] else { return }
        let s = SCNAction.sequence([.moveBy(x: 0.18, y: 0, z: 0, duration: 0.04), .moveBy(x: -0.36, y: 0, z: 0, duration: 0.06), .moveBy(x: 0.18, y: 0, z: 0, duration: 0.04)])
        f.holder.runAction(s)
        let m = f.body.geometry?.firstMaterial
        m?.emission.contents = UIColor(white: 0.9, alpha: 1)
        later(0.12) { m?.emission.contents = UIColor.black }
    }

    func burst(at p: SIMD3<Float>, color: UIColor = .yellow, count: CGFloat = 1) {
        let ps = SCNParticleSystem()
        ps.birthRate = 140 * count
        ps.emissionDuration = 0.07
        ps.loops = false
        ps.particleLifeSpan = 0.7
        ps.particleVelocity = 3
        ps.particleVelocityVariation = 1.5
        ps.spreadingAngle = 180
        ps.particleSize = 0.09
        ps.particleSizeVariation = 0.04
        ps.particleImage = Tex.star
        ps.particleColor = color
        ps.particleColorVariation = SCNVector4(0.15, 0.3, 0.2, 0)
        ps.acceleration = SCNVector3(0, -7, 0)
        ps.blendMode = .additive
        ps.isLightingEnabled = false
        let n = SCNNode()
        n.simdPosition = p
        n.addParticleSystem(ps)
        scene.rootNode.addChildNode(n)
        n.runAction(.sequence([.wait(duration: 1.6), .removeFromParentNode()]))
    }

    /// A big cloud of soft smoke (boss explosion).
    /// Thick smoke between the foe and the camera (big: the boss's true form comes out of it).
    func smoke(at p: SIMD3<Float>, big: Bool = false, color: UIColor? = nil) {
        let ps = SCNParticleSystem()
        ps.birthRate = big ? 900 : 220
        ps.emissionDuration = big ? 0.55 : 0.25
        ps.loops = false
        ps.particleLifeSpan = big ? 2.6 : 1.8
        ps.particleLifeSpanVariation = 0.6
        ps.particleVelocity = big ? 2.4 : 1.6
        ps.particleVelocityVariation = 1.2
        ps.spreadingAngle = 180
        ps.particleSize = big ? 1.7 : 0.9
        ps.particleSizeVariation = 0.6
        ps.particleImage = Tex.puff
        ps.particleColor = color ?? UIColor(red: 0.86, green: 0.82, blue: 0.95, alpha: 0.95)
        ps.particleColorVariation = SCNVector4(0, 0, 0.15, 0)
        ps.acceleration = SCNVector3(0, big ? 0.35 : 0.6, 0)
        ps.dampingFactor = big ? 1.1 : 1.5
        if big {
            ps.emitterShape = SCNSphere(radius: 1.1)
            ps.birthLocation = .volume
        }
        let grow = SCNParticlePropertyController(animation: {
            let a = CAKeyframeAnimation(); a.values = [0.6, 1.7, 2.4]; a.keyTimes = [0, 0.4, 1]; return a }())
        let fade = SCNParticlePropertyController(animation: {
            let a = CAKeyframeAnimation(); a.values = [0.0, 1.0, 0.9, 0.0]; a.keyTimes = [0, 0.08, 0.65, 1]; return a }())
        ps.propertyControllers = [.size: grow, .opacity: fade]
        ps.blendMode = .alpha
        ps.isLightingEnabled = false
        ps.sortingMode = .projectedDepth
        // pull the cloud toward the camera so it covers the foe instead of hiding behind it
        let c = cam.simdWorldPosition
        var dir = c - p; let len = simd_length(dir); if len > 0.01 { dir /= len }
        let n = SCNNode()
        n.simdPosition = p + SIMD3<Float>(0, big ? 0.6 : 0.3, 0) + dir * (big ? 1.4 : 0.6)
        n.renderingOrder = 50
        n.addParticleSystem(ps)
        scene.rootNode.addChildNode(n)
        n.runAction(.sequence([.wait(duration: 4), .removeFromParentNode()]))
    }

    func rescue(_ id: UUID, big: Bool, freed: String? = nil, reveal: Double = 0, puff: Bool = false) {
        guard let f = foes.removeValue(forKey: id) else { return }
        f.holder.childNode(withName: "coin", recursively: false)?.removeFromParentNode()
        f.body.removeAction(forKey: "idle")
        let hold: Double
        if let freed, let img = UIImage(named: freed) {
            let swap = { [weak self] in
                guard let self else { return }
                let pos = f.holder.simdWorldPosition
                if reveal > 0 {
                    // a big cloud of smoke swallows the boss, then the true form steps out of it
                    self.smoke(at: pos, big: true)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.smoke(at: pos, big: true) }
                    self.burst(at: pos, color: UIColor(red: 1, green: 0.8, blue: 0.95, alpha: 1), count: 3.5)
                    f.body.runAction(.fadeOut(duration: 0.25))
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                        f.body.geometry?.firstMaterial?.diffuse.contents = img
                        if let g = f.body.geometry as? SCNPlane { g.width = g.height * img.size.width / max(1, img.size.height) }
                        f.body.scale = SCNVector3(0.7, 0.7, 0.7)
                        let pop = SCNAction.scale(to: 1, duration: 0.6); pop.timingMode = .easeOut
                        f.body.runAction(.group([.fadeIn(duration: 0.7), pop]))
                        self.burst(at: pos, color: UIColor(red: 1, green: 0.95, blue: 0.7, alpha: 1), count: 2)
                    }
                } else if puff {
                    // possessed person: a smaller cloud of smoke, the spirit leaves, the person steps out
                    self.smoke(at: pos, big: false)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { self.smoke(at: pos, big: false) }
                    self.burst(at: pos, color: UIColor(red: 0.8, green: 0.7, blue: 1, alpha: 1), count: 1.6)
                    f.body.runAction(.fadeOut(duration: 0.2))
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                        f.body.geometry?.firstMaterial?.diffuse.contents = img
                        if let g = f.body.geometry as? SCNPlane { g.width = g.height * img.size.width / max(1, img.size.height) }
                        f.body.scale = SCNVector3(0.8, 0.8, 0.8)
                        let pop = SCNAction.scale(to: 1, duration: 0.45); pop.timingMode = .easeOut
                        f.body.runAction(.group([.fadeIn(duration: 0.5), pop]))
                        self.burst(at: pos, color: UIColor(red: 1, green: 0.95, blue: 0.7, alpha: 1), count: 1.4)
                    }
                } else {
                    self.burst(at: pos, color: UIColor(red: 1, green: 0.8, blue: 0.95, alpha: 1), count: 2.5)
                    f.body.geometry?.firstMaterial?.diffuse.contents = img
                    if let g = f.body.geometry as? SCNPlane { g.width = g.height * img.size.width / max(1, img.size.height) }
                }
            }
            if reveal > 0 {
                // shudder while the thunder hits, then the explosion
                f.body.runAction(.repeat(.sequence([.moveBy(x: 0.06, y: 0, z: 0, duration: 0.04), .moveBy(x: -0.06, y: 0, z: 0, duration: 0.04)]), count: Int(reveal / 0.08)))
                DispatchQueue.main.asyncAfter(deadline: .now() + reveal, execute: swap)
            } else { swap() }
            hold = reveal + (reveal > 0 ? 3.6 : puff ? 3.0 : 2.4)
        } else { hold = big ? 0.6 : 0 }
        f.body.runAction(.sequence([.rotateTo(x: 0, y: 0, z: 0, duration: 0.1)]))
        // a freed boss / person (true form) fades out where it stands; flying up and growing took it off screen
        let leave: SCNAction = freed != nil
            ? .fadeOut(duration: 1.2)
            : .group([.moveBy(x: 0, y: big ? 2.5 : 1.6, z: 0, duration: big ? 1.4 : 0.8), .fadeOut(duration: big ? 1.4 : 0.8), .scale(to: 1.2, duration: 0.8)])
        f.holder.runAction(.sequence([.wait(duration: hold), leave, .removeFromParentNode()]))
    }

    /// Enemy lunges at the camera.
    func attack(_ id: UUID, kind: AttackKind = .bite) {
        guard let f = foes[id] else { return }
        // finish the walk-in and any earlier attack first: two moves at once made foes jerk and "warp"
        f.holder.removeAction(forKey: "arrive")
        f.holder.removeAction(forKey: "atk")
        let home = homes[id] ?? f.holder.position
        let near = point(ahead: 2.6, right: 0, up: 1.9)
        let back = SCNAction.move(to: home, duration: 0.45); back.timingMode = .easeOut
        switch kind {
        case .bite:
            let lunge = SCNAction.move(to: SCNVector3(near), duration: 0.28); lunge.timingMode = .easeIn
            f.holder.runAction(.sequence([.moveBy(x: 0, y: 0.4, z: 0, duration: 0.12), lunge, .wait(duration: 0.1), back]), forKey: "atk")
        case .lick:
            // leans in and stretches out a long tongue (body stretches toward you)
            let mid = point(ahead: 4.2, right: 0, up: 1.7)
            let lean = SCNAction.move(to: SCNVector3(mid), duration: 0.3); lean.timingMode = .easeIn
            f.body.runAction(.sequence([.wait(duration: 0.25), .scale(to: 1.5, duration: 0.2), .wait(duration: 0.15), .scale(to: 1, duration: 0.3)]))
            f.holder.runAction(.sequence([lean, .wait(duration: 0.4), back]), forKey: "atk")
        case .stomp:
            // jumps high and lands right in front of you
            let up = SCNAction.moveBy(x: 0, y: 4.5, z: 0, duration: 0.4); up.timingMode = .easeOut
            let slam = SCNAction.move(to: SCNVector3(point(ahead: 3.0, right: 0, up: 1.2)), duration: 0.3); slam.timingMode = .easeIn
            f.holder.runAction(.sequence([up, slam, .wait(duration: 0.25), back]), forKey: "atk")
        case .spit:
            // recoils, then spits a slime ball at the camera
            f.holder.runAction(.sequence([.moveBy(x: 0, y: 0.3, z: 0, duration: 0.18), .moveBy(x: 0, y: -0.3, z: 0, duration: 0.12), back]), forKey: "atk")
            let s = SCNSphere(radius: 0.32)
            let m = SCNMaterial(); m.lightingModel = .constant; m.diffuse.contents = UIColor(red: 0.6, green: 0.9, blue: 0.35, alpha: 1)
            s.firstMaterial = m
            let ball = SCNNode(geometry: s)
            ball.simdPosition = f.holder.simdWorldPosition
            scene.rootNode.addChildNode(ball)
            let fly = SCNAction.move(to: SCNVector3(point(ahead: 0.6, right: 0, up: 1.5)), duration: 0.32); fly.timingMode = .easeIn
            ball.runAction(.sequence([.wait(duration: 0.3), fly, .removeFromParentNode()]))
        case .spin:
            let lunge = SCNAction.move(to: SCNVector3(near), duration: 0.45); lunge.timingMode = .easeIn
            f.body.runAction(.rotateBy(x: 0, y: 0, z: .pi * 4, duration: 0.55))
            f.holder.runAction(.sequence([lunge, .wait(duration: 0.1), back]), forKey: "atk")
        case .roar:
            // swells up and roars: a shock wave
            f.body.runAction(.sequence([.scale(to: 1.35, duration: 0.45), .wait(duration: 0.2), .scale(to: 1, duration: 0.3)]))
            f.holder.runAction(back, forKey: "atk")
            later(0.5) { [weak self] in self?.burst(at: f.holder.simdWorldPosition, color: .white, count: 1.5) }
        }
        later(kind.impact) { [weak self] in self?.shake(kind == .stomp || kind == .roar ? 0.55 : 0.35) }
    }

    /// Enemy runs off (after biting, or a lucky Gobble escaping).
    func flee(_ id: UUID) {
        guard let f = foes.removeValue(forKey: id) else { return }
        let away = point(ahead: 30, right: Float.random(in: -6...6), up: 3)
        f.holder.runAction(.sequence([.wait(duration: 0.7), .group([.move(to: SCNVector3(away), duration: 0.9), .fadeOut(duration: 0.9)]), .removeFromParentNode()]))
    }

    /// the view drawing this world (to keep it running)
    weak var view: SCNView?
    /// Safety net: while the game is running nothing may stay stopped. Seen once on iPad: the whole
    /// picture stood still (a defeated mid boss stayed, the boss stayed tiny far away).
    func ensureRunning(frozen: Bool) {
        if scene.isPaused { scene.isPaused = false }
        if let v = view, !v.isPlaying { v.isPlaying = true }
        if foeRoot.isPaused != frozen { freeze(frozen) }
    }

    /// Boss rush: a boss comes back as a dark "shadow" of itself
    func shade(_ id: UUID) {
        guard let f = foes[id] else { return }
        let c = UIColor(red: 0.55, green: 0.42, blue: 0.75, alpha: 1)
        foes[id] = (f.holder, f.body, c)
        f.body.geometry?.firstMaterial?.multiply.contents = c
    }

    func removeAllFoes() { foeRoot.childNodes.forEach { $0.removeFromParentNode() }; foes = [:]; homes = [:] }

    /// Time stop: enemies freeze and turn icy blue.
    func freeze(_ on: Bool) {
        foeRoot.isPaused = on
        for (_, f) in foes { f.body.geometry?.firstMaterial?.multiply.contents = on ? UIColor(red: 0.6, green: 0.8, blue: 1, alpha: 1) : f.tint }
    }

    // MARK: - helpers

    private func constantMaterial(_ img: Any?) -> SCNMaterial {
        let m = SCNMaterial()
        m.lightingModel = .constant
        m.diffuse.contents = img
        m.isDoubleSided = true
        m.transparencyMode = .aOne
        return m
    }

    private func plane(_ w: CGFloat, _ h: CGFloat, _ img: UIImage, lit: Bool) -> SCNPlane {
        let p = SCNPlane(width: w, height: h)
        let m = SCNMaterial(); m.diffuse.contents = img; m.lightingModel = lit ? .lambert : .constant
        p.firstMaterial = m
        return p
    }

    private func billboard(_ g: SCNPlane, _ m: SCNMaterial) -> SCNNode {
        g.firstMaterial = m
        let n = SCNNode(geometry: g)
        let c = SCNBillboardConstraint(); c.freeAxes = .Y
        n.constraints = [c]
        return n
    }
}

/// Small generated textures.
enum Tex {
    /// centre crop to the view's aspect (the background picture is stretched to the view)
    static func crop(_ img: UIImage, aspect: CGFloat) -> UIImage {
        guard let cg = img.cgImage else { return img }
        let w = CGFloat(cg.width), h = CGFloat(cg.height)
        var r = CGRect(x: 0, y: 0, width: w, height: h)
        if w / h > aspect { r.size.width = h * aspect; r.origin.x = (w - r.width) / 2 }
        else { r.size.height = w / aspect; r.origin.y = (h - r.height) * 0.6 }
        guard let c = cg.cropping(to: r.integral) else { return img }
        return UIImage(cgImage: c)
    }

    static func sky(_ top: UIColor, _ bottom: UIColor) -> UIImage {
        render(CGSize(width: 8, height: 256)) { c, s in
            let cs = CGColorSpaceCreateDeviceRGB()
            let g = CGGradient(colorsSpace: cs, colors: [top.cgColor, bottom.cgColor] as CFArray, locations: [0, 1])!
            c.drawLinearGradient(g, start: .zero, end: CGPoint(x: 0, y: s.height), options: [])
        }
    }
    nonisolated static func rgb(_ h: Int) -> UIColor { UIColor(red: CGFloat((h >> 16) & 0xFF) / 255, green: CGFloat((h >> 8) & 0xFF) / 255, blue: CGFloat(h & 0xFF) / 255, alpha: 1) }

    /// cobblestones (Future Street)
    static let cobble: UIImage = render(CGSize(width: 128, height: 96)) { c, s in
        rgb(0x8A7A6C).setFill(); c.fill(CGRect(origin: .zero, size: s))
        let cols: [Int] = [0xB49C86, 0xA88F7A, 0xC2AA92, 0x9E8672]
        for row in 0..<6 {
            let off = row % 2 == 0 ? 0 : 10
            var x = -off
            while x < 128 {
                let w = Int.random(in: 16...24)
                rgb(cols.randomElement()!).setFill()
                c.addPath(UIBezierPath(roundedRect: CGRect(x: x + 1, y: row * 16 + 1, width: w - 2, height: 14), cornerRadius: 5).cgPath); c.fillPath()
                x += w
            }
        }
        UIColor(red: 1, green: 0.85, blue: 0.4, alpha: 0.9).setFill(); c.fill(CGRect(x: 62, y: 8, width: 4, height: 40))
    }
    /// checker tiles (Trophy Plaza)
    static let checker: UIImage = render(CGSize(width: 128, height: 96)) { c, s in
        for y in 0..<6 { for x in 0..<8 {
            rgb((x + y) % 2 == 0 ? 0xFFF1D6 : 0xE96F7E).setFill()
            c.fill(CGRect(x: x * 16, y: y * 16, width: 16, height: 16))
        } }
    }
    /// stone road with a red carpet (Hotel District)
    static let carpet: UIImage = render(CGSize(width: 128, height: 96)) { c, s in
        rgb(0xD8D0C4).setFill(); c.fill(CGRect(origin: .zero, size: s))
        rgb(0xBDB3A5).setFill()
        for y in stride(from: 0, to: 96, by: 24) { c.fill(CGRect(x: 0, y: y, width: 128, height: 2)) }
        for x in stride(from: 0, to: 128, by: 32) { c.fill(CGRect(x: x, y: 0, width: 2, height: 96)) }
        rgb(0xC8323F).setFill(); c.fill(CGRect(x: 40, y: 0, width: 48, height: 96))
        rgb(0xF2C14E).setFill(); c.fill(CGRect(x: 40, y: 0, width: 4, height: 96)); c.fill(CGRect(x: 84, y: 0, width: 4, height: 96))
    }
    /// stepping-stone path in grass (Garden of If)
    static let garden: UIImage = render(CGSize(width: 128, height: 96)) { c, s in
        rgb(0x8FCB6E).setFill(); c.fill(CGRect(origin: .zero, size: s))
        rgb(0x7DB85E).setFill()
        for _ in 0..<40 { c.fill(CGRect(x: Int.random(in: 0..<128), y: Int.random(in: 0..<96), width: 2, height: 5)) }
        for row in 0..<3 {
            for k in 0..<2 {
                rgb([0xEDE3CF, 0xE2D6BE].randomElement()!).setFill()
                c.addPath(UIBezierPath(ovalIn: CGRect(x: 34 + k * 32 + (row % 2) * 6, y: row * 32 + 4, width: 28, height: 22)).cgPath); c.fillPath()
            }
        }
        for _ in 0..<10 {
            rgb([0xFF8FB8, 0xFFE07A, 0xC3A6FF, 0xFFFFFF].randomElement()!).setFill()
            let x = [Int.random(in: 2..<28), Int.random(in: 100..<124)].randomElement()!
            c.fillEllipse(in: CGRect(x: x, y: Int.random(in: 0..<92), width: 5, height: 5))
        }
    }
    /// lab floor tiles (Logic Lab)
    static let labFloor: UIImage = render(CGSize(width: 128, height: 96)) { c, s in
        for y in 0..<6 { for x in 0..<8 {
            rgb((x + y) % 2 == 0 ? 0xE8EEF5 : 0xC9D3E0).setFill()
            c.fill(CGRect(x: x * 16, y: y * 16, width: 16, height: 16))
        } }
        rgb(0x55D6FF).setFill(); c.fill(CGRect(x: 62, y: 0, width: 4, height: 96))
    }
    /// sky bridge stones (Castle of Silence)
    static let bridge: UIImage = render(CGSize(width: 128, height: 96)) { c, s in
        rgb(0x7E7890).setFill(); c.fill(CGRect(origin: .zero, size: s))
        let cols: [Int] = [0xA7A1B8, 0x9C96AE, 0xB3ADC4]
        for row in 0..<4 {
            let off = row % 2 == 0 ? 0 : 16
            for k in -1..<5 {
                rgb(cols.randomElement()!).setFill()
                c.fill(CGRect(x: k * 32 + off + 1, y: row * 24 + 1, width: 30, height: 22))
            }
        }
    }
    static func plain(_ h: Int) -> UIImage { render(CGSize(width: 16, height: 16)) { c, s in rgb(h).setFill(); c.fill(CGRect(origin: .zero, size: s)) } }

    /// facades
    static let brass: UIImage = render(CGSize(width: 120, height: 120)) { c, s in
        rgb(0xF6E7D2).setFill(); c.fill(CGRect(origin: .zero, size: s))
        rgb(0xC98B4E).setFill(); c.fill(CGRect(x: 0, y: 0, width: 120, height: 8)); c.fill(CGRect(x: 0, y: 112, width: 120, height: 8))
        for col in 0..<3 {
            rgb(0xC98B4E).setFill(); c.fillEllipse(in: CGRect(x: 10 + col * 36, y: 22, width: 28, height: 28))
            rgb(0x9ED7E8).setFill(); c.fillEllipse(in: CGRect(x: 14 + col * 36, y: 26, width: 20, height: 20))
            rgb(0xC98B4E).setFill(); c.fill(CGRect(x: 12 + col * 36, y: 66, width: 24, height: 36))
            rgb(0x9ED7E8).setFill(); c.fill(CGRect(x: 16 + col * 36, y: 70, width: 16, height: 28))
        }
    }
    static let hotel: UIImage = render(CGSize(width: 120, height: 120)) { c, s in
        rgb(0xFBF3E6).setFill(); c.fill(CGRect(origin: .zero, size: s))
        for col in 0..<3 {
            let x = 12 + col * 36
            rgb(0xFFD889).setFill()
            c.addPath(UIBezierPath(roundedRect: CGRect(x: x, y: 14, width: 24, height: 40), byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 12, height: 12)).cgPath); c.fillPath()
            rgb(0x8C5A3C).setFill(); c.fill(CGRect(x: x - 3, y: 54, width: 30, height: 4))
            for k in 0..<4 { c.fill(CGRect(x: x - 2 + k * 8, y: 46, width: 2, height: 8)) }
            rgb(0xFFD889).setFill()
            c.addPath(UIBezierPath(roundedRect: CGRect(x: x, y: 72, width: 24, height: 36), byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 12, height: 12)).cgPath); c.fillPath()
        }
        rgb(0xD9C7AE).setFill(); c.fill(CGRect(x: 0, y: 62, width: 120, height: 3))
    }
    static let hedge: UIImage = render(CGSize(width: 120, height: 120)) { c, s in
        rgb(0x5FAE5A).setFill(); c.fill(CGRect(origin: .zero, size: s))
        for _ in 0..<70 {
            rgb([0x4E9A4B, 0x73C46A, 0x68B862].randomElement()!).setFill()
            c.fillEllipse(in: CGRect(x: Int.random(in: -6..<120), y: Int.random(in: -6..<120), width: 14, height: 12))
        }
        for _ in 0..<14 {
            rgb([0xFF7FAE, 0xFFFFFF, 0xFFD45E, 0xE07BFF].randomElement()!).setFill()
            c.fillEllipse(in: CGRect(x: Int.random(in: 0..<114), y: Int.random(in: 0..<114), width: 7, height: 7))
        }
    }
    static let labWall: UIImage = render(CGSize(width: 120, height: 120)) { c, s in
        rgb(0xF3F6FA).setFill(); c.fill(CGRect(origin: .zero, size: s))
        rgb(0xD5DDE8).setFill(); c.fill(CGRect(x: 0, y: 0, width: 2, height: 120)); c.fill(CGRect(x: 0, y: 58, width: 120, height: 2))
        rgb(0x2E3A55).setFill(); c.fill(CGRect(x: 14, y: 12, width: 44, height: 32)); c.fill(CGRect(x: 66, y: 70, width: 40, height: 30))
        rgb(0x6FE3C1).setFill(); c.fill(CGRect(x: 18, y: 30, width: 6, height: 10)); c.fill(CGRect(x: 27, y: 24, width: 6, height: 16)); c.fill(CGRect(x: 36, y: 18, width: 6, height: 22))
        rgb(0x7BC8FF).setFill(); c.fill(CGRect(x: 70, y: 76, width: 32, height: 4)); c.fill(CGRect(x: 70, y: 84, width: 22, height: 4)); c.fill(CGRect(x: 70, y: 92, width: 28, height: 4))
        rgb(0xFF8FB8).setFill(); c.fillEllipse(in: CGRect(x: 76, y: 16, width: 10, height: 10)); rgb(0xFFE07A).setFill(); c.fillEllipse(in: CGRect(x: 92, y: 16, width: 10, height: 10))
    }
    static let bunting: UIImage = render(CGSize(width: 256, height: 48)) { c, s in
        rgb(0x3B2F5A).setStroke(); c.setLineWidth(2)
        c.move(to: CGPoint(x: 0, y: 4)); c.addQuadCurve(to: CGPoint(x: 256, y: 4), control: CGPoint(x: 128, y: 22)); c.strokePath()
        let cols: [Int] = [0xFF5D73, 0xFFD23F, 0x3EC1F3, 0x7BE495, 0xB18CFF]
        for k in 0..<16 {
            let x = CGFloat(k) * 16 + 2, t = x / 256, y = 4 + 18 * 4 * t * (1 - t)
            rgb(cols[k % cols.count]).setFill()
            c.move(to: CGPoint(x: x, y: y)); c.addLine(to: CGPoint(x: x + 13, y: y)); c.addLine(to: CGPoint(x: x + 6.5, y: y + 20)); c.closePath(); c.fillPath()
        }
    }
    static let roses: UIImage = render(CGSize(width: 64, height: 16)) { c, s in
        rgb(0x4E9A4B).setFill(); c.fill(CGRect(origin: .zero, size: s))
        for k in 0..<5 { rgb([0xFF6F9C, 0xFFFFFF, 0xFFB3C9].randomElement()!).setFill(); c.fillEllipse(in: CGRect(x: k * 13 + 2, y: 3, width: 9, height: 9)) }
    }
    static let cloud: UIImage = render(CGSize(width: 256, height: 116)) { c, s in
        UIColor(white: 1, alpha: 0.92).setFill()
        for (x, y, r) in [(60, 70, 40), (110, 55, 52), (165, 65, 44), (205, 78, 32), (40, 86, 26)] as [(CGFloat, CGFloat, CGFloat)] {
            c.fillEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
        }
        c.fill(CGRect(x: 30, y: 78, width: 200, height: 34))
    }
    static let road: UIImage = render(CGSize(width: 64, height: 48)) { c, s in
        UIColor(red: 0.37, green: 0.39, blue: 0.47, alpha: 1).setFill(); c.fill(CGRect(origin: .zero, size: s))
        UIColor.white.withAlphaComponent(0.85).setFill(); c.fill(CGRect(x: 30, y: 4, width: 4, height: 22))
        UIColor.white.withAlphaComponent(0.5).setFill(); c.fill(CGRect(x: 1, y: 0, width: 2, height: 48)); c.fill(CGRect(x: 61, y: 0, width: 2, height: 48))
    }
    static let plainRoad: UIImage = render(CGSize(width: 32, height: 32)) { c, s in
        UIColor(red: 0.37, green: 0.39, blue: 0.47, alpha: 1).setFill(); c.fill(CGRect(origin: .zero, size: s))
    }
    static let windows: UIImage = render(CGSize(width: 120, height: 120)) { c, s in
        UIColor(white: 0.97, alpha: 1).setFill(); c.fill(CGRect(origin: .zero, size: s))
        UIColor(red: 0.62, green: 0.74, blue: 0.86, alpha: 1).setFill()
        for row in 0..<3 { for col in 0..<3 { c.fill(CGRect(x: 12 + col * 36, y: 14 + row * 36, width: 24, height: 22)) } }
        UIColor(white: 0.8, alpha: 1).setFill(); c.fill(CGRect(x: 0, y: 116, width: 120, height: 4))
    }
    /// soft round puff for smoke
    static let puff: UIImage = render(CGSize(width: 64, height: 64)) { c, s in
        let cs = CGColorSpaceCreateDeviceRGB()
        let g = CGGradient(colorsSpace: cs, colors: [UIColor.white.cgColor, UIColor.white.withAlphaComponent(0.6).cgColor, UIColor.white.withAlphaComponent(0).cgColor] as CFArray, locations: [0, 0.5, 1])!
        c.drawRadialGradient(g, startCenter: CGPoint(x: 32, y: 32), startRadius: 0, endCenter: CGPoint(x: 32, y: 32), endRadius: 32, options: [])
    }
    static let star: UIImage = render(CGSize(width: 32, height: 32)) { c, s in
        let p = UIBezierPath()
        for i in 0..<10 {
            let r: CGFloat = i % 2 == 0 ? 15 : 6, a = CGFloat(i) * .pi / 5 - .pi / 2
            let pt = CGPoint(x: 16 + cos(a) * r, y: 16 + sin(a) * r)
            i == 0 ? p.move(to: pt) : p.addLine(to: pt)
        }
        p.close(); UIColor.white.setFill(); p.fill()
    }
    private static var emojiCache: [String: UIImage] = [:]
    /// item coin: "ui_name|emoji" draws the illustration (falls back to the emoji), a plain string draws the emoji
    static func emoji(_ e: String) -> UIImage? {
        if let i = emojiCache[e] { return i }
        let parts = e.split(separator: "|").map(String.init)
        let art = parts.count > 1 ? UIImage(named: parts[0]) : nil
        let glyph = parts.last ?? e
        let img = render(CGSize(width: 128, height: 128)) { c, s in
            UIColor(red: 1, green: 0.88, blue: 0.48, alpha: 1).setFill()
            UIColor(red: 0.14, green: 0.12, blue: 0.29, alpha: 1).setStroke()
            let o = UIBezierPath(ovalIn: CGRect(x: 8, y: 8, width: 112, height: 112)); o.lineWidth = 8; o.fill(); o.stroke()
            if let art {
                let r = CGRect(x: 26, y: 26, width: 76, height: 76)
                let k = min(r.width / art.size.width, r.height / art.size.height)
                let sz = CGSize(width: art.size.width * k, height: art.size.height * k)
                art.draw(in: CGRect(x: 64 - sz.width / 2, y: 64 - sz.height / 2, width: sz.width, height: sz.height))
            } else {
                let a = NSAttributedString(string: glyph, attributes: [.font: UIFont.systemFont(ofSize: 64)])
                let sz = a.size(); a.draw(at: CGPoint(x: 64 - sz.width / 2, y: 66 - sz.height / 2))
            }
        }
        emojiCache[e] = img
        return img
    }
    private static func render(_ size: CGSize, _ draw: (CGContext, CGSize) -> Void) -> UIImage {
        let f = UIGraphicsImageRendererFormat(); f.scale = 1
        return UIGraphicsImageRenderer(size: size, format: f).image { ctx in draw(ctx.cgContext, size) }
    }
}

/// Run on the main actor after a delay (SceneKit completion handlers run off the main thread, so we never use them).
func later(_ seconds: Double, _ f: @escaping @MainActor () -> Void) {
    Task { @MainActor in
        try? await Task.sleep(nanoseconds: UInt64(max(0, seconds) * 1_000_000_000))
        f()
    }
}


/// What one chapter's street looks like.
struct WorldTheme {
    enum Side { case city, lab, hedges, rails }
    var skyTop: UIColor, skyBottom: UIColor, fog: UIColor
    var fogStart: CGFloat = 70, fogEnd: CGFloat = 210
    var road: UIImage, square: UIImage
    var walk: UIColor
    var facade: UIImage
    var side: Side = .city
    var heights: ClosedRange<Float> = 5...12
    var shops = true
    var bunting = false
    var arches = false
    var skyline = true
    var palette: [UIColor]

    static func of(_ a: Area) -> WorldTheme {
        let c = Tex.rgb
        let candy = [0xFF9CC8, 0x7EE3C3, 0xFFE07A, 0x8FD3FF, 0xFFB978, 0xC3A6FF, 0xB8EB8A, 0xFF9E9E].map { c($0) }
        switch a {
        case .lv1:
            return .init(skyTop: c(0x6BBDFF), skyBottom: c(0xDBF2FF), fog: UIColor(red: 0.85, green: 0.93, blue: 1, alpha: 1),
                         road: Tex.road, square: Tex.plainRoad, walk: UIColor(red: 0.93, green: 0.87, blue: 0.78, alpha: 1), facade: Tex.windows, palette: candy)
        case .lv2:
            return .init(skyTop: c(0xFF9F6B), skyBottom: c(0xFFE2B8), fog: c(0xFFE0C2),
                         road: Tex.cobble, square: Tex.plain(0x9E8672), walk: c(0xD9B98F), facade: Tex.brass, heights: 6...13,
                         palette: [0xE8A15A, 0x6FC2B4, 0xD9774F, 0xF2C14E, 0x8DB6E0].map { c($0) })
        case .lv3:
            return .init(skyTop: c(0x8F7BFF), skyBottom: c(0xFFC4E1), fog: c(0xFFD6EA),
                         road: Tex.checker, square: Tex.plain(0xFFF1D6), walk: c(0xF6D27A), facade: Tex.windows, heights: 4...8,
                         bunting: true, palette: [0xFF7A93, 0xFFD23F, 0x3EC1F3, 0x7BE495, 0xB18CFF].map { c($0) })
        case .lv4:
            return .init(skyTop: c(0x4A5FB5), skyBottom: c(0xF5B98E), fog: c(0xF2C9A8),
                         road: Tex.carpet, square: Tex.plain(0xD8D0C4), walk: c(0xE8DDCB), facade: Tex.hotel, heights: 10...17,
                         shops: false, palette: [0xF7E3C6, 0xE9C9A0, 0xF4D1D1, 0xD8E4F0, 0xFFF0C4].map { c($0) })
        case .lv5:
            return .init(skyTop: c(0xB79BFF), skyBottom: c(0xFFE6F2), fog: c(0xF4E4FF),
                         road: Tex.garden, square: Tex.plain(0x8FCB6E), walk: c(0x7DB85E), facade: Tex.hedge, side: .hedges, heights: 1.4...2.6,
                         shops: false, arches: true, skyline: false, palette: [0x7FD07A, 0x9BE08F, 0x6CC06A].map { c($0) })
        case .lv6:
            return .init(skyTop: c(0x1E2A4A), skyBottom: c(0x3E5C8F), fog: c(0x7FA0C8), fogStart: 40, fogEnd: 140,
                         road: Tex.labFloor, square: Tex.plain(0xE8EEF5), walk: c(0xB9C6D6), facade: Tex.labWall, side: .lab, heights: 7.5...7.5,
                         shops: false, skyline: false, palette: [0xBFEFFF, 0xD7F7EA, 0xE3E0FF, 0xFFFFFF].map { c($0) })
        case .graduation:
            return .init(skyTop: c(0x5B3F9E), skyBottom: c(0xFFC98A), fog: c(0xF4D8C8), fogStart: 50, fogEnd: 180,
                         road: Tex.bridge, square: Tex.plain(0x9C96AE), walk: c(0xB3ADC4), facade: Tex.windows, side: .rails,
                         shops: false, skyline: false, palette: candy)
        }
    }
}
