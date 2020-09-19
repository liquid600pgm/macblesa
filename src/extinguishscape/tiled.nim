## Tiled JSON data format.

import std/json
import std/options

type
  # tileset
  TiledTile*[T: enum] = object
    id*: int
    `type`*: T
  TiledTileset*[T: enum] = object
    image*: string
    columns*: uint32
    tilecount*: uint32
    tilewidth*, tileheight*: float32
    tiles*: seq[TiledTile[T]]

  # map

  TiledLayerKind* = enum
    tlkTile = "tilelayer"
    tlkObject = "objectgroup"

  TiledLayerChunk* = object
    x*, y*, width*, height*: int32
    data*: seq[uint32]

  TiledPropertyKind* = enum
    tpkString = "string"
    tpkObject = "object"

  TiledObjectProperty* = object
    name*: string
    `type`*: TiledPropertyKind
    value*: JsonNode

  TiledLayerObject* = object
    id*: uint32
    gid*: Option[int]
    x*, y*: float32
    width*, height*: float32
    name*: string

  TiledLayer* = object
    id*: uint32
    name*: string
    case `type`*: TiledLayerKind
    of tlkTile:
      chunks*: seq[TiledLayerChunk]
      startx*, starty*: int32
      width*, height*: int32
    of tlkObject:
      objects*: seq[TiledLayerObject]

  TiledMap* = object
    width*, height*: uint32
    infinite*: bool
    layers*: seq[TiledLayer]

proc loadTiledTileset*(filename: string, T: type[enum]): TiledTileset[T] =
  json.parseFile(filename).to(TiledTileset[T])

proc loadTiledMap*(filename: string): TiledMap =
  json.parseFile(filename).to(TiledMap)
