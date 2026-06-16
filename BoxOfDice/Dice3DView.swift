//
//  Dice3DView.swift
//  BoxOfDice
//

import SceneKit
import SwiftUI
import UIKit
import simd

struct Dice3DView: UIViewRepresentable {
    let value: Int
    let isRolling: Bool
    let dieIndex: Int
    var onSettled: (() -> Void)?

    func makeUIView(context: Context) -> SCNView {
        context.coordinator.makeView()
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        context.coordinator.update(
            value: value,
            isRolling: isRolling,
            onSettled: onSettled
        )
    }

    func makeCoordinator() -> DiceSceneCoordinator {
        DiceSceneCoordinator(dieIndex: dieIndex)
    }
}

final class DiceSceneCoordinator: NSObject {
    private let dieIndex: Int
    private let scene = SCNScene()
    private let dieNode = SCNNode()
    private let contactShadowNode = SCNNode()
    private let basePosition = SIMD3<Float>(0, 0, 0)
    private var displayedValue = -1
    private var targetValue = 0
    private var wasRolling = false
    private var isAnimating = false
    private var onSettled: (() -> Void)?
    private var finalYaw: Float = 0

    private let dieSize: CGFloat = 1.0
    private let pipRadius: CGFloat = 0.045
    private let pipDepth: CGFloat = 0.014

