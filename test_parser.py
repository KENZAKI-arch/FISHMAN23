import sys
from luaparser import ast
try:
    ast.parse("function f() end end")
    print("Extra end parsed ok!?")
except Exception as e:
    print(f"Extra end error: {type(e).__name__}: {e}")

try:
    ast.parse("function f()")
    print("Missing end parsed ok!?")
except Exception as e:
    print(f"Missing end error: {type(e).__name__}: {e}")
