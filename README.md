# KiteLang - Compiler Construction Project

KiteLang is a small, Basant-inspired language for teaching algorithmic programming. It keeps C-like types, arrays, functions, and braces, while providing `pecha` (if), `warna` (else), `dheel` (while), `dor` (inclusive range loop), and `palta` (swap).

## Dependencies (Linux)

Install the build tools and LLVM/Clang:

```sh
sudo apt update
sudo apt install -y build-essential flex bison clang llvm
```

The project uses only Flex and Bison for lexical analysis and parsing. The Phase 2 executable emits textual LLVM IR, which Clang compiles to a native executable.

## Build

```sh
make
```

This creates `build/kitelang-interpreter` for Phase 1 and `build/kitelang-compiler` for Phase 2. Use `make clean` to remove generated build files.

## Phase 1 - Interpreter

Run a KiteLang program directly:

```sh
./build/kitelang-interpreter examples/insertion_sort.kite
```

The interpreter executes AST actions implemented in the Bison grammar source; it does not produce intermediate code.

## Phase 2 - AOT compiler

Generate LLVM IR, then compile it into a native executable:

```sh
./build/kitelang-compiler examples/insertion_sort.kite -o build/program.ll
clang build/program.ll -o build/program
./build/program
```

The IR lowering maps KiteLang statements to ordinary LLVM loads, stores, branches, and calls to `printf`.

## Language quick reference

```kite
int x = 3;
int data[3] = {9, 4, 1};
pecha (x > 0) { print(x); } warna { print(0); }
dheel (x > 0) { x = x - 1; }
dor (i : 0 -> 2) { print(data[i]); }
palta(data[0], data[1]);
```

`dor` evaluates its start and inclusive end bounds once, then increases its loop variable by one. `palta` exchanges two variables or array elements. The implemented core uses integer values; `float` and `bool` are accepted declaration keywords for the proposal-compatible surface syntax but currently share integer runtime representation.

## Included files

- `src/kitelang.l` - Flex lexer: keywords, literals, identifiers, comments, and operators.
- `src/kitelang.y` - Bison grammar, AST structures, interpreter actions, and LLVM IR emitter.
- `src/ast.hpp` - AST declarations shared by generated parser and lexer.
- `examples/insertion_sort.kite` - proposal insertion-sort demonstration.
- `Makefile` - portable Linux build, test, and cleanup commands.
- `README.pdf` - submission-ready version of this guide.
- `KiteLang_Proposal.pdf` - original Phase 0 proposal, retained for reference.
