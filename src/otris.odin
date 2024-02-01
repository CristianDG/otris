package otris

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

WINDOW_HEIGHT : i32 : 540
WINDOW_WIDTH : i32 : 960
BOARD_POSITION : [2]i32 : { 250, 50 }
BLOCK_SIZE : i32 : 20
VERTICAL_COLUMNS :: 10
HORIZONTAL_COLUMNS :: 20
SIMULATION_DELAY : f32 : 1 // em segundos

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

Board :: struct {
  pieces: [HORIZONTAL_COLUMNS][VERTICAL_COLUMNS]rl.Color
}

GAME_STATE : struct {
  score: u64,
  board: Board,
  next_tetrominos: [5]TetrominoType,
  change_tetromino: Maybe(TetrominoType),
  current_tetromino: Tetromino,
  tetromino_position: [2]i32,
} = {
  score = 0,
  board = Board{},
}

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

tetromino_on_board_draw :: proc(t: ^Tetromino, relative_position: [2]i32) {
  pos := BOARD_POSITION + (relative_position * BLOCK_SIZE)
  tetromino_draw(t, pos.x, pos.y)
}

tetromino_draw :: proc(t: ^Tetromino, x, y: i32) {
  for x_tetromino in 0..<4 {
    for y_tetromino in 0..<4 {
      if ROTATION_TABLE[t.type][t.orientation] & (1 << u32(((3 - y_tetromino) * 4) + (3 - x_tetromino))) != 0 {
        rl.DrawRectangle(x + (i32(x_tetromino) * BLOCK_SIZE), y + (i32(y_tetromino) * BLOCK_SIZE), BLOCK_SIZE, BLOCK_SIZE, rl.WHITE)
      }
    }
  }
}

board_frame_draw :: proc(x, y: i32) {

  for i in 0..=VERTICAL_COLUMNS {
    rl.DrawLine(x + (i32(i) * BLOCK_SIZE), y, x + (i32(i) * BLOCK_SIZE), y + (HORIZONTAL_COLUMNS * BLOCK_SIZE), rl.GRAY)
  }

  for i in 0..=HORIZONTAL_COLUMNS {
    rl.DrawLine(x, y + (i32(i) * BLOCK_SIZE), x + (VERTICAL_COLUMNS * BLOCK_SIZE), y + (i32(i) * BLOCK_SIZE), rl.GRAY)
  }

  // linha da esquerda
  rl.DrawLine(x, y, x, y + (HORIZONTAL_COLUMNS * BLOCK_SIZE), rl.WHITE)

  // linha da direita
  rl.DrawLine(x + (VERTICAL_COLUMNS * BLOCK_SIZE), y, x + (VERTICAL_COLUMNS * BLOCK_SIZE), y + (HORIZONTAL_COLUMNS * BLOCK_SIZE), rl.WHITE)
  
  // linha do fundo
  rl.DrawLine(x, y + (HORIZONTAL_COLUMNS * BLOCK_SIZE), x + (VERTICAL_COLUMNS * BLOCK_SIZE), y + (HORIZONTAL_COLUMNS * BLOCK_SIZE), rl.WHITE)

}

board_draw :: proc(board: ^Board) {
  board_frame_draw(BOARD_POSITION.x, BOARD_POSITION.y)
}

rotate_orientation :: proc(rotation: TetrominoOrientation) -> TetrominoOrientation {
  return TetrominoOrientation((u8(rotation) + 1) % len(TetrominoOrientation))
}

can_place :: proc(board: ^Board, t: Tetromino) -> bool {

  return false;
}

step :: proc () {

}

main :: proc () {

  rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "OTris")
  defer rl.CloseWindow()

  GAME_STATE.current_tetromino = Tetromino {
    type = .Z,
    orientation = .LEFT,
  }

  simulation_delay_cooldown : f32 = 0

  rl.SetTargetFPS(60)
  for !rl.WindowShouldClose() {
    if rl.IsKeyPressed(rl.KeyboardKey.Q) do break
    if rl.IsKeyPressed(rl.KeyboardKey.C) {
      GAME_STATE.current_tetromino.type = TetrominoType((u8(GAME_STATE.current_tetromino.type) + 1) % len(TetrominoType))
    }
    if rl.IsKeyPressed(rl.KeyboardKey.R) do GAME_STATE.current_tetromino.orientation = rotate_orientation(GAME_STATE.current_tetromino.orientation)

    simulation_delay_cooldown += rl.GetFrameTime()
    if simulation_delay_cooldown > SIMULATION_DELAY {
      simulation_delay_cooldown = 0
      step()
    }

    // NOTE: simular

    rl.BeginDrawing()
    rl.ClearBackground(rl.BLACK)

    // TODO: remover
    type_str, type_ok := fmt.enum_value_to_string(GAME_STATE.current_tetromino.type)
    orientation_str, orientation_ok := fmt.enum_value_to_string(GAME_STATE.current_tetromino.orientation)
    if type_ok && orientation_ok {
      rl.DrawText(strings.clone_to_cstring(type_str), 0, 0, 10, rl.RAYWHITE)
      rl.DrawText(strings.clone_to_cstring(orientation_str), 20, 0, 10, rl.RAYWHITE)
    }
    // remover

    board_draw(&GAME_STATE.board)
    tetromino_on_board_draw(&GAME_STATE.current_tetromino, GAME_STATE.tetromino_position + 1)

    rl.EndDrawing()
  }

}
