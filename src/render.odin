package otris

import "core:strings"
import "core:strconv"
import "core:fmt"
import "core:container/queue"
import rl "vendor:raylib"

RENDER_WIDTH  : i32 : 640
RENDER_HEIGHT : i32 : 360

WINDOW_WIDTH  : i32 : 1280
WINDOW_HEIGHT : i32 : 720

BLOCK_SIZE : i32 : 15
FONT_SIZE : i32 : 20
BOARD_POSITION : [2]i32 : { 250, 50 }

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
  rl.DrawText("Board", x, y - 25, FONT_SIZE, BOARD_PERIMETER_COLOR)

  width := BOARD_COLUMNS * BLOCK_SIZE
  height := BOARD_LINES * BLOCK_SIZE

  for i in 1..<BOARD_COLUMNS {
    rl.DrawLine(x + (i32(i) * BLOCK_SIZE), y, x + (i32(i) * BLOCK_SIZE), y + height, BOARD_LINE_COLOR)
  }

  for i in 1..<BOARD_LINES {
    rl.DrawLine(x, y + (i32(i) * BLOCK_SIZE), x + width, y + (i32(i) * BLOCK_SIZE), BOARD_LINE_COLOR)
  }

  rl.DrawRectangleLines(
    x, y,
    width, height,
    BOARD_PERIMETER_COLOR)

}

board_draw :: proc(board: ^Board) {

  for line, x in board.pieces {
    for color, y in line {
      rl.DrawRectangle(
        BOARD_POSITION.x + (i32(x) * BLOCK_SIZE),
        BOARD_POSITION.y + (i32(y) * BLOCK_SIZE),
        BLOCK_SIZE, BLOCK_SIZE, color)
    }
  }

  board_frame_draw(BOARD_POSITION.x, BOARD_POSITION.y)

}

score_draw :: proc(score: u64) {

  builder := strings.builder_make()
  strings.write_string(&builder, "Score: ")
  strings.write_u64(&builder, score)
  str := strings.to_string(builder)

  rl.DrawText(
    strings.clone_to_cstring(str),
    BOARD_POSITION.x - 190,
    BOARD_POSITION.y + 100,
    FONT_SIZE,
    BOARD_PERIMETER_COLOR)

}

next_tetrominos_draw :: proc(next_tetrominos: ^NextTetrominos) {

  next_tetrominos_pos := BOARD_POSITION + [2]i32{(BOARD_COLUMNS * BLOCK_SIZE) + 50, 0}
  next_tetrominos_to_display_nr :: 5

  width  := 6 * BLOCK_SIZE
  height := 4 * BLOCK_SIZE * next_tetrominos_to_display_nr


  for i in 0..<5 {
    tetromino_draw(
      // NOTE: ?
      queue.get_ptr(next_tetrominos, i),
      next_tetrominos_pos.x + BLOCK_SIZE,
      next_tetrominos_pos.y + (i32(i) * 4 * BLOCK_SIZE) + BLOCK_SIZE)
  }

  rl.DrawRectangleLines(
    next_tetrominos_pos.x,
    next_tetrominos_pos.y,
    6 * BLOCK_SIZE,
    4 * BLOCK_SIZE * next_tetrominos_to_display_nr,
    BOARD_PERIMETER_COLOR)

  for i in 1..<6 {
    rl.DrawLine(
      next_tetrominos_pos.x + (i32(i) * BLOCK_SIZE),
      next_tetrominos_pos.y,
      next_tetrominos_pos.x + (i32(i) * BLOCK_SIZE),
      next_tetrominos_pos.y + height,
      BOARD_LINE_COLOR)
  }

  for i in 1..<(4 * next_tetrominos_to_display_nr) {
    rl.DrawLine(
      next_tetrominos_pos.x,
      next_tetrominos_pos.y + (i32(i) * BLOCK_SIZE),
      next_tetrominos_pos.x + width,
      next_tetrominos_pos.y + (i32(i) * BLOCK_SIZE),
      BOARD_LINE_COLOR)
  }

  rl.DrawText("Next", next_tetrominos_pos.x, next_tetrominos_pos.y - 25, FONT_SIZE, BOARD_PERIMETER_COLOR)
}

debug_tetromino_info_draw :: proc(t: Tetromino){
  type_str, type_ok := fmt.enum_value_to_string(t.type)
  orientation_str, orientation_ok := fmt.enum_value_to_string(t.orientation)
  if type_ok && orientation_ok {
    rl.DrawText(strings.clone_to_cstring(type_str), 0, 0, FONT_SIZE / 2, rl.RAYWHITE)
    rl.DrawText(strings.clone_to_cstring(orientation_str), 20, 0, FONT_SIZE / 20, rl.RAYWHITE)
  }
}

