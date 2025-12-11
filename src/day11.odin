package aoc

import "core:strings"

//https://adventofcode.com/2025/day/11
day11 :: proc(input: string) -> (part1: i64, part2: i64) {
    graph := make(map[string][]string)

    lines := input
    for line in strings.split_lines_iterator(&lines) {
        split := strings.split(line, ": ")
        name := split[0]
        connections: [dynamic]string
        for connection in strings.split_iterator(&split[1], " ") do append(&connections, connection)
        graph[name] = connections[:]
    }

    memo1 := make(map[string]i64)
    part1 = solve_part1("you", graph, &memo1)
    memo2 := make(map[Path]i64)
    part2 = solve_part2("svr", false, false, graph, &memo2)
    return
}

@(private = "file")
Path :: struct {
    node:    string,
    has_fft: bool,
    has_dac: bool,
}

@(private = "file")
solve_part1 :: proc(current: string, graph: map[string][]string, memo: ^map[string]i64) -> i64 {
    if current == "out" do return 1
    if res, ok := memo[current]; ok do return res

    count: i64
    if outputs, ok := graph[current]; ok {
        for output in outputs do count += solve_part1(output, graph, memo)
    }

    memo[current] = count
    return count
}

@(private = "file")
solve_part2 :: proc(
    current: string,
    has_fft: bool,
    has_dac: bool,
    graph: map[string][]string,
    memo: ^map[Path]i64,
) -> i64 {
    if current == "out" {
        return (has_fft && has_dac) ? 1 : 0
    }

    key := Path{current, has_fft, has_dac}
    if res, ok := memo[key]; ok do return res

    count: i64
    if outputs, ok := graph[current]; ok {
        for output in outputs {
            visited_fft := has_fft || (output == "fft")
            visited_dac := has_dac || (output == "dac")
            count += solve_part2(output, visited_fft, visited_dac, graph, memo)
        }
    }

    memo[key] = count
    return count
}
