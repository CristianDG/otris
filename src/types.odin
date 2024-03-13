package otris

import "core:container/queue"
import rl "vendor:raylib"

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

NextTetrominos :: queue.Queue(Tetromino)

add_to_next_tetrominos :: proc(next: ^NextTetrominos, t: Tetromino){
  queue.push_back(&GAME_STATE.next_tetrominos, t)
}

get_next_tetromino :: proc(next: ^NextTetrominos) -> Tetromino {
  return queue.pop_front(next)
}


