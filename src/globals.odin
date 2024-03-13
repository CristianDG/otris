package otris

import rl "vendor:raylib"

MAX_TRIES :: 1
BOARD_COLUMNS :: 10
BOARD_LINES :: 20

BOARD_LINE_COLOR :: rl.GRAY
BOARD_PERIMETER_COLOR :: rl.WHITE

STARTING_TETROMINO_POSITION : TetrominoPos : {3, 0}

GAME_STATE : struct {
  score: u64,
  board: Board,
  next_tetrominos: NextTetrominos,
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
