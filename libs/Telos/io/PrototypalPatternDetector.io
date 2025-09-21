#!/usr/bin/env io
/*
Prototypal Pattern Detection Library
====================================

This library provides systematic detection and validation of prototypal purity
violations in Io code. Based on the research documents, prototypal purity is
a foundational, non-negotiable architectural requirement.

Key Patterns Enforced:
1. Parameters as Objects (not simple values)
2. Variables as Slots (message passing only)
3. Immediate Usability (no init ceremonies)
4. Message Passing Universal (no direct property access)
5. Live Delegation (proper prototype chains)
*/

PrototypalPatternDetector := Object clone
PrototypalPatternDetector name := "Prototypal Pattern Detection Library"
PrototypalPatternDetector version := "1.0"

// Core validation patterns
PrototypalPatternDetector violations := Map clone
PrototypalPatternDetector complianceScore := 0.0
PrototypalPatternDetector scanResults := Map clone

// Initialize violation tracking
PrototypalPatternDetector initialize := method(
    self violations atPut("parameterViolations", list())
    self violations atPut("variableViolations", list())
    self violations atPut("initViolations", list())
    self violations atPut("propertyAccessViolations", list())
    self violations atPut("delegationViolations", list())
    self scanResults atPut("totalMethods", 0)
    self scanResults atPut("totalPrototypes", 0)
    self scanResults atPut("violationCount", 0)
    self
)

// Pattern 1: Parameter as Objects Validation
PrototypalPatternDetector validateParameterUsage := method(methodObj, methodName,
    validator := Object clone
    validator methodObj := methodObj
    validator methodName := methodName
    validator violations := list()
    
    // Check if method treats parameters as simple values
    // This is a simplified check - in practice would need AST analysis
    validator checkPattern := method(
        // Look for direct parameter usage patterns
        codeAnalyzer := Object clone
        codeAnalyzer hasDirectParameterUsage := false
        
        // Simplified heuristic: check for common violation patterns
        // In full implementation, would parse method AST
        if(self methodName containsSeq("method(") and 
           self methodName containsSeq("==") and
           not(self methodName containsSeq("clone")),
            codeAnalyzer hasDirectParameterUsage := true
            self violations append("Direct parameter comparison without object wrapper")
        )
        
        codeAnalyzer hasDirectParameterUsage
    )
    
    if(validator checkPattern,
        violation := Object clone
        violation type := "parameterViolation"
        violation method := methodName
        violation description := "Parameter treated as simple value instead of prototypal object"
        violation suggestion := "Create object wrapper: paramObj := Object clone; paramObj value := param"
        
        self violations at("parameterViolations") append(violation)
    )
    
    validator
)

// Pattern 2: Variables as Slots Validation  
PrototypalPatternDetector validateVariableUsage := method(codeBlock, contextName,
    validator := Object clone
    validator codeBlock := codeBlock
    validator contextName := contextName
    validator violations := list()
    
    validator checkPattern := method(
        // Look for direct variable assignments without object context
        codeAnalyzer := Object clone
        codeAnalyzer hasDirectAssignment := false
        
        // Simplified pattern matching
        if(self codeBlock containsSeq(":=") and 
           not(self codeBlock containsSeq("clone")) and
           not(self codeBlock containsSeq("Object")),
            codeAnalyzer hasDirectAssignment := true
            self violations append("Direct variable assignment without slot-based approach")
        )
        
        codeAnalyzer hasDirectAssignment
    )
    
    if(validator checkPattern,
        violation := Object clone
        violation type := "variableViolation"
        violation context := contextName
        violation description := "Variable assigned directly instead of using slot-based approach"
        violation suggestion := "Use slot pattern: obj := Object clone; obj variableName := value"
        
        self violations at("variableViolations") append(violation)
    )
    
    validator
)

