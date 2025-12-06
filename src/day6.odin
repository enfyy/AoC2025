package aoc

import "core:strings"
import "core:strconv"

//https://adventofcode.com/2025/day/6
day6 :: proc(input: string) -> (part1: i64, part2: i64) {
    //part1:
    grid: [dynamic][]i64
    operators: [dynamic]string

    lines := strings.split(input, NEWLINE)
    for line in lines {
        if strings.starts_with(line, "+") || strings.starts_with(line, "*") {
            ops := strings.split(line, " ")
            for op in ops {
                trimmed := strings.trim_space(op)
                if len(trimmed) == 0 do continue
                append(&operators, op)
            }
        } else {
            numbers := strings.split(line, " ")
            nums: [dynamic]i64
            for num_s in numbers {
                trimmed := strings.trim_space(num_s)
                if len(trimmed) == 0 do continue
                num := strconv.parse_i64(trimmed) or_continue
                append(&nums, num)
            }
            append(&grid, nums[:])
        }
    }

    for op, i in operators {
        if op == "*" {
            result: i64 = 1
            for row in grid do result *= row[i]
            part1 += result
        } else if op == "+" {
            result: i64 = 0
            for row in grid do result += row[i]
            part1 += result
        }
    }

    // part2:
    length := len(lines[0])
    s_builder := strings.builder_make()
    operator_index := len(operators) - 1
    temp_result: i64 = operators[operator_index] == "*" ? 1 : 0

    for x := length - 1; x >= 0; x -= 1 {
        for row, y in lines[:len(lines) - 1] {
            ch := rune(row[x])
            if ch == ' ' do continue
            strings.write_rune(&s_builder, ch)
        }
        s := strings.trim_space(strings.to_string(s_builder))
        if len(s) == 0 {
            operator_index -= 1
            part2 += temp_result
            temp_result = operators[operator_index] == "*" ? 1 : 0
            continue
        }
        num, ok := strconv.parse_i64(s)
        strings.builder_reset(&s_builder)
        if !ok do continue
        op := operators[operator_index]
        if op == "*" {
            temp_result *= num
        } else if op == "+" {
            temp_result += num
        }
    }
    part2 += temp_result

    return
}
