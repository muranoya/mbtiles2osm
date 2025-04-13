# mbtiles2osm

MVT (Mapbox Vector Tiles) 形式のmbtilesファイルからタイルデータを抽出し、人間が読める形式で出力するツールです。

## 必要条件

- Ruby 2.7以上
- Bundler
- Protocol Buffers Compiler (protoc)

## セットアップ

```bash
bundle install
```

## 使用方法

```bash
ruby src/main.rb <mbtiles_file>
```

### パラメータ

- `mbtiles_file`: 入力となるmbtilesファイルのパス

### 出力形式

各タイルの情報が以下の形式で出力されます：

```
=== Tile: z=0, x=0, y=0 ===
Layer: layer_name
Version: 2
Extent: 4096

Feature ID: 1
Type: POLYGON
Attributes: {"name": "Example", "type": "building"}
Geometry: [[0, 0], [10, 0], [10, 10], [0, 10], [0, 0]]

================================================================================
```

#### 出力項目の説明

- タイル情報
  - `z`: ズームレベル
  - `x`: タイルのX座標
  - `y`: タイルのY座標（Web座標系に変換済み）

- レイヤー情報
  - `Layer`: レイヤー名
  - `Version`: MVTバージョン
  - `Extent`: タイルの範囲（ピクセル単位）

- フィーチャー情報
  - `Feature ID`: フィーチャーの一意識別子
  - `Type`: ジオメトリタイプ（UNKNOWN, POINT, LINESTRING, POLYGON）
  - `Attributes`: フィーチャーの属性情報（JSON形式）
  - `Geometry`: 座標列（相対座標から絶対座標に変換済み）

### 例

```bash
ruby src/main.rb example.mbtiles > decoded_tiles.txt
```

## エラーハンドリング

以下の場合にエラーメッセージを表示します：

- 必要な引数が不足している場合
- 指定されたmbtilesファイルが存在しない場合
- データベースアクセスでエラーが発生した場合
- MVTデータの解析に失敗した場合

## ライセンス

MIT
