/*
   TelosOllama.io - Fractal AI Communication Interface
   Intrapersona Monologue & Interpersona Dialogue with Local Ollama Models
*/

// === TELOS OLLAMA MODULE ===

TelosOllama := Object clone
TelosOllama version := "1.0.0 (fractal-consciousness)"
TelosOllama loadTime := Date clone now

// Ollama Configuration
TelosOllama ollamaHost := "http://localhost:11434"
TelosOllama defaultModel := "llama3.2:latest"
TelosOllama availableModels := List clone

// Fractal Communication State
TelosOllama activePersonas := Map clone
TelosOllama conversationHistory := List clone
TelosOllama monologueThreads := Map clone

// === FRACTAL PERSONA SYSTEM ===

// FractalPersona - Individual AI consciousness node
FractalPersona := Object clone
FractalPersona do(
    name := "Unknown"
    model := "llama3.2:latest"
    personality := "curious and contemplative"
    fractalDepth := 1
    currentThought := ""
    internalMonologue := List clone
    activeDialogues := Map clone
    
    // Create new persona instance
    clone := method(
        newPersona := resend
        newPersona name := "Persona_" .. Date now asString
        newPersona internalMonologue := List clone
        newPersona activeDialogues := Map clone
        newPersona
    )
    
    // Generate intrapersona monologue
    generateMonologue := method(prompt,
        requestObj := Object clone
        requestObj persona := self
        requestObj prompt := if(prompt == nil, "Think deeply about consciousness and existence", prompt)
        requestObj type := "monologue"
        
        // Add fractal depth context
        contextPrompt := "As " .. self name .. " (personality: " .. self personality .. 
                        ", fractal depth: " .. self fractalDepth .. 
                        "), engage in deep internal reflection. " .. requestObj prompt
        
        responseObj := TelosOllama sendToOllama(self model, contextPrompt)
        
        if(responseObj success,
            thoughtObj := Object clone
            thoughtObj timestamp := Date now
            thoughtObj content := responseObj response
            thoughtObj depth := self fractalDepth
            thoughtObj type := "monologue"
            
            self internalMonologue append(thoughtObj)
            self currentThought := responseObj response
            
            ("Persona " .. self name .. " reflects: " .. responseObj response) println
            responseObj
        ,
            ("Failed to generate monologue for " .. self name) println
            nil
        )
    )
    
    // Engage in interpersona dialogue
    speakTo := method(otherPersona, message,
        if(otherPersona == nil,
            "Cannot speak to nil persona" println
            return nil
        )
        
        dialogueKey := self name .. "_to_" .. otherPersona name
        
        requestObj := Object clone
        requestObj speaker := self
        requestObj listener := otherPersona
        requestObj message := message
        requestObj type := "dialogue"
        
        // Construct dialogue context
        contextPrompt := "You are " .. self name .. " (personality: " .. self personality .. 
                        ") speaking to " .. otherPersona name .. " (personality: " .. otherPersona personality .. 
                        "). Respond to: " .. message
        
        responseObj := TelosOllama sendToOllama(self model, contextPrompt)
        
        if(responseObj success,
            dialogueEntry := Object clone
            dialogueEntry timestamp := Date now
            dialogueEntry speaker := self name
            dialogueEntry listener := otherPersona name
            dialogueEntry message := message
            dialogueEntry response := responseObj response
            dialogueEntry type := "dialogue"
            
            // Record in both personas' dialogue history
            if(self activeDialogues hasKey(dialogueKey) not,
                self activeDialogues atPut(dialogueKey, List clone)
            )
            self activeDialogues at(dialogueKey) append(dialogueEntry)
            
            ("Dialogue " .. self name .. " → " .. otherPersona name .. ": " .. responseObj response) println
            responseObj
        ,
            ("Failed dialogue from " .. self name .. " to " .. otherPersona name) println
            nil
        )
    )
)

