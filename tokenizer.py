import sys
from luaparser import ast
from luaparser.parser.LuaLexer import LuaLexer
from antlr4 import InputStream

f = open('MSTACK/joinersystem_mobile.lua', 'r', encoding='utf-8').read()
input_stream = InputStream(f)
lexer = LuaLexer(input_stream)
tokens = lexer.getAllTokens()

last_good_token = None
for t in tokens:
    last_good_token = t

print(f"Total tokens: {len(tokens)}")
if last_good_token:
    print(f"Last token type: {lexer.symbolicNames[last_good_token.type]}, text: {last_good_token.text}, line: {last_good_token.line}, column: {last_good_token.column}")
    
# Now parse and if it fails, we know it reached EOF or something else.
try:
    ast.parse(f)
    print("Parsed successfully!")
except Exception as e:
    print(f"Parse error: {e}")
