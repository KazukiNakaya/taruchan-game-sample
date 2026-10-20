# タスク計画

実装方針は [CONCEPT.md](CONCEPT.md) を基準とする。作業ブランチは `step<番号>/<内容>`、Step完了ごとにPR→Squashマージ。
テストは自動テストを使わず、Stepごとに手動で動作確認する。

## 決定事項(2026-10-19)
- 視点は三人称(後ろから)、いいものはその場で回収(MVP)
- GDScript は型ヒントあり、`class_name` を付ける
- 自動テスト(GUT等)は入れない

## Step一覧

- [x] **Step 0 準備** (`step0/setup`): フォルダ作成、入力マップ追加、Meshy元データを `models/_source/`(.gdignore)へ退避、.gitignore整理
- [x] **Step 1 歩ける (M1)** (`step1/walk`): テスト平面、たるちゃん移動、追従カメラ、待機/歩きアニメ。確認: WASD/パッドで歩ける
- [x] **Step 2 見る (M2)** (`step2/head-look`): LookAtModifier3D、左右非対称の可動域、きょろきょろ。最初に固定ターゲットで首の検証
- [ ] **Step 3 嗅ぐ (M3)** (`step3/sniff`): TreasureData、におい検出、クンクン長押し、リザルト
- [ ] **Step 4 森になる (M4)** (`step4/forest`): 森の小道、ライト、フォグ、足音
- [ ] **Step 5 残る (M5)** (`step5/diary`): 日記、図鑑、セーブ

## 既知の課題
- 使用モデルは `models/taruchan/taruchan_light_walk.glb`(軽量版・歩き `walk` 1秒ループ、ボーン28本・小文字名 `root`/`hips` など)。旧 `taruchan_rigged.glb` はボーン名が異なる。以降のStepのボーン名はこのモデル基準にする
- `walk-loop` は首振り焼き込みの192fのまま。首振りなし24fへ差し替え予定(アニメ名は同じ)
- 待機・小走り・クンクン・おすわり・掘るアニメは未作成
- 首の可動域(右45°/左20°、上35°/下45°)と追従速度は `HeadLook` のエクスポート変数。実機で見て調整する
- `LookAtModifier3D` は head の forward=+Y、回転軸=Z で設定(light_walk のボーン軸基準)。胸(chest)にも影響度0.3で適用。左の可動域を超える注目先は、立ち止まっているとき体ごと向く
- 注目先は仮に `look_target` グループ(テスト平面の赤い球)から探している。Step 3 で SniffSensor に置き換える
