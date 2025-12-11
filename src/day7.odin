package aoc

import "core:strings"

@(private = "file")
Tile :: enum {
    Empty,
    Start,
    Splitter,
}

@(private = "file")
State :: struct {
    pos:          [2]int,
    visited_mask: u128,
}

//https://adventofcode.com/2025/day/7
day7 :: proc(input: string) -> (part1: i64, part2: i64) {
    grid: [dynamic][]Tile
    lines := input
    y: int
    start_tile_pos: [2]int
    splitter_positions: [dynamic][2]int

    for line in strings.split_lines_iterator(&lines) {
        row: [dynamic]Tile
        for char, x in line {
            tile: Tile
            if char == 'S' {
                tile = .Start
                start_tile_pos = {x, y}
            } else if char == '.' {
                tile = .Empty
            } else if char == '^' {
                tile = .Splitter
                append(&splitter_positions, [2]int{x, y})
            } else {
                panic("unknown tile, malformed input")
            }
            append(&row, tile)
        }
        append(&grid, row[:])
        y += 1
    }
    bounds := [2]int{len(grid[0]), len(grid)}

    // part1:
    {
        unfinished_paths: [dynamic][2]int
        append(&unfinished_paths, start_tile_pos)
        encountered_splitters: map[[2]int]struct{}

        for len(unfinished_paths) > 0 {
            pos := pop_front(&unfinished_paths)
            next_pos := pos + {0, 1}
            if oob(bounds, next_pos) do continue

            next_tile := grid[next_pos.y][next_pos.x]
            if next_tile == .Empty {
                append(&unfinished_paths, next_pos)
            } else if next_tile == .Splitter {
                _, already_encountered := encountered_splitters[next_pos]
                if already_encountered do continue
                encountered_splitters[next_pos] = {}

                left := next_pos + {-1, 0}
                right := next_pos + {1, 0}
                if is_in_bounds(bounds, left) && grid[left.y][left.x] == .Empty {
                    append(&unfinished_paths, left)
                }
                if is_in_bounds(bounds, right) && grid[right.y][right.x] == .Empty {
                    append(&unfinished_paths, right)
                }
            }
        }
        part1 = i64(len(encountered_splitters))
    }

    // part2:
    splitter_index: map[[2]int]int
    for pos, i in splitter_positions do splitter_index[pos] = i
    memo: map[State]int
    part2 = i64(count_timelines(grid, bounds, start_tile_pos, 0, splitter_index, &memo))

    return
}

count_timelines :: proc(
    grid: [dynamic][]Tile,
    bounds: [2]int,
    pos: [2]int,
    visited_mask: u128,
    splitter_index: map[[2]int]int,
    memo: ^map[State]int,
) -> int {
    current := pos
    current_mask := visited_mask

    for {
        next := current + {0, 1}
        if next.y >= bounds.y do return 1
        if next.x < 0 || next.x >= bounds.x do return 1

        tile := grid[next.y][next.x]

        if tile == .Empty {
            current = next
            continue
        }

        if tile != .Splitter do break
        state := State {
            pos          = next,
            visited_mask = current_mask,
        }
        if cached, ok := memo[state]; ok {
            return cached
        }

        idx, ok := splitter_index[next]
        if !ok do panic("Splitter not in index")

        if (current_mask & (1 << u128(idx))) != 0 do return 1
        new_mask := current_mask | (1 << u128(idx))

        left_pos := next + {-1, 0}
        right_pos := next + {1, 0}

        total := 0

        if left_pos.x >= 0 && left_pos.x < bounds.x && grid[left_pos.y][left_pos.x] == .Empty {
            total += count_timelines(grid, bounds, left_pos, new_mask, splitter_index, memo)
        }

        if right_pos.x >= 0 && right_pos.x < bounds.x && grid[right_pos.y][right_pos.x] == .Empty {
            total += count_timelines(grid, bounds, right_pos, new_mask, splitter_index, memo)
        }

        if total == 0 do total = 1
        memo[state] = total
        return total

    }

    return 1
}
