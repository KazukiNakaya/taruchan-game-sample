# Blender MCP 用プロンプト: 待機・小走り・クンクン・おすわり・掘る のアニメ作成

Blender MCP を操作する Claude に、そのまま貼り付けて使う指示書。
ゲーム側は、ここで決めたアニメ名が `taruchan_light_walk.glb` に入っていれば、自動でそのアニメを使う(無ければ仮表現のまま)。

---

## 依頼: たるちゃんの追加アニメ5種の作成と書き出し

### 作業ファイル(リポジトリ: C:\Users\kazuk\Documents\Repository\taruchan-game-sample)
- 作業元: `models/_blend/taruchan_light_rig.blend`(現行モデルのリグ。ボーン28本、小文字名: `root` `hips` `chest` `neck` `head` `ear_*` `tail_1`〜`tail_3`、四肢 `back_*` `front_*` の `_L`/`_R`)
- 書き出し先: `models/taruchan/taruchan_light_walk.glb` を**上書き**。既存のアクション `walk-loop` `jump_start` `jump_air-loop` `jump_land` は消さずに、同じファイルに含める。上書き前にバックアップを `models/_backup/` に取る(`.gitignore` 対象)
- 犬の前方は Blender では -Y、glTF では +Z。四つ足で、体高は約0.4m、接地済み

### 作るアクション(名前は一字一句この通りにする)
Godot は名前の `-loop` 接尾辞で自動ループ化し、接尾辞を外した名前(`idle` など)で読み込む。

| アクション名 | 長さ | 内容 |
|---|---|---|
| `idle-loop` | 2.0秒(48f/24fps) | 立ち止まって呼吸する。胸と背中が小さく上下、耳としっぽがわずかに動く。足は動かさない |
| `run-loop` | 0.5秒(12f)で1サイクル | 小走り。`walk-loop` より足の振りを大きく、体の上下動も大きく。四つ足の駆け足(ギャロップではなく速足のトロット) |
| `sniff-loop` | 1.5秒(36f) | 立ったまま頭を下げて地面を嗅ぐ。鼻先が地面近くに下がる。鼻先がぴくぴく小刻みに動く。前足は地面から浮かない(動画用の `sanpo` アクションの嗅ぐ部分を参考に流用してよい) |
| `sit_start` | 0.8秒 | 立ちから、お尻を落として前足を立てたおすわりになる(1回再生) |
| `sit_idle-loop` | 2.0秒 | おすわりで止まったまま、呼吸と耳・しっぽの小さな動き |
| `sit_end` | 0.6秒 | おすわりから立ち姿に戻る(1回再生) |
| `dig-loop` | 0.6秒(14f) | 前足で交互に地面を掻く。頭は下げる。体はその場から動かさない |

### 共通ルール
- ルートモーションなし(その場の動き)。`root`/`hips` の水平移動キーを入れない
- Hips のスケールは全キーで 1.0。位置・回転はレスト姿勢からの相対で、体が地面にめり込まない・浮かない
- ループアニメは先頭と末尾を同じ姿勢にし、最終フレームを重複させない。全フレームを焼き込む(F-Curveの Cycles モディファイアは使わない)
- 首(`neck` `head`)は、ゲーム側の LookAtModifier3D が上書きするので、動きは最小限でよい。ただし `sniff-loop` `dig-loop` の頭を下げるポーズは、アニメ側に入れる
- しっぽ(`tail_1`〜`tail_3`)は、ゲーム側でも揺らすので、アニメ側では揺れを小さめにする
- Blender 5.x のアクションはレイヤー構造(`action.layers[].strips[].channelbags[].fcurves`)。F-Curve を直接触るときは注意
- 元の顔が犬自身の右にねじれているモデルのため、頭を左に大きく振らせない

### 確認(必須)
Godot 4.7 で見た目を確認する。ヘッドレスは描画されないので、実ウィンドウで画像を保存して見る。
- Godot: `C:\Users\kazuk\Documents\Program Files\Godot\Godot_v4.7.2-stable_win64_console.exe`
- 7つのアニメが `AnimationPlayer` に `idle` `run` `sniff` `sit_start` `sit_idle` `sit_end` `dig` の名前で入っている(ループは loop_mode=1)。既存の `walk` `jump_start` `jump_air` `jump_land` も残っている
- 各アニメを再生して、姿勢が崩れない、足が地面に刺さらない、ループの継ぎ目でカクつかないことを画像で確認する

### 完了条件
- 上記確認がすべて通る
- 変更したファイル(`models/_blend/taruchan_light_rig.blend`、`models/taruchan/taruchan_light_walk.glb`)を報告する。コミットはしない
