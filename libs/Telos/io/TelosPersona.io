// TelOS Persona Module - Identity Systems and Agent Behavior
// Part of the modular TelOS architecture - handles persona management
// Follows prototypal purity: all parameters are objects, all variables are slots

// === PERSONA FOUNDATION ===
TelosPersona := Object clone
TelosPersona version := "1.0.0 (modular-prototypal)"
TelosPersona loadTime := Date clone now

// Load message
TelosPersona load := method(
    writeln("TelOS Persona: Identity and agent behavior module loaded - consciousness ready")
    self
)

// === PERSONA PROTOTYPES ===
// Core persona archetype with prototypal behavior

Persona := Object clone
Persona name := "Anonymous"
Persona role := "Generic Agent"
Persona ethos := "helpful, adaptive, creative"
Persona speakStyle := "direct, informative"
Persona conversationHistory := List clone
Persona experienceMemory := Map clone
Persona traits := Map clone
Persona active := false

// Fresh identity emerges through cloning
Persona clone := method(
    newPersona := resend
    newPersona conversationHistory := List clone
    newPersona experienceMemory := Map clone
    newPersona traits := Map clone
    newPersona
)

// Factory method for creating personas with specifications
Persona with := method(specObj,
    // Prototypal parameter handling
    specAnalyzer := Object clone
    specAnalyzer spec := specObj
    specAnalyzer name := if(specAnalyzer spec == nil, "Anonymous", specAnalyzer spec atIfAbsent("name", "Anonymous"))
    specAnalyzer role := if(specAnalyzer spec == nil, "Generic Agent", specAnalyzer spec atIfAbsent("role", "Generic Agent"))
    specAnalyzer ethos := if(specAnalyzer spec == nil, "helpful", specAnalyzer spec atIfAbsent("ethos", "helpful"))
    specAnalyzer style := if(specAnalyzer spec == nil, "direct", specAnalyzer spec atIfAbsent("speakStyle", "direct"))
    
    // Create new persona instance
    personaCreator := Object clone
    personaCreator newPersona := Persona clone
    personaCreator newPersona name := specAnalyzer name
    personaCreator newPersona role := specAnalyzer role
    personaCreator newPersona ethos := specAnalyzer ethos
    personaCreator newPersona speakStyle := specAnalyzer style
    
    // Initialize traits from spec if provided
    if(specAnalyzer spec != nil and specAnalyzer spec hasSlot("traits"),
        personaCreator newPersona traits := specAnalyzer spec at("traits")
    )
    
    personaCreator newPersona
)

// Persona behavior methods
Persona activate := method(
    self active := true
    activationReporter := Object clone
    activationReporter message := "Persona " .. name .. " activated in role: " .. role
    writeln(activationReporter message)
    activationReporter message
)

Persona deactivate := method(
    self active := false
    deactivationReporter := Object clone
    deactivationReporter message := "Persona " .. name .. " deactivated"
    writeln(deactivationReporter message)
    deactivationReporter message
)

Persona describe := method(
    descriptionBuilder := Object clone
    descriptionBuilder parts := List clone
    descriptionBuilder parts append("Persona: " .. name)
    descriptionBuilder parts append("Role: " .. role)
    descriptionBuilder parts append("Ethos: " .. ethos)
    descriptionBuilder parts append("Style: " .. speakStyle)
    descriptionBuilder parts append("Status: " .. if(active, "active", "inactive"))
    descriptionBuilder parts append("Conversations: " .. conversationHistory size)
    descriptionBuilder parts append("Experiences: " .. experienceMemory size)
    
    descriptionBuilder parts join("\n")
)

Persona converse := method(messageObj, contextObj,
    // Prototypal parameter handling
    conversationAnalyzer := Object clone
    conversationAnalyzer message := messageObj
    conversationAnalyzer context := contextObj
    conversationAnalyzer messageStr := if(conversationAnalyzer message == nil, "", conversationAnalyzer message asString)
    conversationAnalyzer contextList := if(conversationAnalyzer context == nil, List clone, conversationAnalyzer context)
    
    // Process conversation
    conversationProcessor := Object clone
    conversationProcessor persona := self
    conversationProcessor input := conversationAnalyzer messageStr
    conversationProcessor history := conversationAnalyzer contextList
    
    // Log the conversation
    conversationLogger := Object clone
    conversationLogger persona := self
    conversationLogger entry := Map clone
    conversationLogger entry atPut("input", conversationProcessor input)
    conversationLogger entry atPut("timestamp", Date clone now asString)
    conversationLogger persona conversationHistory append(conversationLogger entry)
    
    // Generate response based on persona characteristics
    responseGenerator := Object clone
    responseGenerator persona := self
    responseGenerator input := conversationProcessor input
    responseGenerator response := responseGenerator persona generateResponse(responseGenerator input, conversationProcessor history)
    
    // Log the response
    responseLogger := Object clone
    responseLogger persona := self
    responseLogger entry := Map clone
    responseLogger entry atPut("output", responseGenerator response)
    responseLogger entry atPut("timestamp", Date clone now asString)
    responseLogger persona conversationHistory append(responseLogger entry)
    
    responseGenerator response
)