// Pattern 3: Immediate Usability Validation
PrototypalPatternDetector validateImmediateUsability := method(prototypeObj, prototypeName,
    validator := Object clone
    validator prototypeObj := prototypeObj
    validator prototypeName := prototypeName
    validator violations := list()
    
    validator checkPattern := method(
        // Check if prototype requires initialization ceremony
        usabilityTester := Object clone
        usabilityTester hasInitMethod := self prototypeObj hasSlot("init")
        usabilityTester hasDoBlock := self prototypeName containsSeq("do(")
        
        if(usabilityTester hasInitMethod,
            self violations append("Prototype has init method - violates immediate usability")
        )
        
        if(usabilityTester hasDoBlock,
            self violations append("Prototype uses do() block - may violate immediate usability")
        )
        
        usabilityTester hasInitMethod or usabilityTester hasDoBlock
    )
    
    if(validator checkPattern,
        violation := Object clone
        violation type := "initViolation"
        violation prototype := prototypeName
        violation description := "Prototype requires initialization ceremony"
        violation suggestion := "Make prototype immediately usable after cloning"
        
        self violations at("initViolations") append(violation)
    )
    
    validator
)

// Pattern 4: Message Passing Validation
PrototypalPatternDetector validateMessagePassing := method(accessPattern, contextName,
    validator := Object clone
    validator accessPattern := accessPattern
    validator contextName := contextName
    validator violations := list()
    
    validator checkPattern := method(
        // Check for property access violations
        accessAnalyzer := Object clone
        accessAnalyzer hasDotAccess := self accessPattern containsSeq(".")
        accessAnalyzer hasDirectAccess := self accessPattern containsSeq(".") and 
                                        not(self accessPattern containsSeq("hasSlot"))
        
        if(accessAnalyzer hasDirectAccess,
            self violations append("Direct property access without hasSlot check")
        )
        
        accessAnalyzer hasDirectAccess
    )
    
    if(validator checkPattern,
        violation := Object clone
        violation type := "propertyAccessViolation"
        violation context := contextName
        violation description := "Property accessed directly instead of through message passing"
        violation suggestion := "Use hasSlot check: if(obj hasSlot(\"prop\"), obj prop, nil)"
        
        self violations at("propertyAccessViolations") append(violation)
    )
    
    validator
)

// Pattern 5: Live Delegation Validation
PrototypalPatternDetector validateDelegation := method(prototypeObj, prototypeName,
    validator := Object clone
    validator prototypeObj := prototypeObj
    validator prototypeName := prototypeName
    validator violations := list()
    
    validator checkPattern := method(
        // Check delegation chain integrity
        delegationAnalyzer := Object clone
        delegationAnalyzer hasProtos := self prototypeObj hasSlot("Protos")
        delegationAnalyzer protosValid := if(delegationAnalyzer hasProtos,
            self prototypeObj Protos != nil,
            false
        )
        
        if(not(delegationAnalyzer protosValid),
            self violations append("Invalid or missing Protos delegation chain")
        )
        
        not(delegationAnalyzer protosValid)
    )
    
    if(validator checkPattern,
        violation := Object clone
        violation type := "delegationViolation"
        violation prototype := prototypeName
        violation description := "Invalid delegation chain structure"
        violation suggestion := "Ensure proper Protos list for delegation"
        
        self violations at("delegationViolations") append(violation)
    )
    
    validator
)

// Comprehensive scan method
PrototypalPatternDetector scanObject := method(targetObj, objectName,
    scanner := Object clone
    scanner targetObj := targetObj
    scanner objectName := objectName
    scanner violations := 0
    
    "Scanning " print; objectName print; " for prototypal compliance..." println
    
    // Validate immediate usability
    self validateImmediateUsability(scanner targetObj, scanner objectName)
    
    // Validate delegation
    self validateDelegation(scanner targetObj, scanner objectName)
    
    // Count violations
    violationCounts := self violations values map(violationList, violationList size)
    scanner violations := 0
    violationCounts foreach(count, scanner violations := scanner violations + count)
    
    currentCount := self scanResults at("violationCount") ifNil(0)
    self scanResults atPut("violationCount", currentCount + scanner violations)
    
    scanner
)