    private static let contactShadowImage: UIImage = {
        let size = CGSize(width: 256, height: 128)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let cgContext = context.cgContext
            cgContext.clear(CGRect(origin: .zero, size: size))
            let colors = [
                UIColor.black.withAlphaComponent(0.30).cgColor,
                UIColor.black.withAlphaComponent(0.10).cgColor,
                UIColor.clear.cgColor
            ] as CFArray
            let locations: [CGFloat] = [0.0, 0.42, 1.0]
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations) else {
                return
            }
            cgContext.scaleBy(x: 1.0, y: 0.42)
            cgContext.drawRadialGradient(
                gradient,
                startCenter: CGPoint(x: size.width * 0.48, y: size.height * 1.18),
                startRadius: 5,
                endCenter: CGPoint(x: size.width * 0.48, y: size.height * 1.18),
                endRadius: size.width * 0.48,
                options: [.drawsAfterEndLocation]
            )
        }
    }()

    init(dieIndex: Int) {
        self.dieIndex = dieIndex
        super.init()
        configureScene()
    }

    func makeView() -> SCNView {
        let view = SCNView(frame: .zero)
        view.scene = scene
        view.backgroundColor = .clear
        view.isOpaque = false
        view.allowsCameraControl = false
        view.autoenablesDefaultLighting = false
        view.antialiasingMode = .multisampling4X
        view.preferredFramesPerSecond = 60
        return view
    }

    func update(value: Int, isRolling: Bool, onSettled: (() -> Void)?) {
        self.onSettled = onSettled

        if isRolling {
            let suppliedValue = clampedDieValue(value, fallback: decorativeValue)
            targetValue = suppliedValue
            if !wasRolling && !isAnimating {
                startRoll(to: suppliedValue)
            }
        } else if wasRolling {
            let suppliedValue = clampedDieValue(value, fallback: targetValue)
            targetValue = suppliedValue
            if !isAnimating {
                setValue(suppliedValue, animated: true)
            }
        } else if !isAnimating, displayedValue != value {
            setValue(value, animated: false)
        }

        wasRolling = isRolling
    }

    private func configureScene() {
        scene.background.contents = UIColor.clear
        scene.rootNode.addChildNode(dieNode)
        dieNode.simdPosition = basePosition
        buildDie()
        addShadowPlane()
        addCamera()
        addLights()
        setValue(0, animated: false)
    }

    private func buildDie() {
        let box = SCNBox(
            width: dieSize,
            height: dieSize,
            length: dieSize,
            chamferRadius: dieSize * 0.205
        )
        box.chamferSegmentCount = 14

        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = UIColor(red: 245.0 / 255.0, green: 242.0 / 255.0, blue: 230.0 / 255.0, alpha: 1.0)
        material.roughness.contents = 0.32
        material.metalness.contents = 0.0
        material.clearCoat.contents = 0.06
        material.clearCoatRoughness.contents = 0.58
        material.ambientOcclusion.contents = UIColor(white: 0.78, alpha: 1.0)
        box.materials = Array(repeating: material, count: 6)

        dieNode.geometry = box
        dieNode.castsShadow = true
        addPips()
    }

    private func addPips() {
        let pipMaterial = SCNMaterial()
        pipMaterial.lightingModel = .physicallyBased
        pipMaterial.diffuse.contents = UIColor(red: 0.055, green: 0.055, blue: 0.052, alpha: 1.0)
        pipMaterial.roughness.contents = 0.76
        pipMaterial.metalness.contents = 0.0

        let innerShadowMaterial = SCNMaterial()
        innerShadowMaterial.lightingModel = .constant
        innerShadowMaterial.diffuse.contents = UIColor.black.withAlphaComponent(0.34)
        innerShadowMaterial.transparency = 0.52
        innerShadowMaterial.writesToDepthBuffer = false

        let half = Float(dieSize / 2)
        let inset = Float(pipDepth * 0.20)
        let offset = Float(dieSize * 0.225)

        for face in diceFaces {
            for point in pipLayout(for: face.value) {
                let localPosition = face.normal * (half + inset)
                    + face.right * (Float(point.x) * offset)
                    + face.up * (Float(point.y) * offset)
                let orientation = rotation(from: SIMD3<Float>(0, 1, 0), to: face.normal)

                let shadowGeometry = SCNCylinder(radius: pipRadius * 1.16, height: pipDepth * 0.45)
                shadowGeometry.radialSegmentCount = 24
                shadowGeometry.heightSegmentCount = 1
                shadowGeometry.materials = [innerShadowMaterial]

                let shadowNode = SCNNode(geometry: shadowGeometry)
                shadowNode.simdPosition = localPosition - face.normal * Float(pipDepth * 0.17)
                shadowNode.simdOrientation = orientation
                shadowNode.castsShadow = false
                dieNode.addChildNode(shadowNode)

                let pipGeometry = SCNCylinder(radius: pipRadius, height: pipDepth * 0.44)
                pipGeometry.radialSegmentCount = 24
                pipGeometry.heightSegmentCount = 1
                pipGeometry.materials = [pipMaterial]

                let pipNode = SCNNode(geometry: pipGeometry)
                pipNode.simdPosition = localPosition + face.normal * Float(pipDepth * 0.08)
                pipNode.simdOrientation = orientation
                pipNode.castsShadow = false
                dieNode.addChildNode(pipNode)
            }
        }
    }

    private func addShadowPlane() {
        let receiverPlane = SCNPlane(width: 12, height: 12)
        let receiverMaterial = SCNMaterial()
        receiverMaterial.lightingModel = .shadowOnly
        receiverMaterial.diffuse.contents = UIColor.black
        receiverMaterial.writesToDepthBuffer = true
        receiverMaterial.readsFromDepthBuffer = true
        receiverPlane.materials = [receiverMaterial]

        let receiverNode = SCNNode(geometry: receiverPlane)
        receiverNode.eulerAngles.x = -.pi / 2
        receiverNode.position = SCNVector3(0, -0.522, 0)
        receiverNode.castsShadow = false
        receiverNode.renderingOrder = -2
        scene.rootNode.addChildNode(receiverNode)

        let contactPlane = SCNPlane(width: 1.08, height: 0.40)
        let contactMaterial = SCNMaterial()
        contactMaterial.lightingModel = .constant
        contactMaterial.diffuse.contents = Self.contactShadowImage
        contactMaterial.transparency = 0.78
        contactMaterial.blendMode = .multiply
        contactMaterial.writesToDepthBuffer = false
        contactMaterial.readsFromDepthBuffer = false
        contactPlane.materials = [contactMaterial]

        contactShadowNode.geometry = contactPlane
        contactShadowNode.eulerAngles.x = -.pi / 2
        contactShadowNode.castsShadow = false
        contactShadowNode.renderingOrder = -1
        scene.rootNode.addChildNode(contactShadowNode)
        updateContactShadow(for: basePosition)
    }

    private func addCamera() {
        let camera = SCNCamera()
        camera.fieldOfView = 40
        camera.wantsHDR = true
        camera.bloomIntensity = 0.01
        camera.bloomThreshold = 0.98
        camera.contrast = 1.02
        camera.saturation = 0.98

        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0.95, 1.42, 2.08)
        cameraNode.look(at: SCNVector3(0, 0.04, 0))
        scene.rootNode.addChildNode(cameraNode)
    }

    private func addLights() {
        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.color = UIColor(white: 0.92, alpha: 1.0)
        ambient.intensity = 155

        let ambientNode = SCNNode()
        ambientNode.light = ambient
        scene.rootNode.addChildNode(ambientNode)

        let key = SCNLight()
        key.type = .directional
        key.color = UIColor(white: 0.98, alpha: 1.0)
        key.intensity = 740
        key.castsShadow = true
        key.shadowMode = .deferred
        key.shadowRadius = 7
        key.shadowSampleCount = 24

        let keyNode = SCNNode()
        keyNode.light = key
        keyNode.position = SCNVector3(-1.9, 2.35, 1.45)
        keyNode.look(at: SCNVector3(0.02, -0.04, 0))
        scene.rootNode.addChildNode(keyNode)
    }

    private func startRoll(to value: Int) {
        dieNode.removeAllActions()
        isAnimating = true
        targetValue = value
        finalYaw = randomFinalYaw()

        let wait = SCNAction.wait(duration: Double(dieIndex) * 0.05)
        let tumble = SCNAction.customAction(duration: 0.70) { [weak self] node, elapsed in
            guard let self else { return }
            let progress = Float(elapsed / 0.70)
            let eased = self.smoothstep(progress)
            let spinX = (Float.pi * (4.0 + Float(self.dieIndex) * 0.42)) * eased
            let spinY = (Float.pi * (3.1 + Float(self.dieIndex) * 0.35)) * eased
            let spinZ = (Float.pi * (2.4 - Float(self.dieIndex) * 0.18)) * eased
            let spin = simd_quatf(angle: spinX, axis: SIMD3<Float>(1, 0.22, 0.12).normalized)
                * simd_quatf(angle: spinY, axis: SIMD3<Float>(0.18, 1, 0.25).normalized)
                * simd_quatf(angle: spinZ, axis: SIMD3<Float>(0.14, 0.26, 1).normalized)
            node.simdOrientation = self.orientation(for: value) * spin

            let hop = sin(Float.pi * progress) * 0.22
            let bounce = progress > 0.82 ? sin((progress - 0.82) / 0.18 * Float.pi) * 0.035 : 0
            let sideways = sin(Float.pi * progress) * (self.dieIndex == 0 ? -0.055 : 0.055)
            let position = SIMD3<Float>(sideways, hop + bounce, 0)
            node.simdPosition = position
            self.updateContactShadow(for: position)
        }

        let settle = SCNAction.customAction(duration: 0.12) { [weak self] node, elapsed in
            guard let self else { return }
            let progress = Float(elapsed / 0.12)
            let eased = self.smoothstep(progress)
            let position = simd_mix(node.simdPosition, self.basePosition, SIMD3<Float>(repeating: eased))
            node.simdPosition = position
            node.simdOrientation = simd_slerp(node.simdOrientation, self.orientation(for: value), eased)
            self.updateContactShadow(for: position)
        }

        let finish = SCNAction.run { [weak self] _ in
            guard let self else { return }
            self.displayedValue = value
            self.dieNode.simdPosition = self.basePosition
            self.dieNode.simdOrientation = self.orientation(for: value)
            self.updateContactShadow(for: self.basePosition)
            self.isAnimating = false
            self.onSettled?()
        }

        dieNode.runAction(.sequence([wait, tumble, settle, finish]), forKey: "roll")
    }

    private func setValue(_ value: Int, animated: Bool) {
        let displayValue = clampedDieValue(value, fallback: decorativeValue)
        displayedValue = value
        finalYaw = stableYaw(for: displayValue)
        let orientation = orientation(for: displayValue)

        dieNode.removeAllActions()
        if animated {
            isAnimating = true
            let startOrientation = dieNode.simdOrientation
            let action = SCNAction.customAction(duration: 0.18) { [weak self] node, elapsed in
                guard let self else { return }
                let progress = self.smoothstep(Float(elapsed / 0.18))
                node.simdOrientation = simd_slerp(startOrientation, orientation, progress)
                let position = simd_mix(node.simdPosition, self.basePosition, SIMD3<Float>(repeating: progress))
                node.simdPosition = position
                self.updateContactShadow(for: position)
            }
            dieNode.runAction(.sequence([action, .run { [weak self] _ in
                self?.dieNode.simdOrientation = orientation
                self?.dieNode.simdPosition = self?.basePosition ?? .zero
                self?.updateContactShadow(for: self?.basePosition ?? .zero)
                self?.isAnimating = false
            }]))
        } else {
            dieNode.simdOrientation = orientation
            dieNode.simdPosition = basePosition
            updateContactShadow(for: basePosition)
        }
    }

    private func orientation(for value: Int) -> simd_quatf {
        let faceNormal: SIMD3<Float>
        switch value {
        case 1: faceNormal = SIMD3<Float>(0, 1, 0)
        case 2: faceNormal = SIMD3<Float>(0, 0, 1)
        case 3: faceNormal = SIMD3<Float>(1, 0, 0)
        case 4: faceNormal = SIMD3<Float>(-1, 0, 0)
        case 5: faceNormal = SIMD3<Float>(0, 0, -1)
        case 6: faceNormal = SIMD3<Float>(0, -1, 0)
        default: faceNormal = SIMD3<Float>(0, 1, 0)
        }

        let bringFaceUp = rotation(from: faceNormal, to: SIMD3<Float>(0, 1, 0))
        let yaw = simd_quatf(angle: finalYaw, axis: SIMD3<Float>(0, 1, 0))
        return yaw * bringFaceUp
    }

    private func stableYaw(for value: Int) -> Float {
        Float((dieIndex == 0 ? -12.0 : 16.0) + Double(value) * 5.0) * .pi / 180
    }

    private func updateContactShadow(for diePosition: SIMD3<Float>) {
        let lift = max(0, diePosition.y)
        let spread = 1.0 + CGFloat(lift) * 1.45
        contactShadowNode.position = SCNVector3(diePosition.x - 0.025, -0.518, diePosition.z + 0.035)
        contactShadowNode.scale = SCNVector3(spread, spread, 1)
        contactShadowNode.opacity = max(0.28, 0.88 - CGFloat(lift) * 1.9)
    }

    private func randomFinalYaw() -> Float {
        let base = dieIndex == 0 ? Double.random(in: -18 ... -6) : Double.random(in: 8 ... 22)
        return Float(base) * .pi / 180
    }

    private func clampedDieValue(_ value: Int, fallback: Int) -> Int {
        (1...6).contains(value) ? value : fallback
    }

    private var decorativeValue: Int {
        dieIndex.isMultiple(of: 2) ? 1 : 6
    }

    private func smoothstep(_ value: Float) -> Float {
        let x = min(1, max(0, value))
        return x * x * (3 - 2 * x)
    }
}

