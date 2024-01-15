package otris

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

WINDOW_HEIGHT : i32 : 540
WINDOW_WIDTH : i32 : 960

// NOTE: pode ser enum u16
TetrominoType :: enum {
  I, J, L, S, O, T, Z,
}

// NOTE: manter a ordem assim obrigado
TetrominoOrientation :: enum {
  LEFT, UP, RIGHT, DOWN
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



ROTATION_TABLE := [TetrominoType][TetrominoOrientation]u16 {
  .T = {
    /*
       UP    DOWN   LEFT   RIGHT
    | .#.. | .#.. | .#.. | .... |
    | .##. | ##.. | ###. | ###. |
    | .#.. | .#.. | .... | .#.. |
    | .... | .... | .... | .... |
    */
    .UP    = 0b0100_0110_0100_0000,
    .DOWN  = 0b0100_1100_0100_0000,
    .LEFT  = 0b0100_1110_0000_0000,
    .RIGHT = 0b0000_1110_0100_0000,
  },
  .J = {
    /*
       UP    DOWN   LEFT   RIGHT
    | .##. | .#.. | #... | .... |
    | .#.. | .#.. | ###. | ###. |
    | .#.. | ##.. | .... | ..#. |
    | .... | .... | .... | .... |
    */
    .UP    = 0b0110_0100_0100_0000,
    .DOWN  = 0b0100_0100_1100_0000,
    .LEFT  = 0b1110_0010_0000_0000,
    .RIGHT = 0b1000_1110_0000_0000,
  },
  .I = {
    /*
       UP    DOWN   LEFT   RIGHT
    | .#.. | ..#. | .... | .... |
    | .#.. | ..#. | #### | .... |
    | .#.. | ..#. | .... | #### |
    | .#.. | ..#. | .... | .... |
    */
    .UP    = 0b0100_0100_0100_0100,
    .DOWN  = 0b0010_0010_0010_0010,
    .LEFT  = 0b0000_1111_0000_0000,
    .RIGHT = 0b0000_0000_1111_0000,
  },

  .L = {
    /*
       UP    DOWN   LEFT   RIGHT
    | ##.. | .#.. | ..#. | .... |
    | .#.. | .#.. | ###. | ###. |
    | .#.. | .##. | .... | #... |
    | .... | .... | .... | .... |
    */
    .UP    = 0b1100_0100_0100_0000,
    .DOWN  = 0b0100_0100_0110_0000,
    .LEFT  = 0b0010_1110_0000_0000,
    .RIGHT = 0b0000_1110_1000_0000,
  },
  .O = {
    /*
       UP    DOWN   LEFT   RIGHT
    | .##. | .##. | .##. | .##. |
    | .##. | .##. | .##. | .##. |
    | .... | .... | .... | .... |
    | .... | .... | .... | .... |
    */
    .UP    = 0b0110_0110_0000_0000,
    .DOWN  = 0b0110_0110_0000_0000,
    .LEFT  = 0b0110_0110_0000_0000,
    .RIGHT = 0b0110_0110_0000_0000,
  },
  .S = {
    /*
       UP    DOWN   LEFT   RIGHT
    | .#.. | #... | .##. | .... |
    | .##. | ##.. | ##.. | .##. |
    | ..#. | .#.. | .... | ##.. |
    | .... | .... | .... | .... |
    */
    .UP    = 0b0100_0110_0010_0000,
    .DOWN  = 0b1000_1100_0100_0000,
    .LEFT  = 0b0110_1100_0000_0000,
    .RIGHT = 0b0000_0110_1100_0000,
  },
  .Z = {
    /*
       UP    DOWN   LEFT   RIGHT
    | ..#. | .#.. | ##.. | .... |
    | .##. | ##.. | .##. | ##.. |
    | .#.. | #... | .... | .##. |
    | .... | .... | .... | .... |
    */
    .UP    = 0b0010_0110_0100_0000,
    .DOWN  = 0b0100_1100_1000_0000,
    .LEFT  = 0b1100_0110_0000_0000,
    .RIGHT = 0b0000_1100_0110_0000,
  },
}

draw_tetromino :: proc(t: Tetromino, x, y: i32) {
  for x_tetromino in 0..<4 {
    for y_tetromino in 0..<4 {
      if ROTATION_TABLE[t.type][t.orientation] & (1 << u32(((3 - y_tetromino) * 4) + (3 - x_tetromino))) != 0 {
        rl.DrawRectangle(x + i32(x_tetromino * 20), y + i32(y_tetromino * 20), 20, 20, rl.WHITE)
      }
    }
  }
}

rotate_orientation :: proc(rotation: TetrominoOrientation) -> TetrominoOrientation {
  return TetrominoOrientation((u8(rotation) + 1) % len(TetrominoOrientation))
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
    type = .Z,
    orientation = .LEFT,    
  }

  rl.SetTargetFPS(60)
  for !rl.WindowShouldClose() {
    if rl.IsKeyPressed(rl.KeyboardKey.Q) do break
    if rl.IsKeyPressed(rl.KeyboardKey.C) {
      teste_tetromino.type = TetrominoType((u8(teste_tetromino.type) + 1) % len(TetrominoType))
    }
    if rl.IsKeyPressed(rl.KeyboardKey.R) do teste_tetromino.orientation = rotate_orientation(teste_tetromino.orientation)

    rl.BeginDrawing()
    rl.ClearBackground(rl.BLACK)

    // TODO: remover
    type_str, type_ok := fmt.enum_value_to_string(teste_tetromino.type)
    orientation_str, orientation_ok := fmt.enum_value_to_string(teste_tetromino.orientation)
    if type_ok && orientation_ok {
      rl.DrawText(strings.clone_to_cstring(type_str), 0, 0, 10, rl.RAYWHITE)
      rl.DrawText(strings.clone_to_cstring(orientation_str), 20, 0, 10, rl.RAYWHITE)
    }
    // remover

    draw_tetromino(teste_tetromino, 10, 20)

    rl.EndDrawing()
  }

}
