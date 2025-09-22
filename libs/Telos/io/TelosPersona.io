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
    # Prototypal parameter handling
    specAnalyzer := Object clone
    specSetter := Object clone
    specSetter specValue := specObj
    specAnalyzer spec := specSetter specValue
    specGetter := Object clone
    specGetter currentSpec := specAnalyzer spec
    nameCalculator := Object clone
    nameCalculator defaultName := "Anonymous"
    nameCalculator specName := if(currentSpec == nil, nameCalculator defaultName, currentSpec atIfAbsent("name", nameCalculator defaultName))
    specAnalyzer name := nameCalculator specName
    roleCalculator := Object clone
    roleCalculator defaultRole := "Generic Agent"
    roleCalculator specRole := if(currentSpec == nil, roleCalculator defaultRole, currentSpec atIfAbsent("role", roleCalculator defaultRole))
    specAnalyzer role := roleCalculator specRole
    ethosCalculator := Object clone
    ethosCalculator defaultEthos := "helpful"
    ethosCalculator specEthos := if(currentSpec == nil, ethosCalculator defaultEthos, currentSpec atIfAbsent("ethos", ethosCalculator defaultEthos))
    specAnalyzer ethos := ethosCalculator specEthos
    styleCalculator := Object clone
    styleCalculator defaultStyle := "direct"
    styleCalculator specStyle := if(currentSpec == nil, styleCalculator defaultStyle, currentSpec atIfAbsent("speakStyle", styleCalculator defaultStyle))
    specAnalyzer style := styleCalculator specStyle
    
    # Create new persona instance
    personaCreator := Object clone
    personaCreator newPersona := Persona clone
    newPersonaGetter := Object clone
    newPersonaGetter newPersona := personaCreator newPersona
    nameSetter := Object clone
    nameSetter nameValue := specAnalyzer name
    newPersonaGetter newPersona name := nameSetter nameValue
    roleSetter := Object clone
    roleSetter roleValue := specAnalyzer role
    newPersonaGetter newPersona role := roleSetter roleValue
    ethosSetter := Object clone
    ethosSetter ethosValue := specAnalyzer ethos
    newPersonaGetter newPersona ethos := ethosSetter ethosValue
    styleSetter := Object clone
    styleSetter styleValue := specAnalyzer style
    newPersonaGetter newPersona speakStyle := styleSetter styleValue
    
    # Initialize traits from spec if provided
    if(currentSpec != nil and currentSpec hasSlot("traits"),
        traitsSetter := Object clone
        traitsSetter traitsValue := currentSpec at("traits")
        newPersonaGetter newPersona traits := traitsSetter traitsValue
    )
    
    newPersonaGetter newPersona
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
    descriptionBuilder partsGetter := Object clone
    descriptionBuilder partsGetter parts := descriptionBuilder parts
    descriptionBuilder partsGetter parts append("Persona: " .. self name)
    descriptionBuilder partsGetter parts append("Role: " .. self role)
    descriptionBuilder partsGetter parts append("Ethos: " .. self ethos)
    descriptionBuilder partsGetter parts append("Style: " .. self speakStyle)
    descriptionBuilder partsGetter parts append("Status: " .. if(self active, "active", "inactive"))
    descriptionBuilder historyGetter := Object clone
    descriptionBuilder historyGetter history := self conversationHistory
    descriptionBuilder partsGetter parts append("Conversations: " .. descriptionBuilder historyGetter history size)
    descriptionBuilder memoryGetter := Object clone
    descriptionBuilder memoryGetter memory := self experienceMemory
    descriptionBuilder partsGetter parts append("Experiences: " .. descriptionBuilder memoryGetter memory size)
    
    descriptionBuilder partsGetter parts join("\n")
)

