package aoc

import "core:container/intrusive/list"
import "core:slice"
import "core:strings"
import "core:strconv"
import "core:fmt"

//https://adventofcode.com/2025/day/12
day12 :: proc(input: string) -> (part1: i64, part2: i64) {
    regions: [dynamic]Region
    shapes := make(map[int]Shape)
    id := 0
    lines := input
    for section in strings.split_iterator(&lines, DOUBLE_NEWLINE) {
        split := strings.split(section, fmt.tprintf(":%s", NEWLINE))
        if len(split) == 2 {
            index := strconv.parse_int(split[0]) or_continue
            shape: [dynamic][]bool
            area: int
            for row in strings.split_lines_iterator(&split[1]) {
                shape_line: [dynamic]bool
                for ch in row {
                    v := ch == '#'
                    if v do area += 1
                    append(&shape_line, v)
                }
                append(&shape, shape_line[:])
            }
            shapes[index] = Shape {
                id           = id,
                parts        = shape[:],
                area         = area,
                orientations = slice.unique_proc(make_all_orientations(shape[:]), shape_equal),
            }
            id += 1
        } else {
            section := section
            for region_string in strings.split_iterator(&section, NEWLINE) {
                split_again := strings.split(region_string, ": ")
                dimension_split := strings.split(split_again[0], "x")
                x := strconv.parse_int(dimension_split[0]) or_continue
                y := strconv.parse_int(dimension_split[1]) or_continue
                quantities: [dynamic]int
                for index in strings.split_iterator(&split_again[1], " ") {
                    i := strconv.parse_int(index) or_continue
                    append(&quantities, i)
                }
                append(&regions, Region{x = x, y = y, shape_quantities = quantities[:]})
            }
        }
    }

    pieces: [dynamic]Shape
    for region in regions {
        clear(&pieces)
        total_required_space := 0
        for q, i in region.shape_quantities {
            shape := shapes[i]
            for _ in 0 ..< q {
                append(&pieces, shape)
                total_required_space += shape.area
            }
        }
        region_size := (region.x * region.y)
        if region_size < total_required_space do continue
        if region.y < 3 || region.x < 3 do continue // pieces all happen to be that size at least

        // do they fit when we place them really genereously (each piece gets a 3x3)?
        generous_size := (len(pieces) * 9)
        if region_size >= generous_size {
            part1 += 1
            continue
        } else {
            fmt.println("lmao..", generous_size, region_size)
        }
    }
    return
}

@(private = "file")
Region :: struct {
    x, y:             int,
    shape_quantities: []int,
}

@(private = "file")
Shape :: struct {
    id:           int,
    parts:        [][]bool,
    area:         int,
    orientations: [][][]bool,
}

@(private = "file")
rotate90cw :: proc(grid: [][]$T, allocator := context.allocator) -> [][]T {
    if len(grid) == 0 || len(grid[0]) == 0 do return {}
    row_count := len(grid)
    col_count := len(grid[0])
    result := make([][]T, col_count, allocator = allocator)
    for i in 0 ..< col_count do result[i] = make([]T, row_count, allocator = allocator)

    for i in 0 ..< row_count {
        for j in 0 ..< col_count {
            result[j][row_count - 1 - i] = grid[i][j]
        }
    }
    return result
}

@(private = "file")
flip_horizontal :: proc(grid: [][]$T, allocator := context.allocator) -> [][]T {
    result := make([][]T, len(grid), allocator = allocator)
    for i in 0 ..< len(grid) {
        result[i] = make([]T, len(grid[i]), allocator = allocator)
        for j in 0 ..< len(grid[i]) {
            result[i][j] = grid[i][len(grid[i]) - 1 - j]
        }
    }
    return result
}

@(private = "file")
make_all_orientations :: proc(grid: [][]$T, allocator := context.allocator) -> [][][]T {
    result: [dynamic][][]T
    append(&result, grid)
    for i in 0 ..< 4 do append(&result, rotate90cw(result[len(result) - 1]))
    append(&result, flip_horizontal(result[len(result) - 1]))
    for i in 0 ..< 4 do append(&result, rotate90cw(result[len(result) - 1]))
    return result[:]
}

@(private = "file")
shape_equal :: proc(a, b: [][]bool) -> bool {
    if len(a) != len(b) do return false
    if len(a) == 0 do return true
    if len(a[0]) != len(b[0]) do return false
    for row, y in a do for value, x in row do if b[y][x] != value do return false
    return true
}
