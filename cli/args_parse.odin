package cli

import "core:fmt"
import "core:strings"

ArgType :: enum {
    Flag,
    Value,
}

ArgDef :: struct {
    name: string,
    short: rune,
    type: ArgType,
    desc: string,
    required: bool,
}

ParsedArg :: struct {
    def_idx: int,
    value: string,
}

Parser :: struct {
    defs: [dynamic]ArgDef,
    parsed: map[string]ParsedArg,
    positionals: [dynamic]string,
}

ParseErrorType :: enum {
    None,
    MissingValue,
    UndefinedArgument,
    CombinedValueFlags,
    MissingRequiredArgument,
}

ParseError :: struct {
    type: ParseErrorType,
    source: string,
    position: int,
}

parser_create :: proc() -> Parser {
    return Parser{
        defs = make([dynamic]ArgDef),
        parsed = make(map[string]ParsedArg),
        positionals = make([dynamic]string),
    }
}

parser_destroy :: proc(p: ^Parser) {
    delete(p.defs)
    delete(p.parsed)
    delete(p.positionals)
}

add_arg :: proc(p: ^Parser, type: ArgType, name: string, short: rune, desc: string, required := false) {
    append(&p.defs, ArgDef{
        name = name,
        short = short,
        type = type,
        desc = desc,
        required = required
    })
}

get_def_index :: proc {
    get_def_idx_by_name,
    get_def_idx_by_short,
}

get_def_idx_by_name :: proc(p: Parser, name: string) -> int {
    for def, i in p.defs {
        if def.name == name {
            return i
        }
    }

    return -1
}

get_def_idx_by_short :: proc(p: Parser, short: rune) -> int {
    for def, i in p.defs {
        if def.short == short {
            return i
        }
    }

    return -1
}

parse :: proc(p: ^Parser, args: []string) -> (ok: bool, err: ParseError) {
    pos := 0
    for pos < len(args) {
        arg := args[pos]

        // long arguments
        if strings.has_prefix(arg, "--") {
            name := arg[2:]
            def_idx := get_def_index(p^, name)

            if def_idx < 0 {
                return false, ParseError {
                    type = .UndefinedArgument,
                    source = arg,
                    position = pos,
                }
            }

            def := &p.defs[def_idx]

            switch def.type {
            case .Value:
                if pos + 1 >= len(args) {
                    return false, ParseError {
                        type = .MissingValue,
                        source = arg,
                        position = pos,
                    }
                }

                pos += 1
                p.parsed[def.name] = ParsedArg{ def_idx = def_idx, value = args[pos] }


            case .Flag:
                p.parsed[def.name] = ParsedArg{ def_idx = def_idx, value = "" }

            }

        // short arguments
        } else if strings.has_prefix(arg, "-") {
            for c, i in arg[1:] {
                def_idx := get_def_index(p^, c)
                if def_idx < 0 {
                    return false, ParseError {
                        type = .UndefinedArgument,
                        source = fmt.tprintf("%s", c),
                        position = pos + i,
                    }
                }

                def := p.defs[def_idx]

                switch def.type {
                case .Value:
                    if i != 0 {
                        return false, ParseError {
                            type = .CombinedValueFlags,
                            source = arg,
                            position = pos + i,
                        }
                    }

                    if pos + 1 >= len(args) {
                        return false, ParseError {
                            type = .MissingValue,
                            source = arg,
                            position = pos,
                        }
                    }

                    pos += 1
                    p.parsed[def.name] = ParsedArg{ def_idx = def_idx, value = args[pos] }


                case .Flag:
                    p.parsed[def.name] = ParsedArg{ def_idx = def_idx, value = "" }

                }
            }

        // positional arguments
        } else {
            append(&p.positionals, arg)
        }

        pos += 1
    }

    for def in p.defs {
        if !def.required do continue

        if !is_flag_set(p^, def.name) {
            return false, ParseError {
                type = .MissingRequiredArgument,
                source = def.name,
                position = -1,
            }
        }
    }

    return true, ParseError{ type = .None }
}

is_flag_set :: proc(p: Parser, name: string) -> (is_set: bool) {
    _, is_set = p.parsed[name]
    return
}

get_value :: proc(p: Parser, name: string) -> (value: string, ok: bool) {
    if arg, exists := p.parsed[name]; exists {
        return arg.value, true
    }

    return "", false
}

format_help_text :: proc(p: Parser) -> string {
    out := strings.Builder{}
    strings.builder_init_none(&out)

    for def in p.defs {
        switch def.type {
        case .Value: fmt.sbprintf(&out, "\t%s, %c <value> - %s", def.name, def.short, def.desc)
        case .Flag: fmt.sbprintf(&out, "\t%s, %c - %s", def.name, def.short, def.desc)
        }

        if def.required {
            fmt.sbprint(&out, " (required)")
        }

        fmt.sbprint(&out, "\n")
    }

    return strings.to_string(out)
}
