# KiteLang - Compiler Construction Project

**Group members**

| Name | Roll number |
| --- | --- |
| Mohammad Ibrahim Salman | 23L-0723 |
| Muzammil Ahmed Bhatti | 23L-0688 |
| Muhammad Ali Mahoon | 23L-0531 |

KiteLang is a Basant-inspired language for writing algorithm programs. It keeps C-style functions, variables, arrays, expressions, and braces, and replaces the control-flow keywords with kite-flying words.

| Keyword | Meaning |
| --- | --- |
| `pecha` | `if` |
| `warna` | `else` |
| `dheel` | `while` |
| `dor` | inclusive increasing range loop |
| `palta` | swap two assignable values |

This repository implements both required phases:

1. **Phase 1 - Interpreter:** Flex tokenizes the source, Bison builds an AST, and C++ code inside the Bison grammar file executes that AST directly. No intermediate code is emitted.
2. **Phase 2 - AOT compiler:** the same parser lowers the AST into textual LLVM IR (`.ll`); Clang compiles that IR into a native executable.

```text
program.kite -> Flex lexer -> Bison parser -> AST -+-> Interpreter (Phase 1) -> output
                                                   +-> LLVM IR (Phase 2) -> clang -> native executable
```

`README.pdf` is a more detailed version of this guide, with diagrams. Its LaTeX source is `docs/README.tex`.

## Quick start (for the grader)

```sh
sudo apt update
sudo apt install -y build-essential flex bison clang llvm
make        # build both phases into build/
make test   # run Phase 1 and Phase 2 and compare their output
```

If `make test` prints no `diff` output and exits with status 0, then the interpreter and the natively compiled program both printed `1 2 4 7 8 9` (one number per line).

## Requirements (Linux)

KiteLang requires `make`, a C++17 compiler (`g++`), Flex, Bison, Clang, and LLVM. On Ubuntu/Debian:

```sh
sudo apt update
sudo apt install -y build-essential flex bison clang llvm
```

Confirm the required tools:

```sh
flex --version
bison --version
g++ --version
clang --version
```

> **Clang version:** the generated IR uses LLVM's opaque pointer type `ptr`, so use **Clang/LLVM 15 or newer**. Ubuntu 24.04's default Clang is new enough. On older releases (e.g. Ubuntu 22.04 with Clang 14), run `sudo apt install -y clang-15` and use `clang-15` in place of `clang` in the Phase 2 commands. `make test` calls plain `clang`, so on such a system either point `clang` at the newer version or run the Phase 2 steps by hand.

## Build

From the project root:

```sh
make
```

This creates `build/kitelang-interpreter` (Phase 1, compiled with `-DMODE_INTERPRETER`) and `build/kitelang-compiler` (Phase 2, compiled with `-DMODE_COMPILER`). Both come from the same sources. `make` runs `bison -d` on `src/kitelang.y`, then `flex` on `src/kitelang.l`, then compiles the generated files with `g++ -std=c++17 -Wall -Wextra -O2`.

```sh
make              # build both phases
make interpreter  # build Phase 1 only
make compiler     # build Phase 2 only
make test         # build and verify both phases
make clean        # remove generated build files
```

`FLEX`, `BISON`, `CXX`, and `CXXFLAGS` can be overridden, e.g. `make CXX=clang++`.

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

The value returned by `main` becomes the process exit status (check it with `echo $?`).

### Phase 2 - AOT compiler

```sh
./build/kitelang-compiler examples/insertion_sort.kite -o build/insertion.ll
clang build/insertion.ll -o build/insertion
./build/insertion
```

The first command writes LLVM IR and prints `generated build/insertion.ll`. The second creates a native executable, and the third runs it, printing the same output as the interpreter. If `-o` is omitted, the compiler writes `out.ll` in the current directory.

Every generated `.ll` file begins with:

```llvm
@fmt = private constant [4 x i8] c"%d\0A\00"
declare i32 @printf(ptr, ...)
```

Each KiteLang function becomes one `define i32` / `define void` function. Integer parameters are `i32` and array parameters are `ptr`.

### Command-line usage

```text
kitelang-interpreter source.kite
kitelang-compiler   source.kite [-o output.ll]
```

With no arguments, either tool prints a usage message and exits with status 2. An unreadable file also exits with status 2, and a syntax error exits with status 1.

## Language reference

### Functions

A program contains one or more functions and must contain `main`. Array parameters use `[]`. Recursion is supported.

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

To pass an array argument, use the array's name. Arrays are passed by reference, so the callee can modify the caller's array.

### Variables, arrays, and output

```kite
int score = 10;
int values[4] = {8, 3, 5, 1};
values[1] = score - 2;
print(values[1]);
```

- Declarations accept `int`, `float`, `bool`, and `void` (functions only). The runtime and the IR generator use an integer representation for everything, so `float` and `bool` behave like `int`. A literal such as `3.5` is read as `3`, and `true`/`false` are `1`/`0`.
- Several variables can be declared at once: `int a = 1, b, c = 3;`. An uninitialised variable starts at 0.
- Arrays are fixed-size, one-dimensional, and zero-indexed. Indexes are not bounds-checked, so programs must keep every index in bounds.
- Comments start with `//`.

