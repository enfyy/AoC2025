package aoc

import "core:strings"
import "core:strconv"
import "core:fmt"

day2 :: proc(input: string) -> (part1: i64, part2: i64) {
    ranges := strings.split(input, ",")
    for range in ranges {
        nums := strings.split(range, "-")
        assert(len(nums) == 2, "broken range")
        lower_string := strings.trim_space(nums[0])
        upper_string := strings.trim_space(nums[1])
        lower := strconv.parse_int(lower_string) or_continue
        upper := strconv.parse_int(upper_string) or_continue

        buffer: [16]byte
        for i in lower ..= upper {
            id := strconv.write_int(buffer[:], i64(i), 10)
            if !check_valid_id_part1(id) do part1 += i64(i)
            if !check_valid_id_part2(id) do part2 += i64(i)
        }
    }
    return
}

check_valid_id_part1 :: proc(s: string) -> bool {
    if len(s) % 2 == 0 && s[:len(s) / 2] == s[len(s) / 2:] {
        return false
    }
    return true
}

check_valid_id_part2 :: proc(s: string) -> bool {
    outer: for chunk_count in 2 ..= len(s) {
        if len(s) % chunk_count != 0 do continue
        chunk_size := len(s) / chunk_count
        pattern := s[:chunk_size]
        for i in 1 ..< chunk_count {
            start := i * chunk_size
            partial := s[start:start + chunk_size]
            if partial != pattern {
                continue outer
            }
        }
        return false
    }

    return true
}
