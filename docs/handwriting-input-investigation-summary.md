# 手書き入力「書けない／見えない」調査・実装まとめ

## 方針（実装の流れ）

1. **原因の切り分け**: デモモード無効化 → ヒットテスト → PencilKit 設定 → 表示レイヤ
2. **タッチが届くか**: まずボタンが押せるか → 次に `canvasViewDrawingDidChange` で描画データが更新されるか
3. **表示の問題**: データは入っているのに線が見えない → レイヤ合成・不透明化を試す
4. **認識**: 線が見えないままでは Vision 用画像も期待どおりにならない可能性あり（今後の対応）

---

## 変更 → フィードバック一覧

### 1. デモモードのデフォルト変更

| 変更 | フィードバック |
|------|----------------|
| `SemanticGameController`: `isDemoMode` のデフォルトを `true` → `false` に変更。起動時から手書きエリアを有効に。 | ボタン（Clear, Recognize & Drop など）は押せるようになった。一方で、キャンバス上を指・ペンでなぞっても**線は出ず、反応しない**。 |

→ **結論**: デモ無効化は有効（操作可能になった）。「書けない」原因は別にあり。

---

### 2. キャンバス周りのヒットテスト（contentShape）

| 変更 | フィードバック |
|------|----------------|
| `HandwritingCanvasView` の `canvasArea`（ZStack）に `.contentShape(Rectangle())` を追加。キャンバス領域全体をヒット対象に。 | まだ指・ペンで書けない。後続調査で「ZStack の contentShape がタッチを消費し、PKCanvasView に届いていない可能性」が判明。 |

→ **結論**: キャンバス**自体**に contentShape を付けると、SwiftUI がタッチを処理し、UIKit の PKCanvasView に渡らない可能性あり。**後に削除**。

---

### 3. 入力エリア全体のヒットテスト

| 変更 | フィードバック |
|------|----------------|
| `ContentView` の `inputArea`（VStack）に `.contentShape(Rectangle())` を追加。入力カード全体でタッチを確実に受け、下の SceneView に流れないように。 | ボタンが押しやすくなった。キャンバス上の描画は依然として反応せず。 |

→ **結論**: 入力エリアの「ボタンが押せる」という意味では有効。**現状も維持**（`ContentView.swift` 249 行目）。

---

### 4. ZStack の構成変更と contentShape 削除

| 変更 | フィードバック |
|------|----------------|
| `canvasArea` の ZStack から `.contentShape(Rectangle())` を**削除**。描画レイヤの順序を変更し、**HandwritingCanvasView を最前面**（ZStack の最後）に。ガイド・プレースホルダーは下層で `.allowsHitTesting(false)` のまま。 | タッチがキャンバスに届くかはこの時点では未確認。次の「CanvasHostView」と合わせてタッチ経路を確保。 |

→ **結論**: キャンバスが最前面でタッチを受けやすくする方針。contentShape はキャンバス用には使わない。

---

### 5. キャンバスに明示的な frame

| 変更 | フィードバック |
|------|----------------|
| `HandwritingCanvasView` に `.frame(maxWidth: .infinity, minHeight: 120, maxHeight: 120)` を付与。レイアウトで確実にサイズが決まるように。 | 単体では「見えない」問題は解消せず。レイアウトの一環として維持。 |

---

### 6. CanvasHostView（UIKit ラッパー）の導入

| 変更 | フィードバック |
|------|----------------|
| PKCanvasView を直接返すのではなく、**CanvasHostView**（UIView サブクラス）でラップ。`hitTest(_:with:)` で「自分に当たった場合は PKCanvasView を返す」ようにし、SwiftUI のヒットテスト不具合を回避。`layoutSubviews` で `canvasView.frame = bounds` を設定。 | 実機（iPad）でペンをキャンバスに当てて動かすと、**`[HandwritingCanvasView] drawing changed, bounds=...` がログに出る**。ペンを離したタイミングで出ることが多い。 |

