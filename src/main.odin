package aoc

import "core:fmt"
import "core:time"
import "core:strings"
import "core:strconv"
import "core:os"
import "core:mem"
import "core:mem/virtual"

procs := [?]Day_Proc{day1, day2, day3, day4, day5, day6, day7, day8}
Day_Proc :: #type proc(_: string) -> (i64, i64)

main :: proc() {
    mapped_inputs := map_inputs()
    arena: virtual.Arena
    err := virtual.arena_init_growing(&arena, 20 * mem.Megabyte)
    if err != .None {
        fmt.eprintf("failed to allocate arena: %s", err)
        return
    }
    defer virtual.arena_destroy(&arena)
    context.allocator = virtual.arena_allocator(&arena)
    args := read_args()

    total_duration: f64
    fmt.println("===============================================================")
    fmt.println("|                    PART1 |             PART2 |  TIME        |")
    fmt.println("===============================================================")
    sw: time.Stopwatch
    for day_proc, i in procs {
        index := i + 1

        if day_index_arg, ok := args.day_index.?; ok {
            if index != day_index_arg do continue
        }

        time.stopwatch_start(&sw)
        input, ok := mapped_inputs[index]
        if ok {
            p1, p2 := day_proc(input)
            time.stopwatch_stop(&sw)
            duration_in_ms := time.duration_milliseconds(time.stopwatch_duration(sw))
            fmt.printfln(":: Day %d: %16s | %16s | %fms", index, fmt.tprint(p1), fmt.tprint(p2), duration_in_ms)
            total_duration += duration_in_ms
        } else {
            fmt.printfln(":: Day %d -- !! INPUT NOT FOUND !! (expected path: ../inputs/%d.txt)", index, index)
        }
        fmt.println("---------------------------------------------------------------")
        time.stopwatch_reset(&sw)
        free_all()
    }
    fmt.printfln("_.~+^' MERRY CHRISTMAS '^+~._          TOTAL: | %5Fms", total_duration)
    fmt.println("---------------------------------------------------------------")
}

map_inputs :: proc() -> map[int]string {
    inputs := #load_directory("../inputs")
    result := make(map[int]string)
    for input in inputs {
        splits, err := strings.split(input.name, ".")
        if len(splits) != 2 do continue
        num, ok := strconv.parse_int(splits[0])
        if !ok do continue
        result[num] = string(input.data)
    }

    return result
}

when ODIN_OS == .Windows {
    NEWLINE :: "\r\n"
    DOUBLE_NEWLINE :: "\r\n\r\n"
} else {
    NEWLINE :: "\n"
    DOUBLE_NEWLINE :: "\n\n"
}

read_args :: proc() -> (args: struct {
        day_index: Maybe(int),
    }) {
    if len(os.args) > 1 {
        arg := os.args[1]
        day_index, ok := strconv.parse_int(arg)
        if ok do args.day_index = day_index
    }
    return
}

// HELPERS ------

oob :: #force_inline proc "contextless" (bounds: [2]int, pos: [2]int) -> bool {
    return !is_in_bounds(bounds, pos)
}

is_in_bounds :: #force_inline proc "contextless" (bounds: [2]int, pos: [2]int) -> bool {
    return pos.x >= 0 && pos.x < bounds.x && pos.y >= 0 && pos.y < bounds.y
}
