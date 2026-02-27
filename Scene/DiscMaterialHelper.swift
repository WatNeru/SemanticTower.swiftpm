import SceneKit
#if canImport(UIKit)
import UIKit
#endif

/// SCNCylinder / SCNShape にマテリアルを割り当てるヘルパー。
enum DiscMaterialHelper {

    /// SCNCylinder 用: マテリアル配列 [側面, 天面, 底面]
    static func applyToCylinder(
        geometry: SCNCylinder,
        baseColor: PlatformColor,
        diskShape: DiskShape,
        topTexture: UIImage
    ) {
        let sideMat = makeSideMaterial(color: baseColor, diskShape: diskShape)
        let topMat = makeFaceMaterial(texture: topTexture, diskShape: diskShape)
        let bottomMat = makeSideMaterial(color: baseColor, diskShape: diskShape)
        geometry.materials = [sideMat, topMat, bottomMat]
    }

    /// SCNShape 用: マテリアル配列 [front, back, side, chamfer]
    static func applyToShape(
        geometry: SCNShape,
        baseColor: PlatformColor,
        diskShape: DiskShape,
        faceTexture: UIImage
    ) {
        let frontMat = makeFaceMaterial(texture: faceTexture, diskShape: diskShape)
        let backMat = makeSideMaterial(color: baseColor, diskShape: diskShape)
        let sideMat = makeSideMaterial(color: baseColor, diskShape: diskShape)
        let chamferMat = makeChamferMaterial(color: baseColor, diskShape: diskShape)
        geometry.materials = [frontMat, backMat, sideMat, chamferMat]
    }

    // MARK: - Material factories

    private static func makeFaceMaterial(
        texture: UIImage,
        diskShape: DiskShape
    ) -> SCNMaterial {
        let mat = SCNMaterial()
        mat.lightingModel = .physicallyBased
        mat.diffuse.contents = texture
        mat.isDoubleSided = false
        applyQuality(to: mat, diskShape: diskShape)
        return mat
    }

    private static func makeSideMaterial(
        color: PlatformColor,
        diskShape: DiskShape
    ) -> SCNMaterial {
        var hue: CGFloat = 0, sat: CGFloat = 0, bri: CGFloat = 0, alpha: CGFloat = 0
        color.getHue(&hue, saturation: &sat, brightness: &bri, alpha: &alpha)
        let sideColor = PlatformColor(
            hue: hue,
            saturation: min(1, sat + 0.05),
            brightness: max(0, bri - 0.10),
            alpha: 1
        )

        let mat = SCNMaterial()
        mat.lightingModel = .physicallyBased
        mat.diffuse.contents = sideColor
        mat.isDoubleSided = false
        applyQuality(to: mat, diskShape: diskShape)
        return mat
    }

    private static func makeChamferMaterial(
        color: PlatformColor,
        diskShape: DiskShape
    ) -> SCNMaterial {
        var hue: CGFloat = 0, sat: CGFloat = 0, bri: CGFloat = 0, alpha: CGFloat = 0
        color.getHue(&hue, saturation: &sat, brightness: &bri, alpha: &alpha)
        let chamferColor = PlatformColor(
            hue: hue,
            saturation: max(0, sat - 0.10),
            brightness: min(1, bri + 0.08),
            alpha: 1
        )

        let mat = SCNMaterial()
        mat.lightingModel = .physicallyBased
        mat.diffuse.contents = chamferColor
        mat.isDoubleSided = false
        applyQuality(to: mat, diskShape: diskShape)
        return mat
    }

    private static func applyQuality(to mat: SCNMaterial, diskShape: DiskShape) {
        switch diskShape {
        case .perfect:
            mat.specular.contents = PlatformColor(white: 0.9, alpha: 1)
            mat.roughness.contents = 0.06
            mat.metalness.contents = 0.08
        case .nice:
            mat.specular.contents = PlatformColor(white: 0.5, alpha: 1)
            mat.roughness.contents = 0.30
            mat.metalness.contents = 0.03
        case .miss:
            mat.specular.contents = PlatformColor(white: 0.15, alpha: 1)
            mat.roughness.contents = 0.65
            mat.metalness.contents = 0
        }
    }
}
