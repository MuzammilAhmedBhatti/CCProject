from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Preformatted, PageBreak

styles = getSampleStyleSheet()
styles.add(ParagraphStyle(name="Guide", parent=styles["BodyText"], leading=14, spaceAfter=7))
story = []

def p(text, style="Guide"):
    story.append(Paragraph(text, styles[style]))

def h(text):
    story.append(Spacer(1, 4))
    story.append(Paragraph(text, styles["Heading2"]))

def code(text):
    story.append(Preformatted(text, styles["Code"]))
    story.append(Spacer(1, 6))

p("KiteLang - Compiler Construction Project", "Title")
p("Detailed Linux build, usage, testing, and language-reference guide for the Phase 1 interpreter and Phase 2 LLVM AOT compiler.")
h("1. Purpose and project phases")
p("KiteLang is a Basant-inspired language for algorithmic programming. It combines C-style functions, variables, arrays, expressions, and braces with pecha (if), warna (else), dheel (while), dor (inclusive range loop), and palta (swap).")
p("Phase 1 uses Flex and Bison to parse a program and execute its AST directly. Phase 2 lowers supported AST nodes into textual LLVM IR, which Clang compiles to a native executable.")
h("2. Linux requirements")
p("Install build-essential, Flex, Bison, Clang, and LLVM. A C++17 compiler is required.")
code("sudo apt update\nsudo apt install -y build-essential flex bison clang llvm\nflex --version\nbison --version\nclang --version")
h("3. Build")
code("make\n# Optional: make interpreter\n# Optional: make compiler\n# Cleanup:  make clean")
p("The build creates build/kitelang-interpreter for Phase 1 and build/kitelang-compiler for Phase 2.")
h("4. Phase 1 - interpreter")
code("./build/kitelang-interpreter examples/insertion_sort.kite")
p("Expected output is one number per line: 1, 2, 4, 7, 8, 9. No intermediate code is generated in this phase.")
h("5. Phase 2 - AOT compiler")
code("./build/kitelang-compiler examples/insertion_sort.kite -o build/insertion.ll\nclang build/insertion.ll -o build/insertion\n./build/insertion")
p("The compiler emits LLVM IR. Clang creates a native executable. If -o is omitted, the compiler writes out.ll.")
story.append(PageBreak())
h("6. Language reference")
code("int values[3] = {9, 4, 1};\npecha (values[0] > values[1]) {\n    palta(values[0], values[1]);\n} warna {\n    print(values[0]);\n}\ndheel (values[0] > 0) { values[0] = values[0] - 1; }\ndor (i : 0 -> 2) { print(values[i]); }")
p("Functions use C-style parameters and braces; array parameters use []. Supported declarations are int, float, bool, and void. The implemented runtime uses integer representation, so float and bool keywords currently have integer semantics.")
p("Arithmetic operators are +, -, *, /, and %. Comparison operators are less-than, greater-than, less-or-equal, greater-or-equal, equality, and inequality. Zero is false; any nonzero integer is true. print(expression) writes one integer and a newline.")
h("7. Arrays, loops, and swap")
p("Arrays are fixed-size, one-dimensional, and zero-indexed. Keep indexes in bounds. dor evaluates its inclusive start and end bounds before its loop, then increases its loop variable by one. palta(left, right) exchanges variables or array elements and lowers to ordinary loads and stores in LLVM IR.")
h("8. Test procedure")
code("make test")
p("The test builds both phases, verifies interpreter output against tests/expected_insertion_sort.txt, emits build/insertion.ll, builds a native executable with Clang, runs it, and checks its output against the same expected file. A zero exit status means the end-to-end demonstration passed.")
h("9. Project files")
p("src/kitelang.l: Flex lexer. src/kitelang.y: Bison grammar, AST interpreter, and LLVM emitter. src/ast.hpp: shared AST declarations. examples/insertion_sort.kite: primary demonstration. examples/array_smoke.kite: smoke test. tests/expected_insertion_sort.txt: expected test output. Makefile: build commands. KiteLang_Proposal.pdf: Phase 0 proposal.")
h("10. Troubleshooting and scope")
p("Install missing Flex, Bison, or Clang packages using the requirements command. KiteLang syntax errors include a source line number; check semicolons, braces, and keyword spelling. The project supports integer algorithm programs with fixed one-dimensional arrays in one source file. Pointers, dynamic memory, multidimensional arrays, external libraries, classes, and multi-file programs are outside scope.")

SimpleDocTemplate("README.pdf", pagesize=A4, rightMargin=2*cm, leftMargin=2*cm, topMargin=1.7*cm, bottomMargin=1.7*cm, title="KiteLang README").build(story)
