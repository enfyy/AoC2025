package aoc

import "core:strings"
import "core:strconv"
import "core:math"
import "core:slice"
import "core:fmt"
import la "core:math/linalg"

//https://adventofcode.com/2025/day/8
day8 :: proc(input: string) -> (part1: i64, part2: i64) {
    circuits := make(map[int]int) // box_id -> circuit_id
    box_positions: [dynamic][3]int

    lines := input
    i := 0
    for line in strings.split_lines_iterator(&lines) {
        components := strings.split(line, ",")
        assert(len(components) == 3, "malformed input")
        x := strconv.parse_int(components[0]) or_continue
        y := strconv.parse_int(components[1]) or_continue
        z := strconv.parse_int(components[2]) or_continue
        append(&box_positions, [3]int{x, y, z})
        circuits[i] = i
        i += 1
    }

    // find closest distances of pairs
    Vec_Pair :: struct {
        a, b:       [3]int,
        a_id, b_id: int,
        distance:   f32,
    }
    pairs: [dynamic]Vec_Pair

    for a in 0 ..< len(box_positions) {
        for b in a + 1 ..< len(box_positions) {
            pos_a := box_positions[a]
            pos_b := box_positions[b]
            vec := pos_b - pos_a
            append(&pairs, Vec_Pair{a = pos_a, b = pos_b, distance = sqr_magnitude(vec[:]), a_id = a, b_id = b})
        }
    }
    slice.sort_by(pairs[:], proc(i, j: Vec_Pair) -> bool {return i.distance < j.distance})

    // connect circuits
    PAIRS_TO_CONNECT :: 1000
    counts := make(map[int]int)
    assert(len(pairs) >= PAIRS_TO_CONNECT, "not enough pairs")
    for pair, i in pairs[:] {
        circ_id_a := circuits[pair.a_id] or_continue
        circ_id_b := circuits[pair.b_id] or_continue
        if circ_id_a != circ_id_b {
            for key, circ_id in circuits {
                if circ_id == circ_id_b {
                    circuits[key] = circ_id_a
                }
            }

            only_one_circuit_left := true
            for _, v in circuits {
                if v != circ_id_a {
                    only_one_circuit_left = false
                    break
                }
            }
            // find part2 result
            if only_one_circuit_left {
                part2 = i64(pair.a.x) * i64(pair.b.x)
                break
            }
        }

        // find part1 result
        if i == PAIRS_TO_CONNECT {
            clear(&counts)
            for _, i in box_positions do counts[circuits[i]] += 1

            c, _ := slice.map_values(counts)
            slice.reverse_sort(c)
            part1 = 1
            for v in c[:3] do part1 *= i64(v)
        }
    }

    return
}

@(private = "file")
sqr_magnitude :: proc "contextless" (vec: []int) -> (result: f32) {
    for c in vec do result += math.pow(f32(c), 2)
    return result //return math.sqrt(result)
}
