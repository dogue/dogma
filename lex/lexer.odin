package lex

import "core:unicode"
import "core:unicode/utf8"

// Provides a basic UTF-8 compatible lexer
// and basic utilities for crawling through
// a text source.

Lexer :: struct {
    buf: []rune,
    pos: int,
    line: int,
    col: int,
}

create :: proc(source: string, allocator := context.allocator) -> Lexer {
    l := Lexer{
        line = 1,
        col = 1,
        pos = 0,
    }

    l.buf = utf8.string_to_runes(source, allocator)
    return l
}

consume :: proc(l: ^Lexer) {
    if l.pos >= len(l.buf) - 1 {
        return
    }

    if l.buf[l.pos] == '\n' || l.buf[l.pos] == '\r' {
        l.line += 1
        l.col = 0
    }

    l.pos += 1
    l.col += 1
}

peek :: proc(l: ^Lexer) -> rune {
    if l.pos >= len(l.buf) - 1 {
        return 0
    }

    return l.buf[l.pos + 1]
}

skip_whitespace :: proc(l: ^Lexer) {
    for unicode.is_space(l.buf[l.pos]) {
        consume(l)
    }
}

// reads the buffer until the specified delimiter is reached
// returns the start/end index, including the trailing delimiter
// does not advance past the trailing delimiter
read_until :: proc(l: ^Lexer, delim: rune) -> (start: int, end: int) {
    start = l.pos

    for l.buf[l.pos] != delim {
        consume(l)
    }

    end = l.pos + 1
    return
}

// same as read_until(lexer, delim), except it uses the current
// rune as the delimiter
// returns start/end same as read_until(), but also returns the
// delimiter it used (for debugging purposes)
read_until_next :: proc(l: ^Lexer) -> (start: int, end: int, delim: rune) {
    delim = l.buf[l.pos]
    consume(l)

    start, end = read_until(l, delim)
    start -= 1
    return
}

// read_until() but returns end-1 (trims trailing delimiter)
read_until_trimmed :: proc(l: ^Lexer, delim: rune) -> (start: int, end: int) {
    start, end = read_until(l, delim)
    end -= 1
    return
}

// read_until_next() but returns start/end without including delimiters
read_until_next_trimmed :: proc(l: ^Lexer) -> (start: int, end: int, delim: rune) {
    start, end, delim = read_until_next(l)
    start += 1
    end -= 1
    return
}

read_while_alpha :: proc(l: ^Lexer) -> (start: int, end: int) {
    start = l.pos

    for unicode.is_alpha(l.buf[l.pos]) {
        consume(l)
    }

    consume(l)
    end = l.pos
    return
}

read_while_alphanum :: proc(l: ^Lexer) -> (start: int, end: int) {
    start = l.pos

    for unicode.is_alpha(l.buf[l.pos]) || unicode.is_digit(l.buf[l.pos]) {
        consume(l)
    }

    consume(l)
    end = l.pos
    return
}

read_while_digit :: proc(l: ^Lexer) -> (start: int, end: int) {
    start = l.pos

    for unicode.is_digit(l.buf[l.pos]) {
        consume(l)
    }

    consume(l)
    end = l.pos
    return
}
