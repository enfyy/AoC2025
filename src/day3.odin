package aoc

import "core:strings"
import "core:unicode/utf8"
import "core:strconv"

//https://adventofcode.com/2025/day/3
day3 :: proc(input: string) -> (part1: i64, part2: i64) {
    lines := input
    for line in strings.split_iterator(&lines, NEWLINE) {
        part1 += calculate_joltage(line, 2)
        part2 += calculate_joltage(line, 12)
    }
    return
}

@(private = "file")
calculate_joltage :: proc(bank: string, $digit_count: int) -> (result: i64) {
    assert(len(bank) >= digit_count, "not enough digits in the bank")
    digits: [digit_count]int
    offset := 0
    for i in 0 ..< digit_count {
        digit := -1
        digit_index := 0
        reserved := len(bank) - (digit_count - i - 1)
        for ch, ch_index in bank[offset:reserved] {
            num := strconv.parse_int(utf8.runes_to_string({ch})) or_continue
            if num > digit {
                digit = num
                digit_index = ch_index
            }
        }

        digits[i] = digit
        offset += digit_index + 1
    }
    for digit, i in digits do result = result * 10 + i64(digit)
    return i64(result)
}
