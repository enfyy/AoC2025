package aoc

import "core:fmt"
import "core:strings"
import "core:strconv"
// import "core:slice"

//https://adventofcode.com/2025/day/1
day1 :: proc(input: string) -> (part1: int, part2: int) {
    dial := 50
    lines := input
    for line in strings.split_lines_iterator(&lines) {
        if len(line) < 1 do continue
        rot := strconv.parse_int(line[1:]) or_continue
        dir := strings.starts_with(line, "L") ? -1 : 1
        part2 += rot / 100
        remainder := rot % 100

        for i in 0 ..< remainder {
            dial += dir
            if dial < 0 do dial = 99
            if dial > 99 do dial = 0
            if dial == 0 do part2 += 1
        }

        if dial == 0 do part1 += 1
    }

    return
}