Persona converse := method(messageObj, contextObj,
    # Prototypal parameter handling
    conversationAnalyzer := Object clone
    messageSetter := Object clone
    messageSetter messageValue := messageObj
    conversationAnalyzer message := messageSetter messageValue
    contextSetter := Object clone
    contextSetter contextValue := contextObj
    conversationAnalyzer context := contextSetter contextValue
    messageGetter := Object clone
    messageGetter currentMessage := conversationAnalyzer message
    contextGetter := Object clone
    contextGetter currentContext := conversationAnalyzer context
    messageStrCalculator := Object clone
    messageStrCalculator defaultMessage := ""
    messageStrCalculator messageStr := if(messageGetter currentMessage == nil, messageStrCalculator defaultMessage, messageGetter currentMessage asString)
    conversationAnalyzer messageStr := messageStrCalculator messageStr
    contextListCalculator := Object clone
    contextListCalculator defaultContext := List clone
    contextListCalculator contextList := if(contextGetter currentContext == nil, contextListCalculator defaultContext, contextGetter currentContext)
    conversationAnalyzer contextList := contextListCalculator contextList
    
    # Process conversation
    conversationProcessor := Object clone
    conversationProcessor persona := self
    messageStrGetter := Object clone
    messageStrGetter messageStr := conversationAnalyzer messageStr
    conversationProcessor input := messageStrGetter messageStr
    contextListGetter := Object clone
    contextListGetter contextList := conversationAnalyzer contextList
    conversationProcessor history := contextListGetter contextList
    
    # Log the conversation
    conversationLogger := Object clone
    conversationLogger persona := self
    conversationLogger entry := Map clone
    entryGetter := Object clone
    entryGetter entry := conversationLogger entry
    inputGetter := Object clone
    inputGetter inputValue := conversationProcessor input
    entryGetter entry atPut("input", inputGetter inputValue)
    timestampSetter := Object clone
    timestampSetter timestampValue := Date clone now asString
    entryGetter entry atPut("timestamp", timestampSetter timestampValue)
    historyGetter := Object clone
    historyGetter history := conversationLogger persona conversationHistory
    entryGetter2 := Object clone
    entryGetter2 entry := conversationLogger entry
    historyGetter history append(entryGetter2 entry)
    
    # Generate response based on persona characteristics
    responseGenerator := Object clone
    responseGenerator persona := self
    inputGetter2 := Object clone
    inputGetter2 inputValue := conversationProcessor input
    responseGenerator input := inputGetter2 inputValue
    historyGetter2 := Object clone
    historyGetter2 historyValue := conversationProcessor history
    responseGenerator history := historyGetter2 historyValue
    personaGetter := Object clone
    personaGetter persona := responseGenerator persona
    inputGetter3 := Object clone
    inputGetter3 inputValue := responseGenerator input
    historyGetter3 := Object clone
    historyGetter3 historyValue := responseGenerator history
    responseGenerator response := personaGetter persona generateResponse(inputGetter3 inputValue, historyGetter3 historyValue)
    
    # Log the response
    responseLogger := Object clone
    responseLogger persona := self
    responseLogger entry := Map clone
    entryGetter3 := Object clone
    entryGetter3 entry := responseLogger entry
    responseGetter := Object clone
    responseGetter responseValue := responseGenerator response
    entryGetter3 entry atPut("output", responseGetter responseValue)
    timestampSetter2 := Object clone
    timestampSetter2 timestampValue := Date clone now asString
    entryGetter3 entry atPut("timestamp", timestampSetter2 timestampValue)
    historyGetter4 := Object clone
    historyGetter4 history := responseLogger persona conversationHistory
    entryGetter4 := Object clone
    entryGetter4 entry := responseLogger entry
    historyGetter4 history append(entryGetter4 entry)
    
    responseGetter responseValue
)

