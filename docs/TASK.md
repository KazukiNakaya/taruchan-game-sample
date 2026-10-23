# タスク計画

実装方針は [CONCEPT.md](CONCEPT.md) を基準とする。作業ブランチは `step<番号>/<内容>`、Step完了ごとにPR→Squashマージ。
テストは自動テストを使わず、Stepごとに手動で動作確認する。

## 決定事項
- 視点は三人称(後ろから)、いいものはその場で回収(MVP)(2026-10-19)
- GDScript は型ヒントあり、`class_name` を付ける(2026-10-19)
- 自動テスト(GUT等)は入れない(2026-10-19)
- ジャンプを入れる。操作は Space / パッド B(○)。クンクン中・おすわり中は跳べない(2026-10-23)
- 未作成のアニメ(待機・小走り・クンクン・おすわり・掘る)は、仮実装で先に進める。本番アニメはBlender側で作成して差し替える(2026-10-23)
- 効果音・BGMは、生成した仮素材で進める。本番素材に同名で差し替える(2026-10-23)
- v0.3 以降は、蝶々の寄り道イベントのみ実装。季節/時間帯・動物・追加ステージは保留(2026-10-23)

## 完了したStep

- [x] **Step 0 準備** (`step0/setup`): フォルダ作成、入力マップ追加、Meshy元データを退避、.gitignore整理
- [x] **Step 1 歩ける (M1)** (`step1/walk`): テスト平面、たるちゃん移動、追従カメラ、歩きアニメ
- [x] **Step 2 見る (M2)** (`step2/head-look`): LookAtModifier3D、左右非対称の可動域、きょろきょろ
- [x] **Step 3 嗅ぐ (M3)** (`step3/sniff`): TreasureData、におい検出、クンクン長押し、リザルト
- [x] **Step 4 森になる (M4)** (`step4/forest`): 森の小道、ライト、フォグ、足音
- [x] **Step 5 残る (M5)** (`step5/diary`): タイトル、日記、図鑑、セーブ、メニュー(Tab/Esc)

## これからのStep

- [x] **Step 6 動きを増やす** (`step6/movement`): アニメの状態管理(待機/歩き/小走り/ジャンプ)、小走り(Shift)のアニメ連動、ジャンプ(Space/パッドB: jump_start→jump_air→jump_land)、`jump` 入力マップ追加。本番アニメ用のBlender作成プロンプト(`docs/BLENDER_ANIM_PROMPT.md`)を用意し、アニメ名が届いたら自動で差し替わるようにする(`has_animation` で判定)
  - 確認: 止まる/歩く/走る/跳ぶの切り替えが滑らか、着地後に歩きへ戻る
- [x] **Step 7 しっぽとクンクン** (`step7/tail-sniff`): しっぽ振り(`tail_1`〜`tail_3` を SkeletonModifier3D で揺らす。待機=ゆっくり、においに近づくほど速く、発見時は大きく)、クンクン中は首と胸を下げて地面を見る(仮)、カメラが少し寄る、発見時に土が舞う演出(掘る仮演出)
  - 確認: においに近づくとしっぽが速くなる、クンクンで頭が下がる
- [x] **Step 8 おすわり** (`step8/sit`): `sit`(Ctrl / C / パッドY)でおすわり(`sit_start`→`sit_idle`→`sit_end`)。座っている間は動けず、ジャンプ・クンクンもできない。もう一度押すと立つ。座っている間は においの届く半径が1.5倍(`Taruchan.sit_smell_scale`)。ゴールはベンチ(`scenes/stages/bench_goal.tscn`)で、ベンチの前でおすわりするとおさんぽ終了
  - 確認: Ctrl/Cで座る・もう一度で立つ。座ると遠いにおいに首が向く。ベンチの前で座るとリザルトが出る
- [x] **Step 9 効果音とBGM** (`step9/audio`): 生成した仮素材(`audio/`)で、鳥の声(ランダム間隔)、クンクン音(においが近いほど間隔が短い)、発見ジングル、控えめなBGM、メニュー/UIの音。`AudioManager`(autoload)で音量を一元管理
  - 確認: 森で鳥の声が時々鳴る、クンクンで音が出る、発見で音が鳴る
