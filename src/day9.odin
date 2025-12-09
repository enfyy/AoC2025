package aoc

import "core:strings"
import "core:strconv"

// https://adventofcode.com/2025/day/9
day9 :: proc(input: string) -> (part1: i64, part2: i64) {
    red_tile_positions: [dynamic][2]i64
    lines := input
    for line in strings.split_lines_iterator(&lines) {
        components := strings.split(line, ",")
        if len(components) != 2 do continue
        x := strconv.parse_i64(components[0]) or_continue
        y := strconv.parse_i64(components[1]) or_continue

        append(&red_tile_positions, [2]i64{x, y})
    }

    if len(red_tile_positions) == 0 do return

    // part1:
    largest_area_p1: i64 = -1
    for i in 0 ..< len(red_tile_positions) {
        for j in i + 1 ..< len(red_tile_positions) {
            area := calculate_tile_area(red_tile_positions[i], red_tile_positions[j])
            if area > largest_area_p1 do largest_area_p1 = area
        }
    }
    part1 = largest_area_p1

    // part2
    edges: [dynamic]Segment
    red_tile_count := len(red_tile_positions)
    for i in 0 ..< red_tile_count {
        curr := red_tile_positions[i]
        next := red_tile_positions[(i + 1) % red_tile_count] // wrap
        append(&edges, Segment{curr, next})
    }
    largest_area_p2: i64 = -1

    for i in 0 ..< red_tile_count {
        for j in i + 1 ..< red_tile_count {
            p1 := red_tile_positions[i]
            p2 := red_tile_positions[j]

            r_min_x := min(p1.x, p2.x)
            r_max_x := max(p1.x, p2.x)
            r_min_y := min(p1.y, p2.y)
            r_max_y := max(p1.y, p2.y)

            area := (r_max_x - r_min_x + 1) * (r_max_y - r_min_y + 1)
            if area <= largest_area_p2 do continue
            if is_rect_valid(r_min_x, r_max_x, r_min_y, r_max_y, edges[:]) do largest_area_p2 = area
        }
    }

    part2 = largest_area_p2
    return
}

@(private = "file")
Segment :: struct {
    p1, p2: [2]i64,
}

@(private = "file")
calculate_tile_area :: proc(a, b: [2]i64) -> i64 {
    return (abs(b.x - a.x) + 1) * (abs(b.y - a.y) + 1)
}

// ray casting to check if a point is inside the polygon
@(private = "file")
is_point_inside_f64 :: proc(px, py: f64, edges: []Segment) -> bool {
    intersections := 0
    for e in edges {
        is_vertical_edge := e.p1.x == e.p2.x
        if !is_vertical_edge do continue
        vertical_edge_to_the_right := f64(e.p1.x) > px
        edge_spans_y_coord := py > f64(min(e.p1.y, e.p2.y)) && py < f64(max(e.p1.y, e.p2.y))
        if vertical_edge_to_the_right && edge_spans_y_coord do intersections += 1
    }
    return (intersections % 2) != 0 // odd intersection count -> inside
}

// GEMINI, take the wheel

// Checks if a rectangle defined by min/max bounds is valid (inside or on boundary of polygon)
@(private = "file")
is_rect_valid :: proc(min_x, max_x, min_y, max_y: i64, edges: []Segment) -> bool {

    // Condition A: No polygon edge may strictly pass THROUGH the rectangle.
    // They can touch boundaries or overlap boundaries, but cannot cut the interior.
    for e in edges {
        seg_min_x := min(e.p1.x, e.p2.x)
        seg_max_x := max(e.p1.x, e.p2.x)
        seg_min_y := min(e.p1.y, e.p2.y)
        seg_max_y := max(e.p1.y, e.p2.y)

        is_vertical := (seg_min_x == seg_max_x)

        if is_vertical {
            if seg_min_x > min_x && seg_min_x < max_x {
                overlap_start := max(seg_min_y, min_y)
                overlap_end := min(seg_max_y, max_y)
                if overlap_start < overlap_end do return false // edge cuts through interior
            }
        } else {
            if seg_min_y > min_y && seg_min_y < max_y {
                overlap_start := max(seg_min_x, min_x)
                overlap_end := min(seg_max_x, max_x)
                if overlap_start < overlap_end do return false // edge cuts through interior
            }
        }
    }

    // Condition B: The rectangle must be "inside" the polygon.
    // Since we proved no edges cut the interior, we just need to test ONE point.
    // We test the top-left tile: (min_x, min_y).

    // 1. Is the point (min_x, min_y) literally on a segment (Green)?
    point := [2]i64{min_x, min_y}
    on_boundary := false
    for e in edges {
        // Check if point is on segment
        // vertical
        if e.p1.x == e.p2.x && e.p1.x == point.x {
            if point.y >= min(e.p1.y, e.p2.y) && point.y <= max(e.p1.y, e.p2.y) {
                on_boundary = true; break
            }
        }
        // horizontal Segment check
        if e.p1.y == e.p2.y && e.p1.y == point.y {
            if point.x >= min(e.p1.x, e.p2.x) && point.x <= max(e.p1.x, e.p2.x) {
                on_boundary = true; break
            }
        }
    }

    if on_boundary {
        // If the corner is on the boundary, and we know no edges cut the interior,
        // we might still be "outside" if the rectangle goes the wrong way from the boundary.
        // However, checking just one point is risky if it's on the boundary.
        // Let's check a point slightly inside the rectangle: (min_x + 0.1, min_y + 0.1)
        // Ray casting from (min_x + 0.1, min_y + 0.1)
        return is_point_inside_f64(f64(min_x) + 0.1, f64(min_y) + 0.1, edges)
    }

    // If not on boundary, standard integer check (or offset check) works.
    // Using the offset check is consistent.
    return is_point_inside_f64(f64(min_x) + 0.1, f64(min_y) + 0.1, edges)
}