Persona generateResponse := method(inputObj, historyObj,
    // Prototypal parameter handling
    responseAnalyzer := Object clone
    responseAnalyzer input := inputObj
    responseAnalyzer history := historyObj
    responseAnalyzer inputGetter := Object clone
    responseAnalyzer inputGetter currentInput := responseAnalyzer input
    responseAnalyzer historyGetter := Object clone
    responseAnalyzer historyGetter currentHistory := responseAnalyzer history
    responseAnalyzer inputStr := if(responseAnalyzer inputGetter currentInput == nil, "", responseAnalyzer inputGetter currentInput asString)
    responseAnalyzer historyList := if(responseAnalyzer historyGetter currentHistory == nil, List clone, responseAnalyzer historyGetter currentHistory)
    
    // Simple response generation based on persona traits
    responseBuilder := Object clone
    responseBuilder persona := self
    responseBuilder input := responseAnalyzer inputStr
    responseBuilder ethosGetter := Object clone
    responseBuilder ethosGetter ethos := responseBuilder persona ethos
    responseBuilder ethos := responseBuilder ethosGetter ethos
    responseBuilder styleGetter := Object clone
    responseBuilder styleGetter speakStyle := responseBuilder persona speakStyle
    responseBuilder style := responseBuilder styleGetter speakStyle
    
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
    # Prototypal parameter handling
    traitAnalyzer := Object clone
    traitKeySetter := Object clone
    traitKeySetter keyValue := traitKeyObj
    traitAnalyzer key := traitKeySetter keyValue
    traitValueSetter := Object clone
    traitValueSetter valueValue := traitValueObj
    traitAnalyzer value := traitValueSetter valueValue
    keyGetter := Object clone
    keyGetter currentKey := traitAnalyzer key
    valueGetter := Object clone
    valueGetter currentValue := traitAnalyzer value
    keyStrCalculator := Object clone
    keyStrCalculator defaultKey := "unknown"
    keyStrCalculator keyStr := if(keyGetter currentKey == nil, keyStrCalculator defaultKey, keyGetter currentKey asString)
    traitAnalyzer keyStr := keyStrCalculator keyStr
    valueStrCalculator := Object clone
    valueStrCalculator defaultValue := "undefined"
    valueStrCalculator valueStr := if(valueGetter currentValue == nil, valueStrCalculator defaultValue, valueGetter currentValue asString)
    traitAnalyzer valueStr := valueStrCalculator valueStr
    
    # Store trait
    traitRecorder := Object clone
    traitRecorder persona := self
    keyStrGetter := Object clone
    keyStrGetter keyStr := traitAnalyzer keyStr
    traitRecorder key := keyStrGetter keyStr
    valueStrGetter := Object clone
    valueStrGetter valueStr := traitAnalyzer valueStr
    traitRecorder value := valueStrGetter valueStr
    traitsGetter := Object clone
    traitsGetter traits := traitRecorder persona traits
    keyGetter2 := Object clone
    keyGetter2 keyValue := traitRecorder key
    valueGetter2 := Object clone
    valueGetter2 valueValue := traitRecorder value
    traitsGetter traits atPut(keyGetter2 keyValue, valueGetter2 valueValue)
    
    traitReporter := Object clone
    nameGetter := Object clone
    nameGetter nameValue := self name
    keyGetter3 := Object clone
    keyGetter3 keyValue := traitRecorder key
    valueGetter3 := Object clone
    valueGetter3 valueValue := traitRecorder value
    traitReporter message := "Persona " .. nameGetter nameValue .. " acquired trait: " .. keyGetter3 keyValue .. " = " .. valueGetter3 valueValue
    messageGetter := Object clone
    messageGetter messageValue := traitReporter message
    writeln(messageGetter messageValue)
    messageGetter messageValue
)