private struct DiceFace {
    let value: Int
    let normal: SIMD3<Float>
    let right: SIMD3<Float>
    let up: SIMD3<Float>
}

private let diceFaces: [DiceFace] = [
    DiceFace(value: 1, normal: SIMD3<Float>(0, 1, 0), right: SIMD3<Float>(1, 0, 0), up: SIMD3<Float>(0, 0, -1)),
    DiceFace(value: 6, normal: SIMD3<Float>(0, -1, 0), right: SIMD3<Float>(1, 0, 0), up: SIMD3<Float>(0, 0, 1)),
    DiceFace(value: 2, normal: SIMD3<Float>(0, 0, 1), right: SIMD3<Float>(1, 0, 0), up: SIMD3<Float>(0, 1, 0)),
    DiceFace(value: 5, normal: SIMD3<Float>(0, 0, -1), right: SIMD3<Float>(-1, 0, 0), up: SIMD3<Float>(0, 1, 0)),
    DiceFace(value: 3, normal: SIMD3<Float>(1, 0, 0), right: SIMD3<Float>(0, 0, -1), up: SIMD3<Float>(0, 1, 0)),
    DiceFace(value: 4, normal: SIMD3<Float>(-1, 0, 0), right: SIMD3<Float>(0, 0, 1), up: SIMD3<Float>(0, 1, 0))
]

