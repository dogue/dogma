#+private
package lex

import "core:testing"

@(test)
test_create :: proc(t: ^testing.T) {
    input := "hello world"
    l := create(input)
    defer delete(l.buf)

    testing.expect_value(t, len(l.buf), 11)
}

@(test)
test_consume :: proc(t: ^testing.T) {
    input := "hi\nworld"
    l := create(input)
    defer delete(l.buf)

    testing.expect_value(t, l.buf[l.pos], 'h')

    consume(&l)

    testing.expect_value(t, l.pos, 1)
    testing.expect_value(t, l.buf[l.pos], 'i')
    testing.expect_value(t, l.line, 1)
    testing.expect_value(t, l.col, 2)

    consume(&l)
    consume(&l)

    testing.expect_value(t, l.pos, 3)
    testing.expect_value(t, l.buf[l.pos], 'w')
    testing.expect_value(t, l.line, 2)
    testing.expect_value(t, l.col, 1)
}

@(test)
test_read_until :: proc(t: ^testing.T) {
    input := `hello!world`
    l := create(input)
    defer delete(l.buf)

    start, end := read_until(&l, '!')

    testing.expect_value(t, l.pos, 5)
    testing.expect_value(t, start, 0)
    testing.expect_value(t, end, 6)
    testing.expect_value(t, l.buf[l.pos], '!')
}

@(test)
test_read_until_next :: proc(t: ^testing.T) {
    input := `$foobar$bazoof`
    l := create(input)
    defer delete(l.buf)

    start, end, delim := read_until_next(&l)

    testing.expect_value(t, delim, '$')
    testing.expect_value(t, start, 0)
    testing.expect_value(t, end, 8)
    testing.expect_value(t, l.buf[l.pos], '$')
}

@(test)
test_read_until_trimmed :: proc(t: ^testing.T) {
    input := `foobar$bazoof`
    l := create(input)
    defer delete(l.buf)

    start, end := read_until_trimmed(&l, '$')

    testing.expect_value(t, start, 0)
    testing.expect_value(t, end, 6)
    testing.expect_value(t, l.buf[l.pos], '$')
}

@(test)
test_read_until_next_trimmed :: proc(t: ^testing.T) {
    input := `$foobar$bazoof`
    l := create(input)
    defer delete(l.buf)

    start, end, delim := read_until_next_trimmed(&l)

    testing.expect_value(t, delim, '$')
    testing.expect_value(t, start, 1)
    testing.expect_value(t, end, 7)
    testing.expect_value(t, l.buf[l.pos], '$')
}