Persona rememberExperience := method(experienceObj, contextObj,
    # Prototypal parameter handling
    experienceAnalyzer := Object clone
    experienceSetter := Object clone
    experienceSetter experienceValue := experienceObj
    experienceAnalyzer experience := experienceSetter experienceValue
    contextSetter := Object clone
    contextSetter contextValue := contextObj
    experienceAnalyzer context := contextSetter contextValue
    experienceGetter := Object clone
    experienceGetter currentExperience := experienceAnalyzer experience
    contextGetter := Object clone
    contextGetter currentContext := experienceAnalyzer context
    expStrCalculator := Object clone
    expStrCalculator defaultExp := ""
    expStrCalculator expStr := if(experienceGetter currentExperience == nil, expStrCalculator defaultExp, experienceGetter currentExperience asString)
    experienceAnalyzer expStr := expStrCalculator expStr
    ctxStrCalculator := Object clone
    ctxStrCalculator defaultCtx := ""
    ctxStrCalculator ctxStr := if(contextGetter currentContext == nil, ctxStrCalculator defaultCtx, contextGetter currentContext asString)
    experienceAnalyzer ctxStr := ctxStrCalculator ctxStr
    
    # Create memory entry
    memoryRecorder := Object clone
    memoryRecorder persona := self
    memoryRecorder key := Date clone now asString
    memoryRecorder entry := Map clone
    entryGetter := Object clone
    entryGetter entry := memoryRecorder entry
    expStrGetter := Object clone
    expStrGetter expStr := experienceAnalyzer expStr
    entryGetter entry atPut("experience", expStrGetter expStr)
    ctxStrGetter := Object clone
    ctxStrGetter ctxStr := experienceAnalyzer ctxStr
    entryGetter entry atPut("context", ctxStrGetter ctxStr)
    keyGetter := Object clone
    keyGetter keyValue := memoryRecorder key
    entryGetter entry atPut("timestamp", keyGetter keyValue)
    
    memoryGetter := Object clone
    memoryGetter memory := memoryRecorder persona experienceMemory
    keyGetter2 := Object clone
    keyGetter2 keyValue := memoryRecorder key
    entryGetter2 := Object clone
    entryGetter2 entry := memoryRecorder entry
    memoryGetter memory atPut(keyGetter2 keyValue, entryGetter2 entry)
    
    memoryReporter := Object clone
    nameGetter := Object clone
    nameGetter nameValue := self name
    expStrGetter2 := Object clone
    expStrGetter2 expStr := experienceAnalyzer expStr
    memoryReporter message := "Persona " .. nameGetter nameValue .. " remembered: " .. expStrGetter2 expStr
    messageGetter := Object clone
    messageGetter messageValue := memoryReporter message
    writeln(messageGetter messageValue)
    messageGetter messageValue
)

// === PERSONA REGISTRY ===
// System for managing multiple personas

PersonaCodex := Object clone
PersonaCodex registry := Map clone
PersonaCodex activePersona := nil

PersonaCodex register := method(personaObj,
    # Prototypal parameter handling
    registryAnalyzer := Object clone
    personaSetter := Object clone
    personaSetter personaValue := personaObj
    registryAnalyzer persona := personaSetter personaValue
    personaGetter := Object clone
    personaGetter currentPersona := registryAnalyzer persona
    
    if(personaGetter currentPersona == nil,
        errorReporter := Object clone
        errorReporter message := "PersonaCodex: Cannot register nil persona"
        messageGetter := Object clone
        messageGetter messageValue := errorReporter message
        writeln(messageGetter messageValue)
        return messageGetter messageValue
    )
    
    # Register persona
    registrar := Object clone
    registrar persona := personaGetter currentPersona
    nameGetter := Object clone
    nameGetter name := registrar persona name
    registrar name := nameGetter name
    registryGetter := Object clone
    registryGetter registry := self registry
    nameGetter2 := Object clone
    nameGetter2 nameValue := registrar name
    personaGetter2 := Object clone
    personaGetter2 personaValue := registrar persona
    registryGetter registry atPut(nameGetter2 nameValue, personaGetter2 personaValue)
    
    registrationReporter := Object clone
    nameGetter3 := Object clone
    nameGetter3 nameValue := registrar name
    registrationReporter message := "PersonaCodex: Registered persona '" .. nameGetter3 nameValue .. "'"
    messageGetter2 := Object clone
    messageGetter2 messageValue := registrationReporter message
    writeln(messageGetter2 messageValue)
    messageGetter2 messageValue
)

