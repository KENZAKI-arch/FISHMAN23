import re
lines = open('MSTACK/joinersystem_mobile.lua', encoding='utf-8').readlines()
text = "".join(lines)
def repl_str(m): return '""'
def repl_comment(m): return ''

text_clean = text
text_clean = re.sub(r'\"(?:[^\"\\]|\\.)*\"', repl_str, text_clean)
text_clean = re.sub(r'\'(?:[^\'\\]|\\.)*\'', repl_str, text_clean)
text_clean = re.sub(r'\[\[.*?\]\]', repl_str, text_clean, flags=re.DOTALL)
text_clean = re.sub(r'--\[\[.*?\]\]', repl_comment, text_clean, flags=re.DOTALL)
text_clean = re.sub(r'--.*', repl_comment, text_clean)

print("Original:", lines[1433].strip())
print("Cleaned:", text_clean.split('\n')[1433].strip())
