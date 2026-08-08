import sys
from luaparser.parser.LuaLexer import LuaLexer
from luaparser.parser.LuaParser import LuaParser
from antlr4 import InputStream, CommonTokenStream
from antlr4.error.ErrorListener import ErrorListener

class MyErrorListener(ErrorListener):
    def syntaxError(self, recognizer, offendingSymbol, line, column, msg, e):
        print(f"Syntax error at line {line}:{column} - {msg}")
        sys.exit(1)

f = open('MSTACK/joinersystem_mobile.lua', 'r', encoding='utf-8').read()
input_stream = InputStream(f)
lexer = LuaLexer(input_stream)
stream = CommonTokenStream(lexer)
parser = LuaParser(stream)
parser.removeErrorListeners()
parser.addErrorListener(MyErrorListener())

try:
    tree = parser.start_()
    print("Parsed successfully!")
except Exception as e:
    pass
