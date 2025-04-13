#!/usr/bin/env ruby
# frozen_string_literal: true

require 'sqlite3'
require 'json'
require 'google/protobuf'
require_relative './vector_tile_pb'

# Protocol Bufferの名前空間を設定
VT = VectorTile::Tile

def print_usage
  STDERR.puts 'Usage: ruby main.rb <mbtiles_file>'
  STDERR.puts 'Example: ruby main.rb example.mbtiles'
  exit 1
end

def decode_command(cmd)
  cmd_id = cmd & 0x7
  count = cmd >> 3
  [cmd_id, count]
end

def decode_value(value)
  case
  when value.respond_to?(:string_value) && value.string_value
    value.string_value
  when value.respond_to?(:float_value) && value.float_value
    value.float_value
  when value.respond_to?(:double_value) && value.double_value
    value.double_value
  when value.respond_to?(:int_value) && value.int_value
    value.int_value
  when value.respond_to?(:uint_value) && value.uint_value
    value.uint_value
  when value.respond_to?(:sint_value) && value.sint_value
    value.sint_value
  when value.respond_to?(:bool_value) && value.bool_value
    value.bool_value
  else
    nil
  end
end

def decode_geometry(geometry)
  coordinates = []
  i = 0
  x = 0
  y = 0

  while i < geometry.length
    cmd = geometry[i]
    cmd_id, count = decode_command(cmd)
    i += 1

    case cmd_id
    when 1 # MoveTo
      count.times do
        dx = geometry[i]
        dy = geometry[i + 1]
        x += ((dx >> 1) ^ (-(dx & 1)))
        y += ((dy >> 1) ^ (-(dy & 1)))
        coordinates << [x, y]
        i += 2
      end
    when 2 # LineTo
      count.times do
        dx = geometry[i]
        dy = geometry[i + 1]
        x += ((dx >> 1) ^ (-(dx & 1)))
        y += ((dy >> 1) ^ (-(dy & 1)))
        coordinates << [x, y]
        i += 2
      end
    when 7 # ClosePath
      # 最初の点を再度追加
      coordinates << coordinates.first if coordinates.any?
    end
  end

  coordinates
end

def extract_tiles(db_path)
  begin
    db = SQLite3::Database.new(db_path)
    query = 'SELECT zoom_level, tile_column, tile_row, tile_data FROM tiles'
    
    db.execute(query) do |row|
      z, x, y, data = row
      flipped_y = (1 << z) - 1 - y
      
      # タイル情報をヘッダーとして出力
      puts "=== Tile: z=#{z}, x=#{x}, y=#{flipped_y} ==="
      
      # MVTデータをデコード
      tile = VT.decode(data)
      
      # レイヤー情報を出力
      tile.layers.each do |layer|
        puts "Layer: #{layer.name}"
        puts "Version: #{layer.version}"
        puts "Extent: #{layer.extent}"
        
        # フィーチャー情報を出力
        layer.features.each do |feature|
          puts "\nFeature ID: #{feature.id}"
          type_name = case feature.type
          when VT::GeomType::UNKNOWN
            "UNKNOWN"
          when VT::GeomType::POINT
            "POINT"
          when VT::GeomType::LINESTRING
            "LINESTRING"
          when VT::GeomType::POLYGON
            "POLYGON"
          else
            "UNKNOWN"
          end
          puts "Type: #{type_name}"
          
          # 属性情報を出力
          attributes = {}
          (0...feature.tags.length).step(2) do |i|
            key = layer.keys[feature.tags[i]]
            value = decode_value(layer.values[feature.tags[i + 1]])
            attributes[key] = value
          end
          puts "Attributes: #{JSON.generate(attributes)}"
          
          # ジオメトリを出力
          coords = decode_geometry(feature.geometry)
          puts "Geometry: #{coords.inspect}"
        end
        puts "\n"
      end
      puts "=" * 80
      puts "\n"
    end
    
  rescue SQLite3::Exception => e
    STDERR.puts "Error: #{e.message}"
    exit 1
  rescue Google::Protobuf::ParseError => e
    STDERR.puts "Error parsing MVT data: #{e.message}"
    exit 1
  ensure
    db&.close
  end
end

# メイン処理
if ARGV.length != 1
  print_usage
end

mbtiles_file = ARGV[0]

unless File.exist?(mbtiles_file)
  STDERR.puts "Error: File not found: #{mbtiles_file}"
  exit 1
end

extract_tiles(mbtiles_file)
