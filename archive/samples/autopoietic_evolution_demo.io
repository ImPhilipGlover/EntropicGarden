#!/usr/bin/env io

// Advanced Autopoietic Morph Evolution Demo
// Living objects that adapt and evolve their own behaviors

writeln("TelOS Advanced Autopoietic Evolution Demo")
writeln("========================================")

try(
    // === FOUNDATION SETUP ===
    writeln("Setting up Morphic Canvas...")
    world := Telos createWorld
    Telos openWindow
    
    // === EVOLUTIONARY MORPH CREATION ===
    writeln("Creating evolutionary morphs...")
    
    // Create an evolving rectangle that changes behavior over time
    evolvingRect := RectangleMorph clone
    evolvingRect setColor(0.8, 0.2, 0.2, 1.0)  // Start red
    evolvingRect setPosition(100, 100)
    evolvingRect setSize(80, 60)
    evolvingRect name := "evolving_rectangle"
    
    // Add evolutionary state
    evolvingRect generation := 0
    evolvingRect evolutionRate := 0.1
    evolvingRect targetColor := list(0.2, 0.8, 0.2, 1.0)  // Green target
    
    // Add evolutionary behavior method
    evolvingRect evolve := method(
        # Increment generation counter
        generationTracker := Object clone
        generationTracker current := self generation
        generationTracker current = generationTracker current + 1
        self generation := generationTracker current
        
        writeln("Evolution step ", self generation, " for ", self name)
        
        # Color evolution toward target
        colorEvolver := Object clone
        colorEvolver currentR := self color at(0)
        colorEvolver currentG := self color at(1) 
        colorEvolver currentB := self color at(2)
        
        colorEvolver targetR := self targetColor at(0)
        colorEvolver targetG := self targetColor at(1)
        colorEvolver targetB := self targetColor at(2)
        
        # Calculate evolutionary step
        colorEvolver newR := colorEvolver currentR + ((colorEvolver targetR - colorEvolver currentR) * self evolutionRate)
        colorEvolver newG := colorEvolver currentG + ((colorEvolver targetG - colorEvolver currentG) * self evolutionRate)
        colorEvolver newB := colorEvolver currentB + ((colorEvolver targetB - colorEvolver currentB) * self evolutionRate)
        
        # Apply evolved color
        self setColor(colorEvolver newR, colorEvolver newG, colorEvolver newB, 1.0)
        
        # WAL logging for evolution
        Telos walBegin("morph.evolution")
        Telos walAppend("EVOLVE " .. self name .. " gen:" .. self generation)
        Telos walAppend("COLOR " .. colorEvolver newR .. "," .. colorEvolver newG .. "," .. colorEvolver newB)
        Telos walEnd("morph.evolution")
        
        writeln("  Color evolved to (", colorEvolver newR, ",", colorEvolver newG, ",", colorEvolver newB, ")")
        self
    )
    
    world addMorph(evolvingRect)
    
    // Create an adaptive circle that responds to its environment  
    adaptiveCircle := CircleMorph clone
    adaptiveCircle setColor(0.2, 0.2, 0.8, 1.0)  // Start blue
    adaptiveCircle setPosition(300, 150)
    adaptiveCircle setSize(60, 60)
    adaptiveCircle name := "adaptive_circle"
    
    # Add adaptive state
    adaptiveCircle adaptationLevel := 0
    adaptiveCircle maxAdaptation := 5
    
    # Add adaptive behavior method
    adaptiveCircle adapt := method(stimulus,
        stimulusProcessor := Object clone
        stimulusProcessor value := stimulus
        
        adaptationCounter := Object clone
        adaptationCounter current := self adaptationLevel
        
        if(adaptationCounter current < self maxAdaptation,
            adaptationCounter current = adaptationCounter current + 1
            self adaptationLevel := adaptationCounter current
            
            writeln("Adaptation step ", self adaptationLevel, " for ", self name, " (stimulus: ", stimulusProcessor value, ")")
            
            # Adaptive size increase
            sizeAdaptive := Object clone
            sizeAdaptive currentW := self size at(0)
            sizeAdaptive currentH := self size at(1)
            sizeAdaptive growthFactor := 1.1
            
            sizeAdaptive newW := sizeAdaptive currentW * sizeAdaptive growthFactor
            sizeAdaptive newH := sizeAdaptive currentH * sizeAdaptive growthFactor
            
            self setSize(sizeAdaptive newW, sizeAdaptive newH)
            
            # Adaptive color shift
            colorShifter := Object clone
            colorShifter intensity := self adaptationLevel / self maxAdaptation
            colorShifter newColor := 0.2 + (0.6 * colorShifter intensity)
            
            self setColor(colorShifter newColor, 0.2, 0.8, 1.0)
            
            # WAL logging for adaptation
            Telos walBegin("morph.adaptation")
            Telos walAppend("ADAPT " .. self name .. " level:" .. self adaptationLevel)
            Telos walAppend("SIZE " .. sizeAdaptive newW .. "x" .. sizeAdaptive newH)
            Telos walAppend("STIMULUS " .. stimulusProcessor value)
            Telos walEnd("morph.adaptation")
            
            writeln("  Adapted size to ", sizeAdaptive newW, "x", sizeAdaptive newH)
        ,
            writeln("Maximum adaptation reached for ", self name)
        )
        
        self
    )
    
    world addMorph(adaptiveCircle)
    
    // Create self-modifying text that changes its own message
    metamorphicText := TextMorph clone
    metamorphicText setColor(0.8, 0.8, 0.2, 1.0)  // Yellow
    metamorphicText setPosition(150, 300)
    metamorphicText text := "I am learning..."
    metamorphicText name := "metamorphic_text"
    
    # Add metamorphic state
    metamorphicText knowledgeLevel := 0
    metamorphicText vocabulary := list("learning", "growing", "evolving", "becoming", "transcending")
    
    # Add self-modification method
    metamorphicText selfModify := method(
        knowledgeTracker := Object clone
        knowledgeTracker current := self knowledgeLevel
        knowledgeTracker current = knowledgeTracker current + 1
        self knowledgeLevel := knowledgeTracker current
        
        writeln("Self-modification step ", self knowledgeLevel, " for ", self name)
        
        # Select new vocabulary based on knowledge level
        vocabularySelector := Object clone
        vocabularySelector index := (self knowledgeLevel - 1) % (self vocabulary size)
        vocabularySelector word := self vocabulary at(vocabularySelector index)
        
        messageBuilder := Object clone
        messageBuilder newText := "I am " .. vocabularySelector word .. "... (step " .. self knowledgeLevel .. ")"
        
        self text := messageBuilder newText
        
        # Color evolution based on knowledge
        colorEvolution := Object clone
        colorEvolution progress := (self knowledgeLevel % 10) / 10.0
        colorEvolution newR := 0.8 - (0.4 * colorEvolution progress)
        colorEvolution newG := 0.8 + (0.2 * colorEvolution progress) 
        
        self setColor(colorEvolution newR, colorEvolution newG, 0.2, 1.0)
        
        # WAL logging for self-modification
        Telos walBegin("morph.selfmodify")
        Telos walAppend("MODIFY " .. self name .. " knowledge:" .. self knowledgeLevel)
        Telos walAppend("TEXT " .. messageBuilder newText)
        Telos walEnd("morph.selfmodify")
        
        writeln("  Text modified to: ", messageBuilder newText)
        self
    )
    
    world addMorph(metamorphicText)
    
    writeln("Initial autopoietic morphs created")
    Telos drawWorld
    
    // === EVOLUTIONARY SIMULATION ===
    writeln("Starting evolutionary simulation...")
    
    evolutionCycles := 5
    currentCycle := 0
    
    while(currentCycle < evolutionCycles,
        currentCycle = currentCycle + 1
        
        writeln("=== Evolution Cycle ", currentCycle, " ===")
        
        # Evolve the rectangle
        evolvingRect evolve
        
        # Adapt the circle (simulate environmental stimulus)
        stimulusList := list("heat", "pressure", "light", "sound", "chemical")
        stimulusIndex := (currentCycle - 1) % (stimulusList size)
        stimulus := stimulusList at(stimulusIndex)
        adaptiveCircle adapt(stimulus)
        
        # Self-modify the text
        metamorphicText selfModify
        
        # Visual update
        writeln("Rendering evolutionary state ", currentCycle)
        Telos drawWorld
        
        writeln("Cycle ", currentCycle, " complete")
    )
    
    // === FINAL STATE ANALYSIS ===
    writeln("=== Final Evolutionary State ===")
    writeln("Evolving Rectangle:")
    writeln("  Generation: ", evolvingRect generation)
    writeln("  Final color: ", evolvingRect color)
    
    writeln("Adaptive Circle:")  
    writeln("  Adaptation level: ", adaptiveCircle adaptationLevel)
    writeln("  Final size: ", adaptiveCircle size)
    
    writeln("Metamorphic Text:")
    writeln("  Knowledge level: ", metamorphicText knowledgeLevel)
    writeln("  Final message: ", metamorphicText text)
    
    # Save evolutionary snapshot
    Telos saveSnapshot("logs/autopoietic_evolution_demo.json")
    
    writeln("Demo complete: Advanced autopoietic evolution demonstrated")
    writeln("Living objects successfully evolved, adapted, and self-modified")
    
) catch(
    writeln("Demo complete: Exception caught during autopoietic evolution")
)

writeln("Autopoietic evolution demo finished")