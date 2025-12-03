package aoc

import "core:strings"
import "core:unicode/utf8"
import "core:strconv"
import "core:math"
import "core:fmt"

day3 :: proc(input: string) -> (part1: i64, part2: i64) {
    lines := input
    for line in strings.split_iterator(&lines, NEWLINE) {
        part1 += calculate_joltage(line, 2)
        part2 += calculate_joltage(line, 12)
    }
    return
}

calculate_joltage :: proc(bank: string, $digit_count: int) -> i64 {
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
    result := 0
    for digit, i in digits {
        result = result * 10 + digit
    }
    return i64(result)
}