// Calculate compliance score
PrototypalPatternDetector calculateComplianceScore := method(
    calculator := Object clone
    calculator totalMethods := self scanResults at("totalMethods") ifNil(0)
    calculator totalPrototypes := self scanResults at("totalPrototypes") ifNil(0)
    calculator totalChecks := calculator totalMethods + calculator totalPrototypes
    calculator totalViolations := self scanResults at("violationCount") ifNil(0)
    
    if(calculator totalChecks > 0,
        calculator rawScore := 1.0 - (calculator totalViolations / calculator totalChecks)
        self complianceScore := calculator rawScore max(0.0) min(1.0),
        
        self complianceScore := 1.0  // No checks means perfect score
    )
    
    self complianceScore
)

// Generate compliance report
PrototypalPatternDetector generateReport := method(
    reporter := Object clone
    reporter timestamp := Date clone asString
    reporter score := self calculateComplianceScore
    
    "===========================================" println
    "PROTOTYPAL COMPLIANCE SCAN REPORT" println
    "===========================================" println
    "Timestamp: " print; reporter timestamp println
    "Compliance Score: " print; reporter score print; "/1.0" println
    "" println
    
    // Report violations by category
    violationCategories := Object clone
    violationCategories categories := list(
        list("Parameter Violations", "parameterViolations"),
        list("Variable Violations", "variableViolations"), 
        list("Init Violations", "initViolations"),
        list("Property Access Violations", "propertyAccessViolations"),
        list("Delegation Violations", "delegationViolations")
    )
    
    violationCategories categories foreach(category,
        categoryName := category at(0)
        categoryKey := category at(1)
        categoryViolations := self violations at(categoryKey)
        
        categoryName print; ": " print; categoryViolations size print; " violations" println
        
        if(categoryViolations size > 0,
            categoryViolations foreach(violation,
                "  • " print; violation description println
                if(violation hasSlot("suggestion"),
                    "    Fix: " print; violation suggestion println
                )
            )
        )
        "" println
    )
    
    // Overall assessment
    "OVERALL ASSESSMENT:" println
    assessmentLevel := Object clone
    if(reporter score >= 0.9,
        assessmentLevel status := "EXCELLENT"
        assessmentLevel message := "Prototypal purity is well maintained",
        
        if(reporter score >= 0.7,
            assessmentLevel status := "GOOD" 
            assessmentLevel message := "Minor prototypal violations need attention",
            
            if(reporter score >= 0.5,
                assessmentLevel status := "NEEDS IMPROVEMENT"
                assessmentLevel message := "Significant class-like patterns detected",
                
                assessmentLevel status := "CRITICAL"
                assessmentLevel message := "Major prototypal violations require immediate refactoring"
            )
        )
    )
    
    assessmentLevel status print; ": " print; assessmentLevel message println
    
    "===========================================" println
    
    reporter
)

// Auto-fix suggestions
PrototypalPatternDetector generateTransformations := method(
    transformer := Object clone
    transformer suggestions := list()
    
    "PROTOTYPAL TRANSFORMATION SUGGESTIONS:" println
    "======================================" println
    
    // Parameter transformation examples
    if(self violations at("parameterViolations") size > 0,
        "1. Parameter-as-Objects Pattern:" println
        "   Replace: method(param, if(param == nil, ...))" println
        "   With:    method(paramObj," println
        "              analyzer := Object clone" println
        "              analyzer param := paramObj" println
        "              analyzer hasValue := analyzer param != nil" println
        "              if(analyzer hasValue, ...))" println
        "" println
    )
    
    // Variable transformation examples  
    if(self violations at("variableViolations") size > 0,
        "2. Variables-as-Slots Pattern:" println
        "   Replace: result := calculateValue()" println
        "   With:    calculator := Object clone" println
        "            calculator result := calculateValue()" println
        "" println
    )
    
    // Init elimination examples
    if(self violations at("initViolations") size > 0,
        "3. Immediate Usability Pattern:" println
        "   Replace: MyProto := Object clone do(init := method(...))" println
        "   With:    MyProto := Object clone" println
        "            MyProto defaultValue := \"ready\"" println
        "            MyProto clone := method(newInst := resend; newInst)" println
        "" println
    )
    
    transformer
)

// Initialize the detector
PrototypalPatternDetector initialize

"Prototypal Pattern Detection Library loaded" println
"Version: " print; PrototypalPatternDetector version println
"Use PrototypalPatternDetector scanObject(obj, \"objName\") to validate compliance" println