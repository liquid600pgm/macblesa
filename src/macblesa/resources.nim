import aglet
import aglet/window/glfw
import rapid/graphics

import world

type
  CanvasVertex {.requiresInit.} = object
    position, uv: Vec2f

  Game* = ref object
    aglet*: Aglet
    window*: Window
    canvas*: SimpleFramebuffer
    graphics*: Graphics

    canvasScale*: float32
    canvasSize*, canvasPosition*: Vec2f
    canvasRect: Mesh[CanvasVertex]
    canvasProgram: Program[CanvasVertex]

    world*: World

const
  CanvasSize* = vec2i(192, 128)
  DefaultScale = 4

let
  dpDefault* = defaultDrawParams()

proc newGame*(): Game =

  var g = Game()

  echo "initializing aglet"

  g.aglet = initAglet()
  g.aglet.initWindow()

  echo "opening window"

  g.window = g.aglet.newWindowGlfw(
    title = "Extinguishscape",
    width = CanvasSize.x * DefaultScale,
    height = CanvasSize.y * DefaultScale,
    winHints()
  )

  echo "allocating graphics resources"

  g.canvas = g.window.newTexture2D[:Rgba8](CanvasSize).toFramebuffer
  block:
    proc cv(position, uv: Vec2f): CanvasVertex =
      CanvasVertex(position: position, uv: uv)
    g.canvasRect = g.window.newMesh(
      usage = muStatic,
      primitive = dpTriangleStrip,
      vertices = [
        cv(vec2f(0, 0), vec2f(0, 0)),
        cv(vec2f(1, 0), vec2f(1, 0)),
        cv(vec2f(0, 1), vec2f(0, 1)),
        cv(vec2f(1, 1), vec2f(1, 1)),
      ],
    )
  g.canvasProgram = g.window.newProgram[:CanvasVertex](
    vertexSrc = glsl"""
      #version 330 core

      in vec2 position;
      in vec2 uv;

      uniform mat4 transform;

      out Vertex {
        out vec2 uv;
      } frag;

      void main(void)
      {
        gl_Position = transform * vec4(position, 0.0, 1.0);
        frag.uv = uv;
      }
    """,
    fragmentSrc = glsl"""
      #version 330 core

      in Vertex {
        vec2 uv;
      };

      uniform sampler2D canvas;

      out vec4 color;

      void main(void)
      {
        color = texture(canvas, uv);
      }
    """,
  )

  g.graphics = g.window.newGraphics()

  g.world = loadWorld(g.window, "map")

  result = g

proc drawCanvas*(g: Game, target: Target) =

  g.canvasScale = min(g.window.width div g.canvas.width,
                      g.window.height div g.canvas.height).float
  g.canvasSize = g.canvas.size.vec2f * g.canvasScale
  g.canvasPosition = g.window.size.vec2f / 2 - g.canvasSize / 2

  let projection = ortho(left = 0f, right = g.window.width.float32,
                         bottom = g.window.height.float32, top = 0f,
                         zNear = -1.0, zFar = 1.0)
  target.draw(g.canvasProgram, g.canvasRect, uniforms {
    transform: projection * mat4f()
      .translate(g.canvasPosition.vec3(0.0))
      .scale(g.canvasSize.vec3(0.0)),
    canvas: g.canvas.sampler(minFilter = fmNearest, magFilter = fmNearest),
  }, dpDefault)
