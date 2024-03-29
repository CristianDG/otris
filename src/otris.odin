package otris

import "core:fmt"
import "core:math/rand"
import rl "vendor:raylib"


u16_get :: proc (value: u16, x, y: int) -> bool{
  return value & (1 << u32(((3 - y) * 4) + (3 - x))) != 0
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
  
  next := get_next_tetromino(&GAME_STATE.next_tetrominos)
  add_to_next_tetrominos(&GAME_STATE.next_tetrominos, tetromino_random())

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

      // FIXME: bugado demais :+1:
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
  starting_pos := BOARD_POSITION - [2]i32{190, 0}
  ending_pos := starting_pos + {6 * BLOCK_SIZE, 4 * BLOCK_SIZE}

  if ok {
    tetromino_draw(
      &Tetromino{ type = change_tetromino.type,
      color = change_tetromino.color },
      starting_pos.x + BLOCK_SIZE,
      starting_pos.y + BLOCK_SIZE)
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

game_state_init :: proc() {
  for i in 0..<10 {
    add_to_next_tetrominos(&GAME_STATE.next_tetrominos, tetromino_random())
  }
  GAME_STATE.current_tetromino = tetromino_next()
}

main :: proc () {

  //rl.SetConfigFlags(rl.ConfigFlags{.WINDOW_RESIZABLE})
  rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "OTris")
  defer rl.CloseWindow()

  game_state_init()

  rl.SetTargetFPS(60)
  for !rl.WindowShouldClose() {
    if rl.IsKeyPressed(rl.KeyboardKey.Q) do break
    handle_input()

    GAME_STATE.simulation_cooldown += rl.GetFrameTime()
    if GAME_STATE.simulation_cooldown > GAME_STATE.simulation_delay {
      GAME_STATE.simulation_cooldown = 0
      step(&GAME_STATE.board, &GAME_STATE.current_tetromino, &GAME_STATE.tetromino_position)
    }

    rl.BeginDrawing()
    rl.ClearBackground(rl.BLACK)

    score_draw(GAME_STATE.score)
    tetromino_on_board_draw(&GAME_STATE.current_tetromino, GAME_STATE.tetromino_position)
    board_draw(&GAME_STATE.board)
    change_tetromino_draw(&GAME_STATE.change_tetromino)
    next_tetrominos_draw(&GAME_STATE.next_tetrominos)

    rl.EndDrawing()
  }

}
