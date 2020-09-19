import std/os
import std/tables

import aglet
import rapid/ec
import rapid/ec/physics_aabb
import rapid/game/tilemap
import rapid/game/tilemap_collider
import rapid/graphics
import rapid/physics/aabb

import tiled

type
  TileKind* = enum
    tileNonSolid = "nonsolid"
    tileSolid = "solid"
    tileDecoration = "decoration"
    tileObjPlayer = "obj_player"
    tileObjExtinguisher = "obj_extinguisher"
    tileObjDoor = "obj_door"
    tileObjNpc = "obj_npc"

  MapTileKind = tileNonSolid..tileDecoration

  Tile* = object
    kind*: MapTileKind
    graphic*: int

proc isSolid*(tile: Tile): bool =
  const solidKinds = {tileNonSolid}
  tile.kind notin solidKinds

type
  Tileset* = object
    tileSize*: Vec2f
    columns*: int
    texture*: Texture2D[Rgba8]
    kinds*: seq[TileKind]

  LayerKind* = enum
    lkTile
    lkEntity

  TilemapVertex = object
    position, uv: Vec2f

  TileChunk* = object
    tilemap*: Tilemap[Tile]
    mesh*: Mesh[TilemapVertex]
    collider*: AabbCollider

  Layer* = object
    case kind*: LayerKind
    of lkTile:
      chunkSize*: Vec2i
      chunks*: Table[Vec2i, TileChunk]
    of lkEntity:
      entity*: seq[RootEntity]

  World* = ref object
    tileset*: Tileset
    layers*: Layer

    player*: RootEntity

proc newTileset(window: Window, tiled: TiledTileset): Tileset =
  let image = loadPngImage("data"/"tilesets"/tiled.image)
  result.texture = window.newTexture2D(Rgba8, image)
  result.kinds.setLen(tiled.tilecount)
  for tile in tiled.tiles:
    result.kinds[tile.id] = tile.`type`
  result.tileSize = vec2f(tiled.tilewidth, tiled.tileheight)
  result.columns = tiled.columns.int

proc loadChunk(layer: var Layer, tileset: Tileset,
               tchunk: TiledLayerChunk) =
  let position = vec2i(tchunk.x, tchunk.y) div layer.chunkSize
  var chunk = TileChunk(
    tilemap: newTilemap[Tile](layer.chunkSize, tileset.tileSize)
  )
  for i, gid in tchunk.data:
    let
      x = int32(i mod tchunk.width)
      y = int32(i div tchunk.width)
      kind = tileset.kinds[gid]
    chunk.tilemap[vec2i(x, y)] = Tile(kind: kind, graphic: gid.int)
  # TODO: mesh construction
  chunk.collider = chunk.tilemap.collider
  layer.chunks[position] = chunk

proc loadLayers(world: World, map: TiledMap) =
  for tlayer in map.layers:
    if tlayer.`type` == tlkTile and tlayer.chunks.len == 0: continue
    if tlayer.`type` == tlkObject and tlayer.objects.len == 0: continue

    echo "  - layer ", tlayer.id, " '", tlayer.name, "'"

    var layer = Layer(kind: tlayer.`type`.LayerKind)
    case layer.kind
    of lkTile:
      layer.chunkSize = vec2i(tlayer.chunks[0].width.int32,
                              tlayer.chunks[0].height.int32)
      echo "    chunk size: ", layer.chunkSize
      for chunk in tlayer.chunks:
        layer.loadChunk(world.tileset, chunk)
    of lkEntity:
      discard  # TODO

proc loadWorld*(window: Window, name: string): World =
  echo "loading world: ", name

  new(result)

  echo "- tileset"
  let
    tilesetFilename = addFileExt("data"/"tilesets"/name, "json")
    tileset = loadTiledTileset(tilesetFilename, TileKind)

  result.tileset = newTileset(window, tileset)

  echo "- map"
  let
    mapFilename = addFileExt("data"/"maps"/name, "json")
    map = loadTiledMap(mapFilename)

  result.loadLayers(map)