Supported arithmetic is `+`, `-`, `*`, `/`, and `%`. Comparisons are `<`, `>`, `<=`, `>=`, `==`, and `!=`. Logical `&&`, `||`, and `!`, plus unary `-`, are also available. Zero is false; any nonzero integer is true. `print(expression);` writes one integer and a newline.

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

// The final value is included: prints 0 1 2 3 4
dor (i : 0 -> 4) {
    print(i);
}
```

`dor` evaluates its start and inclusive end bounds before the loop starts, then increases its loop variable by one after each pass. Only increasing ranges are supported. In LLVM IR, it becomes a header block (`dor`) that tests `i <= end`, a body block (`dorbody`) that increments `i`, and an exit block (`enddor`).

### `palta` swap

```kite
palta(values[0], values[1]);
palta(score, values[2]);
```

`palta` exchanges two variables or array elements. The compiler lowers it to ordinary loads and stores in LLVM IR.

## Examples and testing

- [`examples/insertion_sort.kite`](examples/insertion_sort.kite) sorts six integers using `dor`, `pecha`, and `palta`, then prints `1 2 4 7 8 9`.
- [`examples/array_smoke.kite`](examples/array_smoke.kite) prints an array with `dor`. Its expected output is `9 4 7 2 8 1`.

```sh
./build/kitelang-interpreter examples/array_smoke.kite
./build/kitelang-compiler examples/array_smoke.kite -o build/smoke.ll
clang build/smoke.ll -o build/smoke && ./build/smoke
```

To write your own program, create `myprog.kite` with an `int main()` that ends with `return 0;`, then run it with either phase as shown above.

```sh
make test
```

`make test` does the following:

1. Builds both phases.
2. Runs the interpreter and compares its output (`build/interpreter.out`) against `tests/expected_insertion_sort.txt`.
3. Generates `build/insertion.ll` and builds `build/insertion` with Clang.
4. Runs the native program and compares its output (`build/compiler.out`) against the same file.

A zero exit status means both phases passed the end-to-end check.

## Repository layout

| Path | Purpose |
| --- | --- |
| `src/kitelang.l` | Flex lexer: keywords, `true`/`false`, identifiers, numbers, operators, and `//` comments. |
| `src/kitelang.y` | Bison grammar, AST construction, Phase 1 interpreter, Phase 2 LLVM IR emitter, and `main()` driver. |
| `src/ast.hpp` | AST node kinds and `Node` structure shared by parser and lexer. |
| `examples/insertion_sort.kite` | Main Phase 1/2 sorting demonstration. |
| `examples/array_smoke.kite` | Basic array and `dor` loop smoke test. |
| `tests/expected_insertion_sort.txt` | Expected output used by `make test`. |
| `Makefile` | Build, test, and cleanup commands. |
| `README.md` | This guide. |
| `README.pdf` | Detailed PDF version of this guide (required submission document). |
| `docs/README.tex` | LaTeX source of `README.pdf`. |
| `docs/generate_readme.py` | Earlier ReportLab generator for a shorter `README.pdf` (kept for reference). |
| `KiteLang_Proposal.pdf` | Original Phase 0 proposal. |
| `build/` (generated) | `parser.tab.cpp/.hpp`, `lex.yy.cpp`, both executables, and test outputs. |

To rebuild the PDF: `cd docs && pdflatex README.tex && pdflatex README.tex && mv README.pdf ..`

## Troubleshooting

- **`flex`, `bison`, or `clang` not found:** install the packages in Requirements.
- **`KiteLang syntax error at line N`:** check braces, semicolons, and keyword spelling near line N.
- **`KiteLang error: undefined name` / `main function missing` / `wrong argument count`:** declare variables before use, add `int main()`, and match each function's parameter count.
- **`array argument must be an array name`:** pass array parameters as a plain name, e.g. `sort(data, 6)`.
- **Clang rejects `ptr` in the `.ll` file:** your Clang is older than 15; see Requirements.
- **Array problems:** use a valid zero-based index within the declared fixed size.
- **Permission denied for a native program:** run `chmod +x build/insertion` and retry.

## Scope and known limitations

This is a course project focused on integer algorithm programs in one source file. It supports fixed one-dimensional arrays, functions, recursion, conditions, loops, and swap. Pointers, dynamic memory, multidimensional arrays, structs/classes, external libraries, and multi-file programs are outside the implemented scope.

The interpreter supports the whole language. The LLVM back end is narrower, so for programs you want to compile natively:

- Write `pecha`/`dheel` conditions as a single comparison (e.g. `a > b`, `x != 0`). `&&`, `||`, `!`, and unary `-` are not lowered correctly to IR; write `0 - x` instead of `-x`.
- Declare arrays with a literal size (e.g. `int a[6];`).
- Use comparison results only as conditions, not as stored values (`int c = a < b;` will not compile).

Both example programs stay within these rules.
