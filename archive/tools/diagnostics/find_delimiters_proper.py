#!/usr/bin/env python3

def find_unmatched_delimiters_with_strings(filename):
    with open(filename, 'r') as f:
        content = f.read()
    
    paren_stack = []
    brace_stack = []
    bracket_stack = []
    
    in_string = False
    in_comment = False
    i = 0
    
    while i < len(content):
        char = content[i]
        line_num = content[:i].count('\n') + 1
        col_num = i - content.rfind('\n', 0, i)
        
        # Handle multi-line comments /* ... */
        if not in_string and i < len(content) - 1 and content[i:i+2] == '/*':
            in_comment = True
            i += 2
            continue
        elif in_comment and i < len(content) - 1 and content[i:i+2] == '*/':
            in_comment = False
            i += 2
            continue
        
        # Handle single-line comments //
        if not in_string and not in_comment and i < len(content) - 1 and content[i:i+2] == '//':
            # Skip to end of line
            while i < len(content) and content[i] != '\n':
                i += 1
            continue
        
        # Skip if we're in a comment
        if in_comment:
            i += 1
            continue
        
        # Handle string literals
        if char == '"' and (i == 0 or content[i-1] != '\\'):
            in_string = not in_string
            i += 1
            continue
        
        # Skip delimiter checking if we're in a string
        if in_string:
            i += 1
            continue
        
        # Check delimiters
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
        
        i += 1
    
    # Report unmatched opening delimiters
    for pos, line, col in paren_stack:
        print(f"Unmatched opening parenthesis at position {pos}, line {line}, col {col}")
    for pos, line, col in brace_stack:
        print(f"Unmatched opening brace at position {pos}, line {line}, col {col}")
    for pos, line, col in bracket_stack:
        print(f"Unmatched opening bracket at position {pos}, line {line}, col {col}")

if __name__ == "__main__":
    find_unmatched_delimiters_with_strings('libs/Telos/io/IoTelos.io')