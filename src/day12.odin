package aoc

import "core:slice"
import "core:strings"
import "core:strconv"
import "core:fmt"

//https://adventofcode.com/2025/day/12
day12 :: proc(input: string) -> (part1: i64, part2: i64) {
    regions: [dynamic]Region
    shapes: map[int]Shape

    lines := input
    for section in strings.split_iterator(&lines, DOUBLE_NEWLINE) {
        split := strings.split(section, ":\n")
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
                parts = shape[:],
                area  = area,
            }
        } else {
            section := section
            for region_string in strings.split_iterator(&section, NEWLINE) {
                split_again := strings.split(region_string, ": ")
                dimension_split := strings.split(split_again[0], "x")
                x := strconv.parse_int(dimension_split[0]) or_continue
                y := strconv.parse_int(dimension_split[1]) or_continue
                indices: [dynamic]int
                for index in strings.split_iterator(&split_again[1], " ") {
                    i := strconv.parse_int(index) or_continue
                    append(&indices, i)
                }
                append(&regions, Region{x = x, y = y, shape_quantities = indices[:]})
            }
        }
    }

    pieces: [dynamic]Shape
    for region in regions {
        clear(&pieces)
        space := region.x * region.y
        total_space_required := 0
        for q in region.shape_quantities {
            s := shapes[q]
            orientations := make_all_orientations(s.parts)
            orientations = slice.unique_proc(orientations, shape_equal)
            total_space_required += s.area

            fmt.println(orientations)
        }
        if space < total_space_required do continue
        slice.sort_by(pieces[:], proc(i, j: Shape) -> bool {return i.area < j.area})

        part1 += 1
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
    parts: [][]bool,
    area:  int,
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
    for i in 0 ..< 3 do append(&result, rotate90cw(result[len(result) - 1]))
    append(&result, flip_horizontal(result[len(result) - 1]))
    for i in 0 ..< 3 do append(&result, rotate90cw(result[len(result) - 1]))
    return result[:]
}

@(private = "file")
shape_equal :: proc(a, b: [][]bool) -> bool {
    for row, y in a do for value, x in row do if b[y][x] != value do return false
    return true
}
