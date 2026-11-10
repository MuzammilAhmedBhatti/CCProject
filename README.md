# KiteLang - Compiler Construction Project

KiteLang is a Basant-inspired language for learning algorithmic programming. It retains C-style functions, variables, arrays, expressions, and braces, and adds familiar kite-flying words for algorithm control flow.

| Keyword | Meaning |
| --- | --- |
| `pecha` | `if` |
| `warna` | `else` |
| `dheel` | `while` |
| `dor` | inclusive increasing range loop |
| `palta` | swap two assignable values |

This repository implements both required phases:

1. **Phase 1 - Interpreter:** Flex tokenizes source, Bison builds an AST, and C++ actions in the Bison grammar execute that AST. No intermediate code is emitted.
2. **Phase 2 - AOT compiler:** the parser lowers supported AST nodes into textual LLVM IR; Clang builds that IR into a native executable.

## Requirements (Linux)

KiteLang requires `make`, a C++17 compiler, Flex, Bison, Clang, and LLVM. On Ubuntu/Debian:

```sh
sudo apt update
sudo apt install -y build-essential flex bison clang llvm
```

Confirm the required tools:

```sh
flex --version
bison --version
clang --version
```

## Build

From the project root:

```sh
make
```

This creates `build/kitelang-interpreter` (Phase 1) and `build/kitelang-compiler` (Phase 2).

```sh
make              # build both phases
make interpreter  # build Phase 1 only
make compiler     # build Phase 2 only
make test         # build and verify both phases
make clean        # remove generated build files
```

## Run a KiteLang program

### Phase 1 - Interpreter

```sh
./build/kitelang-interpreter examples/insertion_sort.kite
```

Expected output:

```text
1
2
4
7
8
9
```

### Phase 2 - AOT compiler

```sh
./build/kitelang-compiler examples/insertion_sort.kite -o build/insertion.ll
clang build/insertion.ll -o build/insertion
./build/insertion
```

The first command emits LLVM IR, the second creates a native executable, and the final command runs it. If `-o` is omitted, the compiler writes `out.ll` in the current directory.

## Language reference

### Functions

Programs contain one or more functions and must contain `main`. Array parameters use `[]`.

```kite
int add(int left, int right) {
    return left + right;
}

void show(int values[], int count) {
    dor (i : 0 -> count - 1) {
        print(values[i]);
    }
}

int main() {
    print(add(2, 3));
    return 0;
}
```

### Variables, arrays, and output

```kite
int score = 10;
int values[4] = {8, 3, 5, 1};
values[1] = score - 2;
print(values[1]);
```

Declarations accept `int`, `float`, `bool`, and `void` (functions only). The implemented runtime and IR generator use integer representation; `float` and `bool` keywords are accepted with integer semantics. Arrays are fixed-size, one-dimensional, and zero-indexed. Programs must keep all indexes in bounds.

Supported arithmetic is `+`, `-`, `*`, `/`, and `%`. Comparisons are `<`, `>`, `<=`, `>=`, `==`, and `!=`. Logical `&&`, `||`, and `!` are parsed. Zero is false; any nonzero integer is true. `print(expression);` writes one integer and a newline.

### Conditions and loops

```kite
pecha (score > 50) {
    print(score);
} warna {
    print(0);
}

dheel (score > 0) {
    score = score - 1;
}

// The final value is included.
dor (i : 0 -> 4) {
    print(i);
}
```

`dor` evaluates its start and inclusive end bounds before the loop starts, then increases its loop variable by one. This version supports increasing ranges only.

### `palta` swap

```kite
palta(values[0], values[1]);
palta(score, values[2]);
```

`palta` exchanges two variables or array elements. The compiler lowers it to ordinary loads and stores in LLVM IR.

## Example and testing

[`examples/insertion_sort.kite`](examples/insertion_sort.kite) sorts six integers using `dor`, `pecha`, and `palta`, then prints them.

```sh
make test
```

`make test` builds both phases, runs the interpreter, checks its output against `tests/expected_insertion_sort.txt`, generates LLVM IR, builds a native executable with Clang, runs it, and checks that output against the same expected file. A zero exit status means the checked end-to-end demonstration passed.

## Repository layout

| Path | Purpose |
| --- | --- |
| `src/kitelang.l` | Flex lexer: keywords, identifiers, numbers, operators, and `//` comments. |
| `src/kitelang.y` | Bison grammar, AST construction, interpreter, and LLVM IR emitter. |
| `src/ast.hpp` | AST declarations shared by parser and lexer. |
| `examples/insertion_sort.kite` | Main Phase 1/2 sorting demonstration. |
| `examples/array_smoke.kite` | Basic array and `dor` loop smoke test. |
| `tests/expected_insertion_sort.txt` | Expected output used by `make test`. |
| `Makefile` | Build, test, and cleanup commands. |
| `README.pdf` | PDF version of this guide. |
| `KiteLang_Proposal.pdf` | Original Phase 0 proposal. |

## Troubleshooting

- **`flex`, `bison`, or `clang` not found:** install the packages in Requirements.
- **Syntax error:** KiteLang prints a source line number. Check braces, semicolons, and keyword spelling.
- **Array problems:** use a valid zero-based index within the declared fixed size.
- **Permission denied for a native program:** run `chmod +x build/insertion` and retry.

## Scope

This is a course project focused on integer algorithm programs in one source file. It supports fixed one-dimensional arrays, functions, recursion, conditions, loops, and swap. Pointers, dynamic memory, multidimensional arrays, structs/classes, external libraries, and multi-file programs are outside the implemented scope.
