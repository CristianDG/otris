package otris

import "core:fmt"
import rl "vendor:raylib"

WINDOW_HEIGHT : i32 : 540
WINDOW_WIDTH : i32 : 960

// NOTE: pode ser enum u16
TetrominoType :: enum {
  I, J, L, S, O, T, Z,
}

TetrominoOrientation :: enum {
  UP, DOWN, LEFT, RIGHT
}

Tetromino :: struct {
  type: TetrominoType,
  orientation: TetrominoOrientation,
}


//var ROTATION_TABLE = map[TetrominoEnum][4]uint16{
//	I: {setGrid([4]uint8{4, 5, 6, 7}), setGrid([4]uint8{2, 6, 10, 14}), setGrid([4]uint8{8, 9, 10, 11}), setGrid([4]uint8{1, 5, 9, 13})},
//	J: {setGrid([4]uint8{4, 5, 6, 10}), setGrid([4]uint8{1, 5, 8, 9}), setGrid([4]uint8{0, 4, 5, 6}), setGrid([4]uint8{1, 2, 5, 9})},
//	L: {setGrid([4]uint8{2, 4, 5, 6}), setGrid([4]uint8{1, 5, 9, 10}), setGrid([4]uint8{4, 5, 6, 8}), setGrid([4]uint8{0, 1, 5, 9})},
//	O: {setGrid([4]uint8{1, 2, 5, 6}), setGrid([4]uint8{1, 2, 5, 6}), setGrid([4]uint8{1, 2, 5, 6}), setGrid([4]uint8{1, 2, 5, 6})},
//	S: {setGrid([4]uint8{1, 2, 4, 5}), setGrid([4]uint8{1, 5, 6, 10}), setGrid([4]uint8{5, 6, 8, 9}), setGrid([4]uint8{0, 4, 5, 9})},
//	Z: {setGrid([4]uint8{0, 1, 5, 6}), setGrid([4]uint8{2, 5, 6, 9}), setGrid([4]uint8{4, 5, 9, 10}), setGrid([4]uint8{1, 4, 5, 8})},
// T: {setGrid([4]uint8{1, 4, 5, 6}), setGrid([4]uint8{1, 5, 9, 6}), setGrid([4]uint8{4, 5, 6, 9}), setGrid([4]uint8{1, 4, 5, 9})},
//}

ROTATION_TABLE := #partial [TetrominoType][TetrominoOrientation]u16 {
  .T = {
    /*
       UP    DOWN   LEFT   RIGHT
    | .#.. | .... | .#.. | .#.. |
    | ###. | ###. | ##.. | .##. |
    | .... | .#.. | .#.. | .#.. |
    | .... | .... | .... | .... |
    */
    .UP    = 0b0100_1110_0000_0000,
    .DOWN  = 0b0000_1110_0100_0000,
    .LEFT  = 0b0100_1100_0100_0000,
    .RIGHT = 0b0100_0110_0100_0000,
  },
}

draw_tetromino :: proc(t: Tetromino, x, y: i32) {
  for x_tetromino in 0..<4 {
    for y_tetromino in 0..<4 {
      if ROTATION_TABLE[t.type][t.orientation] & (1 << u32(16 - (y_tetromino * 4) + x_tetromino)) != 0 {
        rl.DrawRectangle(x + i32(x_tetromino * 20), y + i32(y_tetromino * 20), 20, 20, rl.WHITE)
      }
    }
  }
}

/*

###.
###.
###.
###.

*/

main :: proc () {

  rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "OTris")
  defer rl.CloseWindow()

  teste_tetromino := Tetromino {
    type = .T,
    orientation = .UP,    
  }

  rl.SetTargetFPS(60)
  for !rl.WindowShouldClose() {
    if rl.IsKeyDown(rl.KeyboardKey.Q) do break
    if rl.IsKeyDown(rl.KeyboardKey.R) do teste_tetromino.orientation = .LEFT

    rl.BeginDrawing()
    rl.ClearBackground(rl.BLACK)
    draw_tetromino(teste_tetromino, 10, 20)


    rl.EndDrawing()
  }

}