→ **結論**: **タッチは PKCanvasView まで届き、PKDrawing は更新されている。**「書けない」のではなく「**線が画面に描画されていない**」状態と判明。

---

### 7. アクセスレベル（CanvasHostView）

| 変更 | フィードバック |
|------|----------------|
| `CanvasHostView` を `private` → `fileprivate` にすると、`makeUIView` / `updateUIView` が「fileprivate な型を返す/受け取る」としてエラーに。`fileprivate` を外して **internal（`final class CanvasHostView`）** に。 | コンパイルエラー解消。 |

---

### 8. デバッグ用 print の追加

| 変更 | フィードバック |
|------|----------------|
| `Coordinator.canvasViewDrawingDidChange` 内で `print("[HandwritingCanvasView] drawing changed, bounds=\(canvasView.drawing.bounds)")` を追加。 | ペンを離すたびに bounds がログに出る（例: `(282.0, 65.0, 40.0, 19.0)` → 続けて書くと `(240.0, 31.0, 262.0, 81.0)` など）。**描画データは確実に更新されている。** |

→ **結論**: 入力経路は問題なし。原因は「**表示レイヤが描画を出していない**」側。

---

### 9. PKCanvasView の不透明化と背景の統一

| 変更 | フィードバック |
|------|----------------|
| `canvas.isOpaque = true` に変更（Metal/SceneView 上でも描画が見えるよう不透明レイヤとして扱う）。`canvasArea` の `.background(Color.white)` を削除し、白背景は PKCanvasView の `backgroundColor = .white` のみに。 | 線は依然として**表示されない**。Recognize & Drop で「Could not recognize」のまま。 |

→ **結論**: レイヤの不透明化だけでは表示問題は解消せず。**次の候補**: インクの太さ・色の変更、または PencilKit の描画レイヤが別ビューで隠れていないかの確認。

---

### 10. その他（ログ・環境）

| 事象 | 対応・結論 |
|------|------------|
| `CAMetalDrawable setDirtyRect:` の Uncaught selector 警告 | SceneKit/Metal 側の既知の挙動。実機でも Mac から Run しているとコンソールに出力される。アプリのバグではない。 |
| 「drawing changed がペンを離したときだけ」 | PencilKit の仕様の範囲。離したタイミングで PKDrawing が確定する形で問題なし。 |

---

## 現在のコード上の状態（方針の反映）

| ファイル | 反映している方針 |
|----------|------------------|
| **SemanticGameController** | `isDemoMode = false` で起動時から手書き有効。 |
| **ContentView** | `inputArea` に `.contentShape(Rectangle())` で入力エリアのヒットを確保。 |
| **HandwritingCanvasView** | PKCanvasView を **CanvasHostView** でラップし、`hitTest` でタッチをキャンバスに転送。`drawingPolicy = .anyInput`, `allowsFingerDrawing = true`。`isOpaque = true`。デバッグ用 `print` は未削除。 |
| **HandwritingInputPanel（canvasArea）** | ZStack でキャンバスを最前面。ガイド・プレースホルダーは下層で `allowsHitTesting(false)`。**contentShape は付けない**。`.background(Color.white)` は削除済み。`.frame(maxWidth: .infinity, minHeight: 120, maxHeight: 120)` をキャンバスに付与。 |

---

## 未解決（次の対応候補）

1. **線が画面に表示されない**  
   - インクを太く・色を変える（例: 赤・幅 8〜10）で「見えるか」を確認。  
   - PKCanvasView のレイヤが別ビューで隠れていないか、階層を確認。

2. **Could not recognize**  
   - 表示が直れば、Vision 用画像（`HandwritingCanvasView.image(from:size:)`）にも線が乗り、認識が改善する可能性が高い。  
   - 表示が直らない場合、`image(from:)` に渡す `drawing` と座標・スケールが正しいか確認。

3. **デバッグ用 print**  
   - 原因が分かったら `canvasViewDrawingDidChange` 内の `print` は削除してよい。
