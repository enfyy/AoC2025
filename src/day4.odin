package aoc

import "core:strings"

//https://adventofcode.com/2025/day/4
day4 :: proc(input: string) -> (part1: i64, part2: i64) {
    rows: [dynamic][]bool
    lines := input
    for line in strings.split_lines_iterator(&lines) {
        row := make([]bool, len(line))
        for ch, x in line {
            row[x] = ch == '@'
        }
        append(&rows, row[:])
    }

    grid := rows[:]
    can_be_removed := make([dynamic][2]int)
    for row, y in rows {
        for tile, x in row {
            if !tile do continue
            neighbour_count := check_neighbour_count(grid, x, y)
            if neighbour_count < 4 {
                append(&can_be_removed, [2]int{x, y})
                part1 += 1
            }
        }
    }

    for len(can_be_removed) > 0 {
        for pos in can_be_removed {
            grid[pos.y][pos.x] = false
            part2 += 1
        }
        clear(&can_be_removed)

        for row, y in grid {
            for tile, x in row {
                if !tile do continue
                neighbour_count := check_neighbour_count(grid, x, y)
                if neighbour_count < 4 {
                    append(&can_be_removed, [2]int{x, y})
                }
            }
        }
    }

    return
}

@(private = "file")
directions := [][2]int{{1, 0}, {1, 1}, {0, 1}, {-1, 1}, {-1, 0}, {-1, -1}, {0, -1}, {1, -1}}

@(private = "file")
check_neighbour_count :: proc(grid: [][]bool, x, y: int) -> (count: int) {
    bounds := [2]int{len(grid[0]), len(grid)}
    if oob(bounds, {x, y}) do return 0

    for dir in directions {
        pos := [2]int{x + dir.x, y + dir.y}
        if oob(bounds, pos) do continue
        if grid[pos.y][pos.x] do count += 1
    }

    return
}
