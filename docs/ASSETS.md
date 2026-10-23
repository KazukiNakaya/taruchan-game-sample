# 素材の差し替えガイド

ゲームの素材(モデル・音)は、今は仮のもの(ローポリ・生成した音)が多い。
ここでは、本番の素材に差し替えるときの置き場所・名前・大きさの決まりをまとめる。
共通の決まり: **単位は1m**、モデルは**上が +Y**、**前が -Z**(人や動物が向く向き)。モデルの形式は glb。

## 音(ファイルを同じ名前で置くだけ)

置き換えたい音を、同じ名前・場所のファイルで上書きする(wav / ogg どちらでもよいが、名前の拡張子は変えない)。
名前は `scripts/systems/audio_manager.gd` の `SOUNDS` と、`scripts/player/footsteps.gd` が決めている。

| 音 | ファイル | メモ |
|---|---|---|
| 足音 | `audio/footsteps/{dirt,grass,leaves,water}_{1,2,3}.wav` | 地面の種類×3種類。ランダムに鳴る。短い(0.1〜0.25秒) |
| クンクン | `audio/sfx/sniff_{1,2,3}.wav` | |
| 掘る | `audio/sfx/dig_{1,2}.wav` | |
| 発見 | `audio/sfx/discover.wav` | 1秒前後のジングル |
| ゴール | `audio/sfx/goal.wav` | |
| ジャンプ / 着地 | `audio/sfx/jump.wav`、`audio/sfx/land.wav` | |
| UI | `audio/sfx/ui_click.wav`、`menu_open.wav`、`menu_close.wav` | 全ボタンに自動でつく |
| 鳥の声 | `audio/ambient/bird_{1,2,3,4}.wav` | 森のどこかから、4〜10秒おきに鳴る |
| BGM | `audio/bgm/forest_loop.wav` | ループする曲(読み込み時に自動でループ設定) |

音量のバランスは `AudioManager.BUS_VOLUME_DB`(バスごと)で変える。
音を増やしたい・名前を変えたいときは、`SOUNDS` の表に足す。
仮の音は `tools/generate_audio.py` で作り直せる。

## モデル

| 素材 | 差し替え方 | 大きさ・向き |
|---|---|---|
| たるちゃん | `scenes/player/taruchan.tscn` の Model を差し替え | ボーン名(`head` `chest` `tail_1`〜`tail_3` など)とアニメ名(`idle` `walk` `run` `sniff` `dig` `sit_start` `sit_idle` `sit_end` `jump_start` `jump_air` `jump_land`)を、今のモデルに合わせる |
| 蝶々 | `scenes/items/butterfly.tscn` の `model_scene` ほか | 羽ばたきアニメが入ったモデル。アニメ名・隠すノード・中心のノード・向きは、同じシーンのプロパティで指定。羽を広げた幅は `model_wing_span`(m)。**モデルを設定しない・読めない場合は、仮の板2枚の蝶々になる** |
| いいもの | `data/treasures/*.tres` の `scene` | 原点=底の中心。大きさ約0.1m。設定すると、仮の形・色の代わりに使う |
| 木 | `ForestBuilder.tree_scene`(`scenes/stages/forest_path.tscn` の ForestBuilder) | 1本ぶん。原点=根元、高さ約4m(`tree_model_height`)。幹の太さは `tree_trunk_radius` に合わせる(当たり判定になる)。**メッシュは1つにまとめる** |
| 岩 | `ForestBuilder.rock_scene` | 1個ぶん。原点=底の中心、大きさ約1m。当たり判定は、仮の球のまま |
| 草 | `ForestBuilder.grass_scene` | 1房ぶん。原点=根元、高さ約0.25m |
| 倒木 | `JumpFeatures.log_scene` | 実寸。長さ約3.2m(横向き=X軸方向)、半径約0.13m。原点=底の中心。当たり判定は箱のまま |
| 切り株 | `JumpFeatures.stump_scene` | 実寸。半径約0.3m、高さ0.28m。原点=底の中心。上に乗れる高さ(0.28m)を守る |
| 平たい岩(上に乗る) | `JumpFeatures.rock_perch_scene` | 実寸。半径約0.38m、高さ0.28m。原点=底の中心 |

木・岩・草は、`MultiMesh`(同じ形を大量に並べる仕組み)で置く。そのため、**glb の中の最初のメッシュ1つだけ**を使う。
素材のメッシュが複数に分かれているときは、Blender などで1つにまとめて書き出す。マテリアルはメッシュのものがそのまま使われる。

## 手順の例(木を差し替える)

1. `models/env/tree.glb` のように、木のモデルを置く(`models/env/` はGit管理される)。
2. Godot で `scenes/stages/forest_path.tscn` を開き、ForestBuilder ノードの「Tree Scene」に、置いたglbをドラッグする。
3. 「Tree Trunk Radius」を、幹の太さに合わせる。実行して、幹に当たり判定があるか、大きさが合っているかを見る。

## クレジット(ライセンスのある素材を使うとき)

CC BY などのライセンスの素材は、`README.md` の「クレジット」に、作者・作品名・URL・ライセンスを書く(改変したときは、改変した旨も)。
再配布できないライセンスの素材は、リポジトリに入れない(`.gitignore` で除外する)。