- [x] **Step 10 蝶々の寄り道** (`step10/butterfly`): 蝶々が飛んでくる。追いかけると隠しアイテムの場所へ案内される。蝶々は首の注目先の優先度2(においの次)。羽ばたきは仮の動き
  - 確認: 蝶々を追うとアイテムの場所に着き、クンクンで発見できる
- [ ] **Step 11 素材差し替えの準備** (`step11/asset-swap`): 本番素材の置き場・名前・サイズの規約を `docs/ASSETS.md` にまとめ、`ForestBuilder` の木・岩・草、いいもの、足音・効果音を、ファイルを置けば差し替わる形にする。素材そのもの(Meshy製)の作成は別途(Blender/Meshy側)
  - 確認: 仮のglbを1つ置いて差し替わること

## 保留(今回は実装しない)
- 季節・時間帯のバリエーション(朝/夕方、秋の落ち葉)
- 他の動物(リス、カエル)との出会い、水たまり・ベンチの寄り道
- ステージ追加(公園、海辺)

## メモ(現状・既知の課題)
- 使用モデルは `models/taruchan/taruchan_light_walk.glb`(ボーン28本・小文字名 `root`/`hips`/`chest`/`neck`/`head`/`tail_1`〜`tail_3` など)。アニメは `walk`(1秒ループ)、`jump_start`/`jump_air`(ループ)/`jump_land`、`idle`(2秒ループ)、`run`(0.5秒ループ)、`sniff`(1.5秒ループ)、`sit_start`/`sit_idle`(ループ)/`sit_end`、`dig`(0.58秒ループ)。`TaruchanAnimator` は idle/run を自動で使う(小走りアニメの基準速度 `RUN_ANIM_SPEED` = 0.9 m/s は実機で足滑りを見て調整)
- 首の可動域(右45°/左20°、上35°/下45°)と追従速度は `HeadLook` のエクスポート変数。`LookAtModifier3D` は head の forward=+Y、回転軸=Z。胸(chest)にも影響度0.3で適用。左の可動域を超える注目先は、立ち止まっているとき体ごと向く
- いいもの5種(どんぐり/木の枝/テニスボール/骨のおやつ/四つ葉)は仮の形(色違いプリミティブ)。`data/treasures/*.tres` の `scene` に Meshy 製を設定すれば差し替えられる。全種類の一覧は `data/treasure_catalog.tres`(配置の抽選と図鑑で共用)
- 森は仮のローポリ(`ForestBuilder` が起動時に生成)。メインシーンは `scenes/main.tscn`(タイトル)から `scenes/stages/forest_path.tscn`(小道約40m)。`test_plane.tscn` は動作確認用に残す
- 効果音・BGM・環境音は `tools/generate_audio.py` で生成した仮素材(`audio/sfx/` `audio/ambient/` `audio/bgm/`)。`AudioManager`(autoload)が名前で読み込み、バス(Music/SFX/Ambient/UI)の音量を `BUS_VOLUME_DB` で一元管理する。本番素材は同じファイル名で差し替える。どのボタンにもクリック音が付く
- 足音はノイズから生成したWAV(`audio/footsteps/`、土/草/葉っぱ×3種)の仮素材。足元の地面は `ForestBuilder.surface_at()` で判定
- メニューは Tab / Esc(パッドは Start)で開閉し、開いている間はゲームを止める。おさんぽ中のメニューに「タイトルにもどる」「おわる」あり(途中のおさんぽは保存されない)
- セーブは `user://save.tres`(図鑑の解放状況と日記)。ゴール到達でおさんぽ1回ぶんを日記に追加して保存する。Windowsでは `%APPDATA%\Godot\app_userdata\taruchan-game-sample\`
- 図鑑の未発見は「？？？」の暗い表示(シルエット画像は未対応)
- 蝶々(`Butterfly`)は仮の見た目(板2枚の羽ばたき)。小道の入口近く(z=-7)で待ち、3m以内に近づくと案内を始める。たるちゃんが2.5mより離れると待つ。案内先は小道から4〜8m離れた隠しいいもの(レア度2以上、木に重ならない場所)。発見すると蝶々は飛び去る。`HeadLook` は、においが無いとき6m以内の蝶々を見る
- 木漏れ日(ボリュメトリックフォグ等)は未実装
