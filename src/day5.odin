package aoc

import "core:strings"
import "core:strconv"

//https://adventofcode.com/2025/day/5
day5 :: proc(input: string) -> (part1: i64, part2: i64) {
    sections := strings.split(input, DOUBLE_NEWLINE)
    assert(len(sections) == 2, "malformed input")
    ranges: [dynamic][2]i64
    for line in strings.split_lines_iterator(&sections[0]) {
        nums := strings.split(line, "-")
        assert(len(nums) == 2, "malformed input")
        lower := strconv.parse_i64(nums[0]) or_continue
        upper := strconv.parse_i64(nums[1]) or_continue
        append(&ranges, [2]i64{lower, upper})
    }

    outer: for line in strings.split_lines_iterator(&sections[1]) {
        num := strconv.parse_i64(line) or_continue
        for range in ranges {
            if is_in_range_inclusive(range, num) {
                part1 += 1
                continue outer
            }
        }
    }

    for any_ranges_are_overlapping(ranges[:]) {
        range_a, ok := pop_front_safe(&ranges)
        overrlapping_range_index := -1
        combined_range: [2]i64
        for range_b, i in ranges {
            if are_ranges_overlapping(range_a, range_b) {
                overrlapping_range_index = i
                combined_range = combine_ranges(range_a, range_b)
                break
            }
        }

        if overrlapping_range_index != -1 {
            unordered_remove(&ranges, overrlapping_range_index)
            append(&ranges, combined_range)
        } else {
            append(&ranges, range_a) // put it in the back
        }
    }

    for r in ranges do part2 += (r[1] - r[0]) + 1
    return
}

@(private = "file")
any_ranges_are_overlapping :: proc "contextless" (ranges: [][2]i64) -> bool {
    for r in ranges {
        for b in ranges {
            if r == b do continue
            if are_ranges_overlapping(r, b) {
                return true
            }
        }
    }
    return false
}

@(private = "file")
is_in_range_inclusive :: #force_inline proc "contextless" (range: [2]i64, num: i64) -> bool {
    return num >= range[0] && num <= range[1]
}

@(private = "file")
are_ranges_overlapping :: #force_inline proc "contextless" (a, b: [2]i64) -> bool {
    return is_in_range_inclusive(a, b[0]) || is_in_range_inclusive(a, b[1])
}

/// only run this if the ranges actually overlap, this proc does not check for overlap
@(private = "file")
combine_ranges :: #force_inline proc "contextless" (a, b: [2]i64) -> [2]i64 {
    return [2]i64{min(a[0], b[0]), max(a[1], b[1])}
}