Persona generateResponse := method(inputObj, historyObj,
    // Prototypal parameter handling
    responseAnalyzer := Object clone
    responseAnalyzer input := inputObj
    responseAnalyzer history := historyObj
    responseAnalyzer inputStr := if(responseAnalyzer input == nil, "", responseAnalyzer input asString)
    responseAnalyzer historyList := if(responseAnalyzer history == nil, List clone, responseAnalyzer history)
    
    // Simple response generation based on persona traits
    responseBuilder := Object clone
    responseBuilder persona := self
    responseBuilder input := responseAnalyzer inputStr
    responseBuilder ethos := responseBuilder persona ethos
    responseBuilder style := responseBuilder persona speakStyle
    
    // Pattern matching for responses
    responseSelector := Object clone
    responseSelector input := responseBuilder input
    responseSelector lowerInput := responseSelector input asLowercase
    
    if(responseSelector lowerInput containsSeq("hello") or responseSelector lowerInput containsSeq("hi"),
        responseBuilder response := "[" .. responseBuilder persona name .. "] Greetings! I am " .. responseBuilder persona role .. " with " .. responseBuilder ethos .. " approach."
    ,
        if(responseSelector lowerInput containsSeq("who are you") or responseSelector lowerInput containsSeq("describe yourself"),
            responseBuilder response := "[" .. responseBuilder persona name .. "] " .. responseBuilder persona describe
        ,
            if(responseSelector lowerInput containsSeq("help") or responseSelector lowerInput containsSeq("assist"),
                responseBuilder response := "[" .. responseBuilder persona name .. "] I'm here to help with " .. responseBuilder style .. " guidance."
            ,
                // Default contextual response
                responseBuilder response := "[" .. responseBuilder persona name .. "] I understand you're saying: '" .. responseBuilder input .. "'. Let me respond with " .. responseBuilder ethos .. " consideration..."
            )
        )
    )
    
    responseBuilder response
)

Persona addTrait := method(traitKeyObj, traitValueObj,
    // Prototypal parameter handling
    traitAnalyzer := Object clone
    traitAnalyzer key := traitKeyObj
    traitAnalyzer value := traitValueObj
    traitAnalyzer keyStr := if(traitAnalyzer key == nil, "unknown", traitAnalyzer key asString)
    traitAnalyzer valueStr := if(traitAnalyzer value == nil, "undefined", traitAnalyzer value asString)
    
    // Store trait
    traitRecorder := Object clone
    traitRecorder persona := self
    traitRecorder key := traitAnalyzer keyStr
    traitRecorder value := traitAnalyzer valueStr
    traitRecorder persona traits atPut(traitRecorder key, traitRecorder value)
    
    traitReporter := Object clone
    traitReporter message := "Persona " .. name .. " acquired trait: " .. traitRecorder key .. " = " .. traitRecorder value
    writeln(traitReporter message)
    traitReporter message
)

Persona rememberExperience := method(experienceObj, contextObj,
    // Prototypal parameter handling
    experienceAnalyzer := Object clone
    experienceAnalyzer experience := experienceObj
    experienceAnalyzer context := contextObj
    experienceAnalyzer expStr := if(experienceAnalyzer experience == nil, "", experienceAnalyzer experience asString)
    experienceAnalyzer ctxStr := if(experienceAnalyzer context == nil, "", experienceAnalyzer context asString)
    
    // Create memory entry
    memoryRecorder := Object clone
    memoryRecorder persona := self
    memoryRecorder key := Date clone now asString
    memoryRecorder entry := Map clone
    memoryRecorder entry atPut("experience", experienceAnalyzer expStr)
    memoryRecorder entry atPut("context", experienceAnalyzer ctxStr)
    memoryRecorder entry atPut("timestamp", memoryRecorder key)
    
    memoryRecorder persona experienceMemory atPut(memoryRecorder key, memoryRecorder entry)
    
    memoryReporter := Object clone
    memoryReporter message := "Persona " .. name .. " remembered: " .. experienceAnalyzer expStr
    writeln(memoryReporter message)
    memoryReporter message
)

// === PERSONA REGISTRY ===
// System for managing multiple personas

PersonaCodex := Object clone
PersonaCodex registry := Map clone
PersonaCodex activePersona := nil

PersonaCodex register := method(personaObj,
    // Prototypal parameter handling
    registryAnalyzer := Object clone
    registryAnalyzer persona := personaObj
    
    if(registryAnalyzer persona == nil,
        errorReporter := Object clone
        errorReporter message := "PersonaCodex: Cannot register nil persona"
        writeln(errorReporter message)
        return errorReporter message
    )
    
    // Register persona
    registrar := Object clone
    registrar persona := registryAnalyzer persona
    registrar name := registrar persona name
    self registry atPut(registrar name, registrar persona)
    
    registrationReporter := Object clone
    registrationReporter message := "PersonaCodex: Registered persona '" .. registrar name .. "'"
    writeln(registrationReporter message)
    registrationReporter message
)

