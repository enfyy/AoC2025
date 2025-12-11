package aoc

import "core:strings"
import "core:strconv"
import "core:fmt"
import "core:math"
import "core:slice"

// https://adventofcode.com/2025/day/10
day10 :: proc(input: string) -> (part1: i64, part2: i64) {
    lines := input
    machines: [dynamic]Machine

    for line in strings.split_lines_iterator(&lines) {
        split := strings.split(line, "] ")
        indicator_string := split[0][1:]

        target := make([]bool, len(indicator_string))
        for ch, i in indicator_string {
            target[i] = (ch == '#')
        }

        split_again := strings.split(split[1], " {")
        joltage_string := split_again[1][:len(split_again[1]) - 1]
        joltage_split := strings.split(joltage_string, ",")
        joltages := make([]int, len(joltage_split))
        for j, i in joltage_split {
            jolt := strconv.parse_int(j) or_continue
            joltages[i] = jolt
        }

        button_sets: [dynamic][]int
        for button_set in strings.split_iterator(&split_again[0], " ") {
            buttons: [dynamic]int
            set := button_set[1:len(button_set) - 1]
            for btn in strings.split_iterator(&set, ",") {
                num := strconv.parse_int(btn) or_continue
                append(&buttons, num)
            }
            append(&button_sets, buttons[:])
        }

        append(
            &machines,
            Machine {
                button_sets = button_sets[:],
                target = target,
                num_lights = len(indicator_string),
                joltages = joltages,
            },
        )
    }

    for machine in machines {
        presses := find_fewest_presses(machine)
        part1 += i64(presses)

        presses2 := find_fewest_presses_joltage(machine)
        part2 += i64(presses2)
    }

    return
}

@(private = "file")
Machine :: struct {
    button_sets: [][]int,
    target:      []bool,
    num_lights:  int,
    joltages:    []int,
}

@(private)
find_fewest_presses :: proc(m: Machine) -> int {
    num_buttons := len(m.button_sets)
    num_lights := m.num_lights
    width := num_buttons + 1

    aug_matrix := make([]bool, num_lights * width, context.temp_allocator)

    for button, btn_idx in m.button_sets {
        for light_idx in button {
            if light_idx < num_lights {
                aug_matrix[light_idx * width + btn_idx] = true
            }
        }
    }

    for i in 0 ..< num_lights {
        aug_matrix[i * width + num_buttons] = m.target[i]
    }

    current_row := 0
    pivot_columns := make([dynamic]int, context.temp_allocator)

    for col in 0 ..< num_buttons {
        if current_row >= num_lights do break

        pivot_row := -1
        for r in current_row ..< num_lights {
            if aug_matrix[r * width + col] {
                pivot_row = r
                break
            }
        }

        if pivot_row == -1 do continue

        if pivot_row != current_row {
            row_a_start := current_row * width
            row_b_start := pivot_row * width
            for k in 0 ..< width {
                aug_matrix[row_a_start + k], aug_matrix[row_b_start + k] =
                    aug_matrix[row_b_start + k], aug_matrix[row_a_start + k]
            }
        }

        row_current_start := current_row * width
        for r in 0 ..< num_lights {
            if r != current_row && aug_matrix[r * width + col] {
                row_r_start := r * width
                for c in 0 ..< width {
                    aug_matrix[row_r_start + c] = aug_matrix[row_r_start + c] != aug_matrix[row_current_start + c]
                }
            }
        }

        append(&pivot_columns, col)
        current_row += 1
    }

    free_vars := make([dynamic]int, context.temp_allocator)
    is_pivot := make([]bool, num_buttons, context.temp_allocator)

    for col in pivot_columns {
        is_pivot[col] = true
    }

    for col in 0 ..< num_buttons {
        if !is_pivot[col] {
            append(&free_vars, col)
        }
    }

    solution := make([]bool, num_buttons, context.temp_allocator)
    lights := make([]bool, num_lights, context.temp_allocator)

    if len(free_vars) == 0 {
        slice.fill(solution, false)
        for row in 0 ..< len(pivot_columns) {
            col := pivot_columns[row]
            solution[col] = aug_matrix[row * width + num_buttons]
        }

        count := 0
        for pressed in solution {
            if pressed do count += 1
        }
        return count
    }

    min_presses := max(int)
    num_free := len(free_vars)

    for combo in 0 ..< (1 << uint(num_free)) {
        slice.fill(solution, false)

        for i in 0 ..< num_free {
            if (combo & (1 << uint(i))) != 0 {
                solution[free_vars[i]] = true
            }
        }

        for row_idx := len(pivot_columns) - 1; row_idx >= 0; row_idx -= 1 {
            pivot_col := pivot_columns[row_idx]
            val := aug_matrix[row_idx * width + num_buttons]

            for col in (pivot_col + 1) ..< num_buttons {
                if aug_matrix[row_idx * width + col] && solution[col] {
                    val = !val
                }
            }
            solution[pivot_col] = val
        }

        slice.fill(lights, false)
        for btn_idx in 0 ..< num_buttons {
            if solution[btn_idx] {
                for light in m.button_sets[btn_idx] {
                    if light < num_lights {
                        lights[light] = !lights[light]
                    }
                }
            }
        }

        matches := true
        for i in 0 ..< num_lights {
            if lights[i] != m.target[i] {
                matches = false
                break
            }
        }

        if matches {
            count := 0
            for pressed in solution {
                if pressed do count += 1
            }
            min_presses = min(min_presses, count)
        }
    }

    return min_presses
}

