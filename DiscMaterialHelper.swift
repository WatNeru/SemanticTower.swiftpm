import SceneKit
#if canImport(UIKit)
import UIKit
#endif

/// SCNCylinder に天面テクスチャ + 側面/底面カラーを割り当て。
/// diskShape で質感（光沢・粗さ・金属感）が変化する。
enum DiscMaterialHelper {
    static func apply(
        to geometry: SCNCylinder,
        baseColor: PlatformColor,
        diskShape: DiskShape,
        topTexture: UIImage
    ) {
        let sideMat = makeSideMaterial(color: baseColor, diskShape: diskShape)
        let topMat = makeTopMaterial(texture: topTexture, diskShape: diskShape)
        let bottomMat = makeSideMaterial(color: baseColor, diskShape: diskShape)

        geometry.materials = [sideMat, topMat, bottomMat]
    }

    private static func makeSideMaterial(
        color: PlatformColor,
        diskShape: DiskShape
    ) -> SCNMaterial {
        let mat = SCNMaterial()
        mat.lightingModel = .physicallyBased
        mat.isDoubleSided = false

        var hue: CGFloat = 0, sat: CGFloat = 0, bri: CGFloat = 0, alpha: CGFloat = 0
        color.getHue(&hue, saturation: &sat, brightness: &bri, alpha: &alpha)
        let sideColor = PlatformColor(
            hue: hue,
            saturation: min(1, sat + 0.05),
            brightness: max(0, bri - 0.10),
            alpha: 1
        )
        mat.diffuse.contents = sideColor

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
        return mat
    }

    private static func makeTopMaterial(
        texture: UIImage,
        diskShape: DiskShape
    ) -> SCNMaterial {
        let mat = SCNMaterial()
        mat.lightingModel = .physicallyBased
        mat.diffuse.contents = texture
        mat.isDoubleSided = false

        switch diskShape {
        case .perfect:
            mat.specular.contents = PlatformColor(white: 0.7, alpha: 1)
            mat.roughness.contents = 0.10
            mat.metalness.contents = 0.05
        case .nice:
            mat.specular.contents = PlatformColor(white: 0.4, alpha: 1)
            mat.roughness.contents = 0.35
            mat.metalness.contents = 0.02
        case .miss:
            mat.specular.contents = PlatformColor(white: 0.1, alpha: 1)
            mat.roughness.contents = 0.70
            mat.metalness.contents = 0
        }
        return mat
    }
}
