import SceneKit
#if canImport(UIKit)
import UIKit
#endif

/// SCNCylinder にマテリアルを割り当てるヘルパー。
/// 天面にテクスチャ、側面・底面にベースカラーを適用。
enum DiscMaterialHelper {
    /// SCNCylinder のマテリアル配列: [側面, 天面, 底面]
    static func apply(
        to geometry: SCNCylinder,
        baseColor: PlatformColor,
        diskShape: DiskShape,
        topTexture: UIImage
    ) {
        let sideMat = makeMaterial(color: baseColor, diskShape: diskShape)
        let topMat = makeMaterial(color: baseColor, diskShape: diskShape)
        topMat.diffuse.contents = topTexture
        let bottomMat = makeMaterial(color: baseColor, diskShape: diskShape)

        geometry.materials = [sideMat, topMat, bottomMat]
    }

    private static func makeMaterial(
        color: PlatformColor,
        diskShape: DiskShape
    ) -> SCNMaterial {
        let mat = SCNMaterial()
        mat.lightingModel = .physicallyBased
        mat.diffuse.contents = color
        mat.isDoubleSided = false

        switch diskShape {
        case .perfect:
            mat.specular.contents = PlatformColor(white: 0.8, alpha: 1)
            mat.roughness.contents = 0.08
            mat.metalness.contents = 0.05
        case .nice:
            mat.specular.contents = PlatformColor(white: 0.5, alpha: 1)
            mat.roughness.contents = 0.25
            mat.metalness.contents = 0.02
        case .miss:
            mat.specular.contents = PlatformColor(white: 0.2, alpha: 1)
            mat.roughness.contents = 0.6
            mat.metalness.contents = 0
        }
        return mat
    }
}
