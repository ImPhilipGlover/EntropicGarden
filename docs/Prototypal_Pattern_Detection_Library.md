# Prototypal Pattern Detection Library

**Purpose**: Provide systematic patterns for detecting and correcting prototypal purity violations in Io code.

## Class-Like Violation Patterns

### 1. Simple Parameter Usage (VIOLATION)
```io
// ❌ VIOLATION: Treating parameter as simple value
method(morphType,
    if(morphType == nil, morphType = "Morph")
    proto := Lobby getSlot(morphType)
)

// ✅ PROTOTYPAL CORRECT: Parameter as object
method(morphTypeObj,
    typeResolver := Object clone
    typeResolver typeName := if(morphTypeObj == nil, "Morph", morphTypeObj asString)
    typeResolver proto := Lobby getSlot(typeResolver typeName) ifNil(Morph)
    proto := typeResolver proto
)
```

**Detection Pattern**: Look for direct parameter usage without object creation
**Auto-Fix**: Wrap parameter in typeResolver object with explicit slots

### 2. Direct Variable Assignment (VIOLATION)
```io
// ❌ VIOLATION: Direct variable assignment
color := "red"
position := List clone append(10, 20)

// ✅ PROTOTYPAL CORRECT: Slot-based assignment
colorObj := Object clone
colorObj value := "red"
positionObj := Object clone
positionObj coordinates := List clone append(10, 20)
```

**Detection Pattern**: Look for `variable := value` without object context
**Auto-Fix**: Create object wrapper with descriptive slot names

### 3. Property Access Violations (VIOLATION)
```io
// ❌ VIOLATION: Direct property access
if(config.enableFeature,
    feature.activate()
)

// ✅ PROTOTYPAL CORRECT: Message passing
configAnalyzer := Object clone
configAnalyzer isEnabled := config hasSlot("enableFeature") and config enableFeature
if(configAnalyzer isEnabled,
    feature activate
)
```

**Detection Pattern**: Look for dot notation property access
**Auto-Fix**: Replace with hasSlot checks and message passing

### 4. Scope Block Issues (VIOLATION)
```io
// ❌ VIOLATION: Complex do() block with scope capture
result := Object clone do(
    position := calculatePosition()
    size := calculateSize()
    color := selectColor()
)

// ✅ PROTOTYPAL CORRECT: Explicit slot assignment
result := Object clone
result position := calculatePosition()
result size := calculateSize()
result color := selectColor()
```

**Detection Pattern**: Look for complex `do()` blocks with multiple assignments
**Auto-Fix**: Extract to explicit slot assignments

### 5. Initialization Ceremony Patterns (VIOLATION)
```io
// ❌ VIOLATION: Class-like initialization
Widget := Object clone do(
    init := method(name, config,
        self name := name
        self config := config
        self setupDefaults()
    )
)

// ✅ PROTOTYPAL CORRECT: Immediate usability
Widget := Object clone
Widget name := "DefaultWidget"
Widget config := Map clone
Widget setupDefaults := method(/* setup logic */)

Widget clone := method(
    newWidget := resend
    newWidget name := "DefaultWidget"
    newWidget config := Map clone
    newWidget setupDefaults()
    newWidget
)
```

**Detection Pattern**: Look for `init := method()` patterns
**Auto-Fix**: Move initialization to prototype slots and clone method

## Prototypal Best Practice Patterns

### 1. Parameter Object Pattern
```io
// Template for proper parameter handling
method(paramObj,
    analyzer := Object clone
    analyzer param := paramObj
    analyzer defaultValue := "default"
    analyzer resolvedValue := if(analyzer param == nil, 
        analyzer defaultValue, 
        analyzer param asString
    )
    // Use analyzer resolvedValue for actual work
)
```

### 2. Variable Slot Pattern
```io
// Template for proper variable handling
processData := method(inputData,
    processor := Object clone
    processor input := inputData
    processor results := List clone
    processor currentItem := nil
    
    processor input foreach(item,
        processor currentItem := item
        processor results append(processor processItem)
    )
    
    processor results
)
```

### 3. Message Passing Flow Pattern
```io
// Template for proper message passing
handleEvent := method(eventObj,
    handler := Object clone
    handler event := eventObj
    handler canHandle := handler event hasSlot("type") and (handler event type == "click")
    
    if(handler canHandle,
        handler processEvent
    )
)
```

### 4. Immediate Usability Pattern
```io
// Template for immediately usable prototypes
MyPrototype := Object clone
MyPrototype defaultState := "ready"
MyPrototype data := List clone
MyPrototype process := method(/* implementation */)

MyPrototype clone := method(
    newInstance := resend
    newInstance data := List clone  // Fresh state
    newInstance
)

// Test: MyPrototype clone process  // Must work without init
```

## Automated Detection Algorithms

### Parameter Violation Scanner
```
scan_for_simple_parameter_usage():
    violations = []
    for each method in code:
        for each parameter in method.parameters:
            if parameter is used directly without object wrapper:
                violations.append({
                    type: "simple_parameter_usage",
                    location: method.name + ":" + parameter.name,
                    fix: "wrap in typeResolver object"
                })
    return violations
```

### Variable Assignment Scanner
```
scan_for_direct_variable_assignments():
    violations = []
    for each line in code:
        if line matches pattern "variable := value" without object context:
            violations.append({
                type: "direct_variable_assignment", 
                location: line.number,
                fix: "create object wrapper with slot"
            })
    return violations
```

### Message Passing Scanner
```
scan_for_property_access_violations():
    violations = []
    for each line in code:
        if line contains dot notation access without hasSlot check:
            violations.append({
                type: "property_access_violation",
                location: line.number,
                fix: "use hasSlot and message passing"
            })
    return violations
```

## Automatic Transformation Engine

### Parameter Transformation
```
transform_parameter_to_object(parameter_name, method_context):
    resolver_name = parameter_name + "Resolver"
    return f"""
    {resolver_name} := Object clone
    {resolver_name} rawParam := {parameter_name}
    {resolver_name} resolvedValue := if({resolver_name} rawParam == nil, 
        "default", 
        {resolver_name} rawParam asString
    )
    """
```

### Variable Transformation  
```
transform_variable_to_slot(variable_assignment):
    var_name = extract_variable_name(variable_assignment)
    value = extract_value(variable_assignment)
    object_name = var_name + "Obj"
    return f"""
    {object_name} := Object clone
    {object_name} value := {value}
    """
```

### Property Access Transformation
```
transform_property_access(property_access):
    object = extract_object(property_access)
    property = extract_property(property_access)
    return f"""
    accessor := Object clone
    accessor hasProperty := {object} hasSlot("{property}")
    accessor value := if(accessor hasProperty, {object} {property}, nil)
    """
```

## Usage in Agent Workflow

### Pre-Code Generation
1. Load pattern library
2. Initialize detection algorithms
3. Prepare transformation templates

### Post-Code Generation
1. Run all violation scanners
2. Calculate compliance score
3. Apply automatic transformations if score < 0.8
4. Document patterns used

### Continuous Learning
1. Track successful transformations
2. Evolve pattern recognition
3. Update best practice templates
4. Build institutional memory

This pattern library enables systematic prototypal compliance validation and automatic improvement of agent-generated code.