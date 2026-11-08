FLEX ?= flex
BISON ?= bison
CXX ?= g++
CXXFLAGS ?= -std=c++17 -Wall -Wextra -O2

BUILD := build
PARSER := $(BUILD)/parser.tab.cpp
LEXER := $(BUILD)/lex.yy.cpp

.PHONY: all interpreter compiler test clean
all: interpreter compiler

$(BUILD):
	mkdir -p $(BUILD)

$(PARSER): src/kitelang.y src/ast.hpp | $(BUILD)
	$(BISON) -d -o $@ $<

$(LEXER): src/kitelang.l $(PARSER)
	$(FLEX) -o $@ $<

interpreter: $(PARSER) $(LEXER)
	$(CXX) $(CXXFLAGS) -DMODE_INTERPRETER -o $(BUILD)/kitelang-interpreter $(PARSER) $(LEXER)

compiler: $(PARSER) $(LEXER)
	$(CXX) $(CXXFLAGS) -DMODE_COMPILER -o $(BUILD)/kitelang-compiler $(PARSER) $(LEXER)

test: all
	./build/kitelang-interpreter examples/insertion_sort.kite
	./build/kitelang-compiler examples/insertion_sort.kite -o build/insertion.ll
	clang build/insertion.ll -o build/insertion
	./build/insertion

clean:
	rm -rf $(BUILD)