private func pipLayout(for value: Int) -> [CGPoint] {
    switch value {
    case 1:
        return [CGPoint(x: 0, y: 0)]
    case 2:
        return [CGPoint(x: 1, y: 1), CGPoint(x: -1, y: -1)]
    case 3:
        return [CGPoint(x: 1, y: 1), CGPoint(x: 0, y: 0), CGPoint(x: -1, y: -1)]
    case 4:
        return [CGPoint(x: -1, y: 1), CGPoint(x: 1, y: 1), CGPoint(x: -1, y: -1), CGPoint(x: 1, y: -1)]
    case 5:
        return [CGPoint(x: -1, y: 1), CGPoint(x: 1, y: 1), CGPoint(x: 0, y: 0), CGPoint(x: -1, y: -1), CGPoint(x: 1, y: -1)]
    case 6:
        return [CGPoint(x: -1, y: 1), CGPoint(x: 1, y: 1), CGPoint(x: -1, y: 0), CGPoint(x: 1, y: 0), CGPoint(x: -1, y: -1), CGPoint(x: 1, y: -1)]
    default:
        return []
    }
}

private func rotation(from source: SIMD3<Float>, to destination: SIMD3<Float>) -> simd_quatf {
    let fromVector = source.normalized
    let toVector = destination.normalized
    let dotProduct = simd_dot(fromVector, toVector)

    if dotProduct > 0.9999 {
        return simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))
    }

    if dotProduct < -0.9999 {
        let fallbackAxis = abs(fromVector.x) < 0.8 ? SIMD3<Float>(1, 0, 0) : SIMD3<Float>(0, 0, 1)
        return simd_quatf(angle: .pi, axis: simd_cross(fromVector, fallbackAxis).normalized)
    }

    let axis = simd_cross(fromVector, toVector).normalized
    return simd_quatf(angle: acos(dotProduct), axis: axis)
}

private extension SIMD3 where Scalar == Float {
    var normalized: SIMD3<Float> {
        let length = simd_length(self)
        guard length > 0 else { return self }
        return self / length
    }
}
