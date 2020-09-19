import aglet
import rapid/game
import rapid/graphics

import extinguishscape/resources

proc main() =
  var g = newGame()

  runGameWhile not g.window.closeRequested:

    g.window.pollEvents do (event: InputEvent):
      discard

    update:
      discard

    draw step:
      var
        frame = g.window.render()
        canvas = g.canvas.render()

      frame.clearColor(colBlack)

      canvas.clearColor(colWhite)

      g.drawCanvas(frame)

      frame.finish()

when isMainModule: main()
