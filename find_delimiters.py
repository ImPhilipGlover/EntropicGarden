#!/usr/bin/env python3

def find_unmatched_delimiters(filename):
    with open(filename, 'r') as f:
        content = f.read()
    
    paren_stack = []
    brace_stack = []
    bracket_stack = []
    
    for i, char in enumerate(content):
        line_num = content[:i].count('\n') + 1
        col_num = i - content.rfind('\n', 0, i)
        
        if char == '(':
            paren_stack.append((i, line_num, col_num))
        elif char == ')':
            if paren_stack:
                paren_stack.pop()
            else:
                print(f"Extra closing parenthesis at position {i}, line {line_num}, col {col_num}")
                
        elif char == '{':
            brace_stack.append((i, line_num, col_num))
        elif char == '}':
            if brace_stack:
                brace_stack.pop()
            else:
                print(f"Extra closing brace at position {i}, line {line_num}, col {col_num}")
                
        elif char == '[':
            bracket_stack.append((i, line_num, col_num))
        elif char == ']':
            if bracket_stack:
                bracket_stack.pop()
            else:
                print(f"Extra closing bracket at position {i}, line {line_num}, col {col_num}")
    
    # Report unmatched opening delimiters
    for pos, line, col in paren_stack:
        print(f"Unmatched opening parenthesis at position {pos}, line {line}, col {col}")
    for pos, line, col in brace_stack:
        print(f"Unmatched opening brace at position {pos}, line {line}, col {col}")
    for pos, line, col in bracket_stack:
        print(f"Unmatched opening bracket at position {pos}, line {line}, col {col}")

if __name__ == "__main__":
    find_unmatched_delimiters('libs/Telos/io/IoTelos.io')