@(private)
find_fewest_presses_joltage :: proc(m: Machine) -> int {
    num_buttons := len(m.button_sets)
    num_eqs := len(m.joltages)
    width := num_buttons + 1

    aug_matrix := make([]f64, num_eqs * width, context.temp_allocator)

    for btn_idx in 0 ..< num_buttons {
        for counter_idx in m.button_sets[btn_idx] {
            if counter_idx < num_eqs do aug_matrix[counter_idx * width + btn_idx] = 1.0
        }
    }

    for i in 0 ..< num_eqs do aug_matrix[i * width + num_buttons] = f64(m.joltages[i])

    current_row := 0
    pivot_columns := make([dynamic]int, context.temp_allocator)

    for col in 0 ..< num_buttons {
        if current_row >= num_eqs do break

        pivot_row := -1
        for r in current_row ..< num_eqs {
            if math.abs(aug_matrix[r * width + col]) > 1e-9 {
                pivot_row = r
                break
            }
        }

        if pivot_row == -1 do continue

        if pivot_row != current_row {
            row_a_start := current_row * width
            row_b_start := pivot_row * width
            for k in 0 ..< width {
                aug_matrix[row_a_start + k], aug_matrix[row_b_start + k] =
                    aug_matrix[row_b_start + k], aug_matrix[row_a_start + k]
            }
        }

        pivot_val := aug_matrix[current_row * width + col]
        row_current_start := current_row * width
        for c in col ..< width {
            aug_matrix[row_current_start + c] /= pivot_val
        }

        for r in 0 ..< num_eqs {
            if r != current_row {
                row_r_start := r * width
                factor := aug_matrix[row_r_start + col]
                if math.abs(factor) > 1e-9 {
                    for c in col ..< width {
                        aug_matrix[row_r_start + c] -= factor * aug_matrix[row_current_start + c]
                    }
                }
            }
        }

        append(&pivot_columns, col)
        current_row += 1
    }

    free_vars := make([dynamic]int, context.temp_allocator)
    is_pivot := make([]bool, num_buttons, context.temp_allocator)
    for col in pivot_columns do is_pivot[col] = true

    for col in 0 ..< num_buttons {
        if !is_pivot[col] {
            append(&free_vars, col)
        }
    }

    if len(free_vars) == 0 {
        solution := make([]f64, num_buttons, context.temp_allocator)

        for i in 0 ..< len(pivot_columns) {
            solution[pivot_columns[i]] = aug_matrix[i * width + num_buttons]
        }

        total_presses := 0
        for val in solution {
            total_presses += int(math.round(val))
        }
        return total_presses
    }

    min_total := max(int)
    found_any := false

    max_vals := make([]int, num_buttons, context.temp_allocator)

    for j in 0 ..< num_buttons {
        max_val := max(int)
        affects_any := false
        for i in 0 ..< num_eqs {
            affects := false
            for c in m.button_sets[j] {
                if c == i {
                    affects = true
                    break
                }
            }

            if affects {
                affects_any = true
                max_val = min(max_val, m.joltages[i])
            }
        }

        max_vals[j] = affects_any ? max_val : 0
    }

    ctx := Search_Ctx {
        aug_matrix       = aug_matrix,
        pivot_columns    = pivot_columns[:],
        free_vars        = free_vars[:],
        max_vals         = max_vals[:],
        num_buttons      = num_buttons,
        min_total        = &min_total,
        found_any        = &found_any,
        solution_scratch = make([]f64, num_buttons, context.temp_allocator),
    }

    search_free_vars(&ctx, 0, make([]int, len(free_vars), context.temp_allocator))

    if !found_any {
        return 0
    }
    return min_total
}

Search_Ctx :: struct {
    aug_matrix:       []f64,
    pivot_columns:    []int,
    free_vars:        []int,
    max_vals:         []int,
    num_buttons:      int,
    min_total:        ^int,
    found_any:        ^bool,
    solution_scratch: []f64,
}

@(private = "file")
search_free_vars :: proc(ctx: ^Search_Ctx, idx: int, free_vals: []int) {
    if idx == len(ctx.free_vars) {
        solution := ctx.solution_scratch

        slice.fill(solution, 0)

        for i in 0 ..< len(ctx.free_vars) {
            solution[ctx.free_vars[i]] = f64(free_vals[i])
        }

        valid := true
        current_sum := 0

        for i in 0 ..< len(ctx.free_vars) {
            current_sum += free_vals[i]
        }

        width := ctx.num_buttons + 1

        for r in 0 ..< len(ctx.pivot_columns) {
            pivot_col := ctx.pivot_columns[r]
            val := ctx.aug_matrix[r * width + ctx.num_buttons]

            for f_idx in 0 ..< len(ctx.free_vars) {
                free_col := ctx.free_vars[f_idx]
                coeff := ctx.aug_matrix[r * width + free_col]
                val -= coeff * f64(free_vals[f_idx])
            }

            if val < -1e-9 {
                valid = false
                break
            }

            if math.abs(val - math.round(val)) > 1e-9 {
                valid = false
                break
            }

            int_val := int(math.round(val))
            solution[pivot_col] = f64(int_val)
            current_sum += int_val
        }

        if valid {
            ctx.found_any^ = true
            ctx.min_total^ = min(ctx.min_total^, current_sum)
        }
        return
    }

    free_var_idx := ctx.free_vars[idx]
    max_val := ctx.max_vals[free_var_idx]

    for val in 0 ..= max_val {
        free_vals[idx] = val
        search_free_vars(ctx, idx + 1, free_vals)
    }
}