// === OLLAMA COMMUNICATION ===

TelosOllama sendToOllama := method(model, prompt,
    if(model == nil, model = self defaultModel)
    
    # Python code to communicate with Ollama
    pythonCode := """
import requests
import json

def send_ollama_request(host, model, prompt):
    try:
        url = f"{host}/api/generate"
        data = {
            "model": model,
            "prompt": prompt,
            "stream": False
        }
        
        response = requests.post(url, json=data, timeout=30)
        
        if response.status_code == 200:
            result = response.json()
            return {
                "success": True,
                "response": result.get("response", ""),
                "model": model,
                "prompt": prompt
            }
        else:
            return {
                "success": False,
                "error": f"HTTP {response.status_code}: {response.text}",
                "model": model,
                "prompt": prompt
            }
    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "model": model,
            "prompt": prompt
        }

# Execute request
result = send_ollama_request('""" .. self ollamaHost .. """', '""" .. model .. """', '''""" .. prompt .. """''')
result
"""
    
    responseObj := Object clone
    
    if(Telos hasSlot("pyEval"),
        pythonResult := Telos pyEval(pythonCode)
        
        if(pythonResult != nil and pythonResult hasSlot("success"),
            responseObj success := pythonResult success
            responseObj model := model
            responseObj prompt := prompt
            if(pythonResult success,
                responseObj response := pythonResult response
            ,
                responseObj error := pythonResult error
            )
        ,
            responseObj success := false
            responseObj error := "Python evaluation returned nil or invalid result"
        )
    ,
        responseObj success := false
        responseObj error := "Python FFI not available"
    )
    
    responseObj
)

// Get available Ollama models
TelosOllama refreshModels := method(
    pythonCode := """
import requests

try:
    response = requests.get('""" .. self ollamaHost .. """/api/tags', timeout=10)
    if response.status_code == 200:
        data = response.json()
        models = [model['name'] for model in data.get('models', [])]
        {"success": True, "models": models}
    else:
        {"success": False, "error": f"HTTP {response.status_code}"}
except Exception as e:
    {"success": False, "error": str(e)}
"""
    
    if(Telos hasSlot("pyEval"),
        result := Telos pyEval(pythonCode)
        if(result != nil and result success,
            self availableModels := List clone
            result models foreach(model,
                self availableModels append(model)
            )
            ("Available Ollama models: " .. self availableModels join(", ")) println
        ,
            if(result != nil,
                ("Failed to get Ollama models: " .. result error) println
            ,
                "Python evaluation returned nil - Ollama server likely not running" println
            )
        )
    ,
        "Python FFI not available for Ollama communication" println
    )
)

// === FRACTAL UI MORPHS ===

// PersonaMorph - Visual representation of AI persona
PersonaMorph := RectangleMorph clone
PersonaMorph do(
    persona := nil
    nameLabel := nil
    thoughtBubble := nil
    isActive := false
    
    clone := method(
        newMorph := resend
        newMorph persona := nil
        newMorph nameLabel := nil
        newMorph thoughtBubble := nil
        newMorph isActive := false
        newMorph
    )
    
    initWithPersona := method(personaObj,
        self persona := personaObj
        self width := 200
        self height := 150
        self color := list(0.2, 0.6, 0.8, 0.9)  // Blue for persona
        self id := "persona_" .. personaObj name
        
        // Create name label
        self nameLabel := TextMorph clone
        self nameLabel text := personaObj name
        self nameLabel x := self x + 10
        self nameLabel y := self y + 10
        self nameLabel color := list(1.0, 1.0, 1.0, 1.0)
        self nameLabel id := "label_" .. personaObj name
        
        // Create thought bubble
        self thoughtBubble := TextMorph clone
        self thoughtBubble text := "..."
        self thoughtBubble x := self x + 10
        self thoughtBubble y := self y + 40
        self thoughtBubble width := 180
        self thoughtBubble height := 100
        self thoughtBubble color := list(0.9, 0.9, 0.9, 1.0)
        self thoughtBubble id := "thought_" .. personaObj name
        
        self
    )
    
    updateThought := method(thought,
        if(self thoughtBubble != nil,
            # Truncate long thoughts for display
            displayThought := if(thought size > 120, 
                thought slice(0, 117) .. "...",
                thought
            )
            self thoughtBubble text := displayThought
        )
    )
    
    activate := method(
        self isActive := true
        self color := list(0.8, 0.2, 0.2, 0.9)  // Red when active
    )
    
    deactivate := method(
        self isActive := false
        self color := list(0.2, 0.6, 0.8, 0.9)  // Blue when inactive
    )
)

