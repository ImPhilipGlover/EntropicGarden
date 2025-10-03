# Io Programming Language: Syntax and Best Practices Guide

## Table of Contents
1. [Core Philosophy](#core-philosophy)
2. [Installation and Setup](#installation-and-setup)
3. [Interactive Mode](#interactive-mode)
4. [Syntax Fundamentals](#syntax-fundamentals)
5. [Object Model and Prototypes](#object-model-and-prototypes)
6. [Message Passing](#message-passing)
7. [Control Flow](#control-flow)
8. [Importing](#importing)
9. [Concurrency](#concurrency)
10. [Exception Handling](#exception-handling)
11. [Primitives](#primitives)
12. [Unicode Support](#unicode-support)
13. [Embedding Io](#embedding-io)
14. [Best Practices](#best-practices)
15. [Common Patterns](#common-patterns)
16. [Debugging and Introspection](#debugging-and-introspection)
17. [API Reference](#api-reference)

## Core Philosophy

Io is a dynamic prototype-based programming language inspired by Self, Smalltalk, NewtonScript, Act1, Lisp, and Lua. Key principles:

- **Everything is an object**: Numbers, strings, blocks, even the language constructs themselves
- **Everything is a message**: All computation happens through message passing
- **No classes**: Object creation through cloning existing objects (prototypes)
- **Uniformity**: State access and method invocation use identical syntax
- **Simplicity**: Minimal syntax with maximum expressiveness
- **Homoiconic**: Code is data - all expressions are runtime inspectable/modifiable trees

### Goals
Io aims to be:
- **Simple**: Conceptually simple and consistent, easily embedded and extended
- **Powerful**: Highly dynamic and introspective, highly concurrent via coroutines and async I/O
- **Practical**: Fast enough, multi-platform, BSD/MIT license, comprehensive standard packages

## Installation and Setup

### Downloading
Io distributions are available at http://iolanguage.org

### Installing
```bash
# Compile the Io VM
make vm
sudo make install

# Install addon dependencies
sudo make aptget  # or emerge, or port (for OSX)

# Build all addons
make

# Install
sudo make install
```

### Binaries
- `io_static`: VM with minimal primitives, statically linked
- `io`: VM that dynamically loads addons when referenced

## Interactive Mode

Running `io` starts the interactive prompt:

```io
Io> "Hello world!" println
==> Hello world!
```

Expressions are evaluated in the Lobby context. Useful commands:
```io
Lobby slotNames  // View all slots
Protos slotNames  // View namespaces
someObject slotSummary  // Formatted object description
doFile("script.io")  // Run script
doString("1+1")  // Evaluate string
System args  // Command line arguments
```

## Syntax Fundamentals

### Basic Structure
Io has no keywords or statements - everything is an expression composed of messages:

```
expression ::= { message | terminator }
message ::= [wcpad] symbol [scpad] [arguments]
arguments ::= "(" [expression [ { "," expression } ]] ")"
symbol ::= identifier | number | string | operator
terminator ::= "\n" | ";"
```

### Assignment Operators
```
::=  # Creates slot + setter method (newSlot)
:=   # Creates/modifies slot (setSlot)  
=    # Updates existing slot (updateSlot)
```

### Comments
```io
// Single line comment
/* Multi-line
   comment */
/* Single line too */
# Unix script style
```

### Numbers
```io
123         // Integer
123.456     // Float
0x0, 0x0F   // Hex (any casing)
123e-4      // Scientific notation
```

### Strings
```io
"a string"           // Single line
"""multi-line
string"""            // Multi-line (no escaping needed)
"a \"quote\""        // Escaped quotes
```

## Object Model and Prototypes

### Overview
Io's guiding principle is **simplicity and power through conceptual unification**:

| Concept | Unifies |
|---------|---------|
| Scopable blocks | Functions, methods, closures |
| Prototypes | Objects, classes, namespaces, locals |
| Messages | Operators, calls, assigns, var access |

### Prototypes
Everything is an object with:
- **Slots**: Key/value pairs (symbols → objects)
- **Protos**: List of parent objects for inheritance

```io
// Create prototype
Vehicle := Object clone

// Add slots
Vehicle type := "Vehicle"
Vehicle start := method("Engine started" println)

// Create instance
myCar := Vehicle clone
myCar year := 2024
myCar color := "red"
```

### Inheritance
**Differential inheritance**: Objects only store differences from their prototypes.

```io
// Single inheritance
Dog := Animal clone

// Multiple inheritance/mixins
obj := Object clone
obj protos append(Mixin1)
obj protos append(Mixin2)
```

### Methods
Methods are anonymous functions that create locals objects when called:

```io
// Basic method
method(a, b, a + b)

// Method with body
add := method(a, b, 
    result := a + b
    result
)

// Default return is last expression
```

### Blocks
Blocks are lexically scoped methods:

```io
// Block creation
b := block(a, a + b)

// Key difference: scope resolution
// Methods: lookup in target object
// Blocks: lookup in creation context
```

### Special Methods

#### init
Called when object is cloned:
```io
Person := Object clone do(
    init := method(
        self name := ""
        self age := 0
    )
)
```

#### forward
Called when message not found:
```io
MyObject forward := method(
    write("Undefined message: ", call message name, "\n")
    write("Arguments: ", call message argsEvaluatedIn(call sender), "\n")
)
```

#### resend
Sends current message to protos:
```io
A := Object clone
A m := method(write("in A\n"))
B := A clone  
B m := method(write("in B\n"); resend)
B m  // Prints "in B\nin A\n"
```

#### super
Sends message directly to proto:
```io
Dog := Object clone do(
    speak := method("woof" println)
)

fido := Dog clone
fido speak := method(
    "ruf" println
    super(speak)  // Call parent's speak
)
```

## Message Passing

### Basic Messages
```io
// No args - parens optional
"hello" println
"hello" println()

// With args
list(1, 2, 3) at(0)  // Returns 1

// Operators are messages
1 + 2 * 3  // Parsed as 1 +(2 *(3))
```

### Message Precedence
Operators follow C-like precedence, overridable via OperatorTable.

### Dynamic Evaluation
```io
// Selective evaluation for control flow
people select(person, person age < 30)
names := people map(person, person name)

// Short form when expression uses single arg
people select(age < 30)
names := people map(name)
```