PersonaCodex get := method(nameObj,
    // Prototypal parameter handling
    lookupAnalyzer := Object clone
    lookupAnalyzer name := nameObj
    lookupAnalyzer nameGetter := Object clone
    lookupAnalyzer nameGetter currentName := lookupAnalyzer name
    lookupAnalyzer nameStr := if(lookupAnalyzer nameGetter currentName == nil, "", lookupAnalyzer nameGetter currentName asString)
    
    // Retrieve persona
    retriever := Object clone
    retriever name := lookupAnalyzer nameStr
    retriever registryGetter := Object clone
    retriever registryGetter registry := self registry
    retriever persona := retriever registryGetter registry at(retriever name)
    retriever persona
)

PersonaCodex activate := method(nameObj,
    # Prototypal parameter handling
    activationAnalyzer := Object clone
    nameSetter := Object clone
    nameSetter nameValue := nameObj
    activationAnalyzer name := nameSetter nameValue
    nameGetter := Object clone
    nameGetter currentName := activationAnalyzer name
    nameStrCalculator := Object clone
    nameStrCalculator defaultName := ""
    nameStrCalculator nameStr := if(nameGetter currentName == nil, nameStrCalculator defaultName, nameGetter currentName asString)
    activationAnalyzer nameStr := nameStrCalculator nameStr
    
    # Deactivate current persona if any
    currentPersonaGetter := Object clone
    currentPersonaGetter currentActive := self activePersona
    if(currentPersonaGetter currentActive != nil,
        activeSetter := Object clone
        activeSetter activeValue := false
        currentPersonaGetter currentActive active := activeSetter activeValue
    )
    
    # Activate new persona
    activator := Object clone
    nameStrGetter := Object clone
    nameStrGetter nameStr := activationAnalyzer nameStr
    activator name := nameStrGetter nameStr
    activator persona := self get(activator name)
    
    personaGetter := Object clone
    personaGetter persona := activator persona
    if(personaGetter persona != nil,
        activeSetter2 := Object clone
        activeSetter2 activeValue := true
        personaGetter persona active := activeSetter2 activeValue
        self activePersona := personaGetter persona
        
        activationReporter := Object clone
        nameGetter2 := Object clone
        nameGetter2 nameValue := activator name
        activationReporter message := "PersonaCodex: Activated persona '" .. nameGetter2 nameValue .. "'"
        messageGetter := Object clone
        messageGetter messageValue := activationReporter message
        writeln(messageGetter messageValue)
        return messageGetter messageValue
    ,
        errorReporter := Object clone
        nameGetter3 := Object clone
        nameGetter3 nameValue := activator name
        errorReporter message := "PersonaCodex: Persona '" .. nameGetter3 nameValue .. "' not found"
        messageGetter2 := Object clone
        messageGetter2 messageValue := errorReporter message
        writeln(messageGetter2 messageValue)
        return messageGetter2 messageValue
    )
)

PersonaCodex list := method(
    lister := Object clone
    lister registryGetter := Object clone
    lister registryGetter registry := self registry
    lister names := lister registryGetter registry keys
    lister count := lister names size
    
    listReporter := Object clone
    listReporter message := "PersonaCodex: " .. lister count .. " registered personas: " .. lister names join(", ")
    writeln(listReporter message)
    lister names
)

PersonaCodex status := method(
    statusAnalyzer := Object clone
    statusAnalyzer registryGetter := Object clone
    statusAnalyzer registryGetter registry := self registry
    statusAnalyzer registry := statusAnalyzer registryGetter registry
    statusAnalyzer activeGetter := Object clone
    statusAnalyzer activeGetter active := self activePersona
    statusAnalyzer active := statusAnalyzer activeGetter active
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