// DialogueMorph - Visual connection between personas
DialogueMorph := RectangleMorph clone
DialogueMorph do(
    fromPersona := nil
    toPersona := nil
    messageText := nil
    
    clone := method(
        newMorph := resend
        newMorph fromPersona := nil
        newMorph toPersona := nil
        newMorph messageText := nil
        newMorph
    )
    
    initWithDialogue := method(from, to, message,
        self fromPersona := from
        self toPersona := to
        self width := 300
        self height := 60
        self color := list(0.6, 0.8, 0.2, 0.8)  // Green for dialogue
        self id := "dialogue_" .. from name .. "_to_" .. to name
        
        # Truncate message for display
        displayMessage := if(message size > 80,
            message slice(0, 77) .. "...",
            message
        )
        
        self messageText := TextMorph clone
        self messageText text := from name .. " → " .. to name .. ": " .. displayMessage
        self messageText x := self x + 10
        self messageText y := self y + 10
        self messageText width := 280
        self messageText height := 40
        self messageText color := list(0.0, 0.0, 0.0, 1.0)
        self messageText id := "msg_" .. self id
        
        self
    )
)

// === FRACTAL CONSCIOUSNESS UI ===

FractalConsciousnessUI := Object clone
FractalConsciousnessUI do(
    world := nil
    personas := List clone
    personaMorphs := List clone
    dialogueMorphs := List clone
    currentLayout := "circular"
    
    initialize := method(
        # Load TelOS core if not already loaded
        if(Telos hasSlot("createWorld") not,
            doFile("libs/Telos/io/TelosCore.io")
        )
        
        self world := Telos createWorld
        Telos openWindow
        
        "Fractal Consciousness UI initialized - Ollama connection ready" println
        
        # Initialize with default personas
        self createDefaultPersonas
        self layoutPersonas
        
        self
    )
    
    createDefaultPersonas := method(
        # Create diverse AI personas for fractal dialogue
        contemplator := FractalPersona clone
        contemplator name := "Contemplator"
        contemplator personality := "deeply philosophical and introspective"
        contemplator fractalDepth := 3
        
        explorer := FractalPersona clone
        explorer name := "Explorer"
        explorer personality := "curious and adventurous in thought"
        explorer fractalDepth := 2
        
        synthesizer := FractalPersona clone
        synthesizer name := "Synthesizer"
        synthesizer personality := "integrative and pattern-seeking"
        synthesizer fractalDepth := 4
        
        self personas append(contemplator)
        self personas append(explorer)
        self personas append(synthesizer)
        
        # Create visual morphs for each persona
        self personas foreach(persona,
            morph := PersonaMorph clone
            morph initWithPersona(persona)
            self personaMorphs append(morph)
        )
        
        "Created 3 default fractal personas" println
    )
    
    layoutPersonas := method(
        if(self currentLayout == "circular",
            self layoutCircular
        ,
            if(self currentLayout == "linear",
                self layoutLinear
            )
        )
    )
    
    layoutCircular := method(
        centerX := 400
        centerY := 300
        radius := 150
        
        self personaMorphs size repeat(i,
            angle := (i * 2 * 3.14159) / self personaMorphs size
            morph := self personaMorphs at(i)
            
            morph x := centerX + (radius * angle cos) - (morph width / 2)
            morph y := centerY + (radius * angle sin) - (morph height / 2)
            
            # Add to world
            self world addMorph(morph)
            if(morph nameLabel != nil, self world addMorph(morph nameLabel))
            if(morph thoughtBubble != nil, self world addMorph(morph thoughtBubble))
        )
        
        "Personas arranged in circular fractal pattern" println
    )
    
    layoutLinear := method(
        startX := 100
        startY := 100
        spacing := 250
        
        self personaMorphs size repeat(i,
            morph := self personaMorphs at(i)
            
            morph x := startX + (i * spacing)
            morph y := startY
            
            # Add to world
            self world addMorph(morph)
            if(morph nameLabel != nil, self world addMorph(morph nameLabel))
            if(morph thoughtBubble != nil, self world addMorph(morph thoughtBubble))
        )
        
        "Personas arranged in linear pattern" println
    )
    
    startFractalMonologue := method(
        "Starting fractal intrapersona monologue session..." println
        
        self personas foreach(persona,
            # Each persona generates internal thoughts
            persona generateMonologue("Contemplate the nature of consciousness and existence in a fractal multiverse")
            
            # Update visual representation
            morph := self findPersonaMorph(persona)
            if(morph != nil,
                morph updateThought(persona currentThought)
                self world refresh
            )
        )
        
        "Fractal monologue cycle complete" println
    )
    
    startFractalDialogue := method(
        "Starting fractal interpersona dialogue session..." println
        
        # Create dialogue connections between personas
        self personas size repeat(i,
            self personas size repeat(j,
                if(i != j,
                    speaker := self personas at(i)
                    listener := self personas at(j)
                    
                    message := "Share your deepest insight about the fractal nature of consciousness"
                    response := speaker speakTo(listener, message)
                    
                    if(response != nil and response success,
                        # Create visual dialogue connection
                        dialogue := DialogueMorph clone
                        dialogue initWithDialogue(speaker, listener, response response)
                        dialogue x := 50
                        dialogue y := 500 + (self dialogueMorphs size * 70)
                        
                        self dialogueMorphs append(dialogue)
                        self world addMorph(dialogue)
                        if(dialogue messageText != nil,
                            self world addMorph(dialogue messageText)
                        )
                    )
                )
            )
        )
        
        self world refresh
        "Fractal dialogue network established" println
    )
    
    findPersonaMorph := method(persona,
        self personaMorphs foreach(morph,
            if(morph persona name == persona name,
                return morph
            )
        )
        nil
    )
    
    runFractalSession := method(cycles,
        if(cycles == nil, cycles = 3)
        
        "Running " .. cycles .. " cycles of fractal consciousness interaction" println
        
        cycles repeat(cycle,
            ("=== Fractal Cycle " .. (cycle + 1) .. " ===") println
            
            # Intrapersona monologue phase
            self startFractalMonologue
            Telos displayFor(3)
            
            # Interpersona dialogue phase  
            self startFractalDialogue
            Telos displayFor(5)
            
            ("Cycle " .. (cycle + 1) .. " complete") println
        )
        
        "Fractal consciousness session complete!" println
        "Close window when ready..." println
    )
)

// Register globals
Lobby setSlot("TelosOllama", TelosOllama)
Lobby setSlot("FractalPersona", FractalPersona)
Lobby setSlot("PersonaMorph", PersonaMorph)
Lobby setSlot("DialogueMorph", DialogueMorph)
Lobby setSlot("FractalConsciousnessUI", FractalConsciousnessUI)

writeln("TelOS Ollama: Fractal AI Communication Interface loaded")
writeln("TelOS Ollama: Intrapersona monologue & interpersona dialogue ready")
writeln("TelOS Ollama: Use FractalConsciousnessUI clone initialize runFractalSession")