from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Preformatted

out = "README.pdf"
styles = getSampleStyleSheet()
story = []
def p(text, style="BodyText"):
    story.append(Paragraph(text, styles[style])); story.append(Spacer(1, 7))
def code(text):
    story.append(Preformatted(text, styles["Code"])); story.append(Spacer(1, 8))
p("KiteLang - Compiler Construction Project", "Title")
p("Linux build and usage guide for the Phase 1 interpreter and Phase 2 LLVM AOT compiler.")
p("Dependencies", "Heading2")
p("Install <b>build-essential</b>, <b>flex</b>, <b>bison</b>, <b>clang</b>, and <b>llvm</b>. On Ubuntu/Debian:")
code("sudo apt update\nsudo apt install -y build-essential flex bison clang llvm")
p("Build", "Heading2"); code("make")
p("This creates build/kitelang-interpreter and build/kitelang-compiler. Use <font name='Courier'>make clean</font> to remove generated files.")
p("Phase 1: Interpreter", "Heading2")
p("The Bison grammar constructs and directly executes the program AST; no intermediate code is created.")
code("./build/kitelang-interpreter examples/insertion_sort.kite")
p("Phase 2: AOT compiler", "Heading2")
p("The compiler emits textual LLVM IR. Clang turns that IR into a native Linux executable.")
code("./build/kitelang-compiler examples/insertion_sort.kite -o build/program.ll\nclang build/program.ll -o build/program\n./build/program")
p("Language use", "Heading2")
code("int data[3] = {9, 4, 1};\npecha (data[0] > data[1]) { palta(data[0], data[1]); }\ndor (i : 0 -> 2) { print(data[i]); }")
p("KiteLang uses pecha/warna for if/else, dheel for while, dor for an inclusive increasing range loop, and palta to exchange two variables or array elements. The implemented runtime core uses integers; float and bool declaration keywords are recognized and share that representation.")
p("Project files", "Heading2")
p("src/kitelang.l: Flex lexer.  src/kitelang.y: Bison grammar, AST, interpreter, and LLVM emitter.  src/ast.hpp: shared AST declarations.  examples/insertion_sort.kite: sample program.  Makefile: Linux build commands.  KiteLang_Proposal.pdf: Phase 0 proposal.")
SimpleDocTemplate(out, pagesize=A4, rightMargin=2*cm, leftMargin=2*cm, topMargin=1.7*cm, bottomMargin=1.7*cm, title="KiteLang README").build(story)
