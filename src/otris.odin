package otris

import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:math/rand"
import rl "vendor:raylib"

WINDOW_HEIGHT : i32 : 540
WINDOW_WIDTH : i32 : 960
BOARD_POSITION : [2]i32 : { 250, 50 }
BLOCK_SIZE : i32 : 20
MAX_TRIES :: 1
BOARD_COLUMNS :: 10
BOARD_LINES :: 20

BOARD_LINE_COLOR :: rl.GRAY
BOARD_PERIMETER_COLOR :: rl.WHITE

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
  color: rl.Color,
}

Board :: struct {
  // TODO: mudar rl.Color para uma struct Piece ou algo assim
  pieces: [BOARD_COLUMNS][BOARD_LINES]rl.Color
}

TetrominoPos :: [2]i32

STARTING_TETROMINO_POSITION : TetrominoPos : {3, 0}

GAME_STATE : struct {
  score: u64,
  board: Board,
  next_tetrominos: [5]Tetromino,
  change_tetromino: Maybe(Tetromino),
  current_tetromino: Tetromino,
  tetromino_position: TetrominoPos,
  current_tries: i8,
  recently_changed: bool,
  simulation_delay : f32, // em segundos
  simulation_cooldown : f32,
} = {
  score = 0,
  tetromino_position = STARTING_TETROMINO_POSITION,
  current_tries = MAX_TRIES,
  board = Board{},
  simulation_delay = .5 ,
  simulation_cooldown = 0,
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

u16_get :: proc (value: u16, x, y: int) -> bool{
  return value & (1 << u32(((3 - y) * 4) + (3 - x))) != 0
}

tetromino_on_board_draw :: proc(t: ^Tetromino, relative_position: [2]i32) {
  pos := BOARD_POSITION + (relative_position * BLOCK_SIZE)
  tetromino_draw(t, pos.x, pos.y)
}

tetromino_draw :: proc(t: ^Tetromino, x, y: i32) {
  for x_tetromino in 0..<4 {
    for y_tetromino in 0..<4 {
      if u16_get(ROTATION_TABLE[t.type][t.orientation], x_tetromino, y_tetromino) {
        rl.DrawRectangle(
          x + (i32(x_tetromino) * BLOCK_SIZE),
          y + (i32(y_tetromino) * BLOCK_SIZE),
          BLOCK_SIZE, BLOCK_SIZE, t.color)
      }
    }
  }
}

board_frame_draw :: proc(x, y: i32) {

  // TODO: mudar para `start_pos` e `end_pos`
  rl.DrawText("Board", x, y - 25, 20, BOARD_PERIMETER_COLOR)

  for i in 1..<BOARD_COLUMNS {
    rl.DrawLine(x + (i32(i) * BLOCK_SIZE), y, x + (i32(i) * BLOCK_SIZE), y + (BOARD_LINES * BLOCK_SIZE), BOARD_LINE_COLOR)
  }

  for i in 1..<BOARD_LINES {
    rl.DrawLine(x, y + (i32(i) * BLOCK_SIZE), x + (BOARD_COLUMNS * BLOCK_SIZE), y + (i32(i) * BLOCK_SIZE), BOARD_LINE_COLOR)
  }

  // linha da esquerda
  rl.DrawLine(x, y, x, y + (BOARD_LINES * BLOCK_SIZE), rl.WHITE)

  // linha da direita
  rl.DrawLine(x + (BOARD_COLUMNS * BLOCK_SIZE), y, x + (BOARD_COLUMNS * BLOCK_SIZE), y + (BOARD_LINES * BLOCK_SIZE), BOARD_PERIMETER_COLOR)
  
  // linha do fundo
  rl.DrawLine(x, y + (BOARD_LINES * BLOCK_SIZE), x + (BOARD_COLUMNS * BLOCK_SIZE), y + (BOARD_LINES * BLOCK_SIZE), BOARD_PERIMETER_COLOR)

  // linha de cima
  rl.DrawLine(x, y, x + (BOARD_COLUMNS * BLOCK_SIZE), y, BOARD_PERIMETER_COLOR)

}

board_draw :: proc(board: ^Board) {

  for line, x in board.pieces {
    for piece, y in line {
      rl.DrawRectangle(
        BOARD_POSITION.x + (i32(x) * BLOCK_SIZE),
        BOARD_POSITION.y + (i32(y) * BLOCK_SIZE),
        BLOCK_SIZE, BLOCK_SIZE, piece)
    }
  }
  board_frame_draw(BOARD_POSITION.x, BOARD_POSITION.y)

}

rotate_orientation :: proc(rotation: TetrominoOrientation) -> TetrominoOrientation {
  return TetrominoOrientation((u8(rotation) + 1) % len(TetrominoOrientation))
}

can_place :: proc(board: ^Board, t: ^Tetromino, pos: [2]i32 ) -> bool {
  for x := 0; x < 4; x+=1 {
    for y := 0; y < 4; y+=1{
      tetromino_piece_present : bool = u16_get(ROTATION_TABLE[t.type][t.orientation], x, y)
      hit_bottom := (i32(y) + pos.y) >= BOARD_LINES
      hit_left   := (i32(x) + pos.x) < 0
      hit_right  := (i32(x) + pos.x) >= BOARD_COLUMNS

      if tetromino_piece_present && (hit_left || hit_right || hit_bottom || (board.pieces[int(x)+int(pos.x)][int(y)+int(pos.y)] != (rl.Color{}))) {
        return false
      }
    }
  }

  return true;
}

step :: proc (board: ^Board, t: ^Tetromino, pos: ^[2]i32) {
  if !can_place(board, t, pos^ + {0 , 1}) {
    GAME_STATE.current_tries -= 1
    if GAME_STATE.current_tries < 0 {
      place_and_get(board, t, pos^)
    }
  } else {
    pos^ += { 0, 1 }
  }

}

place_and_get :: proc (board: ^Board, t: ^Tetromino, pos: [2]i32){
  place(board, t, pos)
  t^ = tetromino_next()

  // TODO: olhar a posição correta
  GAME_STATE.tetromino_position = {3, 0}
  GAME_STATE.current_tries = MAX_TRIES
}

tetromino_random :: proc () -> Tetromino {
  rng := rand.uint32() % len(TetrominoType)
  new_type := TetrominoType(rng)
  color := rl.Color{ u8(rand.uint32() % 226) + 30, u8(rand.uint32() % 226) + 30, u8(rand.uint32() % 226) + 30, 255 }

  return Tetromino { orientation = .LEFT, type = new_type, color = color }
}

tetromino_next :: proc () -> Tetromino {
  
  next := GAME_STATE.next_tetrominos[0]
  for i := 0; i < len(GAME_STATE.next_tetrominos) - 2; i+=1{
    GAME_STATE.next_tetrominos[i] = GAME_STATE.next_tetrominos[i+1]
  }

  GAME_STATE.next_tetrominos[len(GAME_STATE.next_tetrominos)-1] = tetromino_random()

  return next
}

remove_full_lines :: proc(board: ^Board) {
  points : u64 = 0
  for y := 0; y < BOARD_LINES; {
    full := true
    for x := 0; x < BOARD_COLUMNS; x += 1{
      full &&= board.pieces[x][y] != 0
    }
    if full {
      points += 1

      // NOTE: esse definitivamente não é o melhor método, mas fazer o q
      for x in 0..<BOARD_COLUMNS {
        board.pieces[x][y] = 0
      }
      for i in 0..<y {
        for x in 0..<BOARD_COLUMNS{
          if board.pieces[x][i] != 0 {
            board.pieces[x][i+1] = board.pieces[x][i]
            board.pieces[x][i] = 0
          }
        }
      }
      continue
    }

    y += 1
  }
  GAME_STATE.score += points
}

place :: proc (board: ^Board, t: ^Tetromino, pos: [2]i32){
  for x := 0; x < 4; x+=1 {
    for y := 0; y < 4; y+=1{
      piece_present : bool = u16_get(ROTATION_TABLE[t.type][t.orientation], x, y)

      if piece_present {
        board.pieces[int(x)+int(pos.x)][int(y)+int(pos.y)] = t.color
      }
    }
  }
  remove_full_lines(board)

  GAME_STATE.recently_changed = false
}

change_tetromino_draw :: proc (t: ^Maybe(Tetromino)) {
  change_tetromino, ok := t.?
  starting_pos := [2]i32{70, 50}
  ending_pos := starting_pos + {6 * BLOCK_SIZE, 4 * BLOCK_SIZE}

  if ok {
    tetromino_draw(&Tetromino{ type = change_tetromino.type, color = change_tetromino.color }, starting_pos.x + BLOCK_SIZE, starting_pos.y + BLOCK_SIZE)
  }

  rl.DrawText("Change", starting_pos.x, starting_pos.y - 25, 20, BOARD_PERIMETER_COLOR)

  for i in 1..<6 {
    rl.DrawLine(
      starting_pos.x + (i32(i) * BLOCK_SIZE),
      starting_pos.y,
      starting_pos.x + (i32(i) * BLOCK_SIZE),
      ending_pos.y,
      BOARD_LINE_COLOR)
  }
  for i in 1..<4 {
    rl.DrawLine(
      starting_pos.x,
      starting_pos.y + (i32(i) * BLOCK_SIZE),
      ending_pos.x,
      starting_pos.y + (i32(i) * BLOCK_SIZE),
      BOARD_LINE_COLOR)
  }

  rl.DrawLine(starting_pos.x, starting_pos.y, ending_pos.x, starting_pos.y, BOARD_PERIMETER_COLOR)
  rl.DrawLine(starting_pos.x, starting_pos.y, starting_pos.x, ending_pos.y, BOARD_PERIMETER_COLOR)
  rl.DrawLine(ending_pos.x, ending_pos.y, ending_pos.x, starting_pos.y, BOARD_PERIMETER_COLOR)
  rl.DrawLine(starting_pos.x, ending_pos.y, ending_pos.x, ending_pos.y, BOARD_PERIMETER_COLOR)

}

score_draw :: proc(score: u64) {

  builder := strings.builder_make()
  strings.write_string(&builder, "Score: ")
  strings.write_u64(&builder, score)
  str := strings.to_string(builder)
  rl.DrawText(strings.clone_to_cstring(str), 70, 150, 20, BOARD_PERIMETER_COLOR)

}

handle_input :: proc () {
  if rl.IsKeyPressed(rl.KeyboardKey.SPACE) {
    for can_place(&GAME_STATE.board, &GAME_STATE.current_tetromino, GAME_STATE.tetromino_position + { 0, 1 }) {
      GAME_STATE.tetromino_position += { 0, 1 }
    }
    place_and_get(&GAME_STATE.board, &GAME_STATE.current_tetromino, GAME_STATE.tetromino_position)
  }

  if rl.IsKeyPressed(rl.KeyboardKey.R) {
    temp := GAME_STATE.current_tetromino
    temp.orientation = rotate_orientation(GAME_STATE.current_tetromino.orientation)

    if can_place(&GAME_STATE.board, &temp, GAME_STATE.tetromino_position){
      GAME_STATE.current_tetromino.orientation = rotate_orientation(GAME_STATE.current_tetromino.orientation)
    }
  }

  if rl.IsKeyPressed(rl.KeyboardKey.C) {
    if !GAME_STATE.recently_changed {
      change_tetromino, ok := GAME_STATE.change_tetromino.?
      temp :=  GAME_STATE.current_tetromino
      temp.orientation = .LEFT

      GAME_STATE.recently_changed = true
      GAME_STATE.change_tetromino = temp
      GAME_STATE.tetromino_position = STARTING_TETROMINO_POSITION

      GAME_STATE.current_tetromino = tetromino_next() if !ok else change_tetromino
    }
  }
  if rl.IsKeyPressed(rl.KeyboardKey.RIGHT) {
    if can_place(&GAME_STATE.board, &GAME_STATE.current_tetromino, GAME_STATE.tetromino_position + { 1, 0 }){
      GAME_STATE.tetromino_position += { 1, 0 }
    }
  }
  if rl.IsKeyPressed(rl.KeyboardKey.LEFT) {
    if can_place(&GAME_STATE.board, &GAME_STATE.current_tetromino, GAME_STATE.tetromino_position - { 1, 0 }){
      GAME_STATE.tetromino_position -= { 1, 0 }
    }
  }
  if rl.IsKeyPressed(rl.KeyboardKey.DOWN){
    if can_place(&GAME_STATE.board, &GAME_STATE.current_tetromino, GAME_STATE.tetromino_position + { 0, 1 }){
      GAME_STATE.simulation_cooldown = 0
      GAME_STATE.tetromino_position += { 0, 1 }
    }
  }
}

main :: proc () {

  rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "OTris")
  defer rl.CloseWindow()

  for i in 0..<len(GAME_STATE.next_tetrominos) {
    GAME_STATE.next_tetrominos[i] = tetromino_random()
  }
  GAME_STATE.current_tetromino = tetromino_next()

  rl.SetTargetFPS(60)
  for !rl.WindowShouldClose() {
    if rl.IsKeyPressed(rl.KeyboardKey.Q) do break
    handle_input()

    GAME_STATE.simulation_cooldown += rl.GetFrameTime()
    if GAME_STATE.simulation_cooldown > GAME_STATE.simulation_delay {
      GAME_STATE.simulation_cooldown = 0
      step(&GAME_STATE.board, &GAME_STATE.current_tetromino, &GAME_STATE.tetromino_position)
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

    score_draw(GAME_STATE.score)
    tetromino_on_board_draw(&GAME_STATE.current_tetromino, GAME_STATE.tetromino_position)
    board_draw(&GAME_STATE.board)
    change_tetromino_draw(&GAME_STATE.change_tetromino)

    rl.EndDrawing()
  }

}