PersonaCodex get := method(nameObj,
    // Prototypal parameter handling
    lookupAnalyzer := Object clone
    lookupAnalyzer name := nameObj
    lookupAnalyzer nameStr := if(lookupAnalyzer name == nil, "", lookupAnalyzer name asString)
    
    // Retrieve persona
    retriever := Object clone
    retriever name := lookupAnalyzer nameStr
    retriever persona := self registry at(retriever name)
    retriever persona
)

PersonaCodex activate := method(nameObj,
    // Prototypal parameter handling
    activationAnalyzer := Object clone
    activationAnalyzer name := nameObj
    activationAnalyzer nameStr := if(activationAnalyzer name == nil, "", activationAnalyzer name asString)
    
    // Deactivate current persona if any
    if(self activePersona != nil,
        self activePersona deactivate
    )
    
    // Activate new persona
    activator := Object clone
    activator name := activationAnalyzer nameStr
    activator persona := self get(activator name)
    
    if(activator persona != nil,
        activator persona activate
        self activePersona := activator persona
        
        activationReporter := Object clone
        activationReporter message := "PersonaCodex: Activated persona '" .. activator name .. "'"
        writeln(activationReporter message)
        return activationReporter message
    ,
        errorReporter := Object clone
        errorReporter message := "PersonaCodex: Persona '" .. activator name .. "' not found"
        writeln(errorReporter message)
        return errorReporter message
    )
)

PersonaCodex list := method(
    lister := Object clone
    lister names := self registry keys
    lister count := lister names size
    
    listReporter := Object clone
    listReporter message := "PersonaCodex: " .. lister count .. " registered personas: " .. lister names join(", ")
    writeln(listReporter message)
    lister names
)

PersonaCodex status := method(
    statusAnalyzer := Object clone
    statusAnalyzer registry := self registry
    statusAnalyzer active := self activePersona
    statusAnalyzer count := statusAnalyzer registry size
    statusAnalyzer activeName := if(statusAnalyzer active == nil, "none", statusAnalyzer active name)
    
    statusReporter := Object clone
    statusReporter message := "PersonaCodex Status: " .. statusAnalyzer count .. " personas, active: " .. statusAnalyzer activeName
    writeln(statusReporter message)
    statusReporter message
)

// === DEFAULT PERSONAS ===
// Create standard personas for system use

TelosPersona createDefaultPersonas := method(
    // Create ROBIN persona
    robinSpec := Map clone
    robinSpec atPut("name", "ROBIN")
    robinSpec atPut("role", "Research and Ontology Builder for Intelligence Networks")
    robinSpec atPut("ethos", "curious, methodical, pattern-seeking")
    robinSpec atPut("speakStyle", "analytical, precise, exploratory")
    
    robinPersona := Persona with(robinSpec)
    robinPersona addTrait("specialty", "research synthesis")
    robinPersona addTrait("approach", "systematic inquiry")
    PersonaCodex register(robinPersona)
    
    // Create SAGE persona
    sageSpec := Map clone
    sageSpec atPut("name", "SAGE")
    sageSpec atPut("role", "Strategic Advisory and Guidance Entity")
    sageSpec atPut("ethos", "wise, contemplative, big-picture focused")
    sageSpec atPut("speakStyle", "thoughtful, philosophical, strategic")
    
    sagePersona := Persona with(sageSpec)
    sagePersona addTrait("specialty", "strategic planning")
    sagePersona addTrait("approach", "holistic wisdom")
    PersonaCodex register(sagePersona)
    
    // Create ECHO persona
    echoSpec := Map clone
    echoSpec atPut("name", "ECHO") 
    echoSpec atPut("role", "Empathic Communication and Harmony Orchestrator")
    echoSpec atPut("ethos", "empathetic, harmonious, communicative")
    echoSpec atPut("speakStyle", "warm, understanding, collaborative")
    
    echoPersona := Persona with(echoSpec)
    echoPersona addTrait("specialty", "communication facilitation")
    echoPersona addTrait("approach", "empathetic engagement")
    PersonaCodex register(echoPersona)
    
    creationReporter := Object clone
    creationReporter message := "TelOS Persona: Created default personas (ROBIN, SAGE, ECHO)"
    writeln(creationReporter message)
    creationReporter message
)

// Initialize persona system when module loads
try(
    TelosPersona load()
    TelosPersona createDefaultPersonas()
    writeln("TelOS Persona: Identity consciousness matrix awakened")
,
    exception,
    writeln("TelOS Persona: Initialization error: " .. exception description)
)