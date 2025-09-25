/*
   TelosMorphic-Shapes.io - Basic Shape Morphs
   RectangleMorph, CircleMorph, TextMorph, and Canvas implementations
   Part of the modular TelosMorphic system
*/

// === TELOS MORPHIC SHAPES MODULE ===

TelosMorphicShapes := Object clone
TelosMorphicShapes version := "1.0.0 (modular-prototypal)"
TelosMorphicShapes loadTime := Date clone now

// === RECTANGLE MORPH ===
// Basic rectangular morph with customizable appearance

RectangleMorph := Morph clone do(
    type := "rectangle"

    // Enhanced drawing with proper Canvas delegation
    drawSelfOn := method(canvas,
        // Use Canvas abstraction for drawing
        canvas fillRectangle(self bounds, self color)
        self
    )

    // Factory method for creating rectangles
    withBounds := method(x, y, width, height,
        newMorph := self clone
        newMorph bounds setPosition(x, y)
        newMorph bounds setSize(width, height)
        newMorph
    )

    // Factory method with color
    withBoundsAndColor := method(x, y, width, height, r, g, b, a,
        newMorph := self withBounds(x, y, width, height)
        newMorph color setColor(r, g, b, a)
        newMorph
    )

    // Interactive behavior - change color on click
    leftMouseDown := method(event,
        # Call parent method first
        resend

        # Additional behavior: toggle color
        if(self color r > 0.5,
            self color setColor(0.2, 0.8, 0.2, 1.0)  # Green
        ,
            self color setColor(0.8, 0.2, 0.2, 1.0)  # Red
        )

        # Log interaction
        if(Telos hasSlot("walAppend"),
            walEntry := "RECTANGLE_CLICK {\"id\":\"" .. self id .. "\",\"x\":" .. event x .. ",\"y\":" .. event y .. "}"
            Telos walAppend(walEntry)
        )

        self
    )

    description := method(
        "RectangleMorph(" .. self bounds x .. "," .. self bounds y .. "," .. self bounds width .. "," .. self bounds height .. ")"
    )
)

// === CIRCLE MORPH ===
// Circular morph with radius-based sizing

CircleMorph := Morph clone do(
    type := "circle"
    radius := 25

    // Override bounds to be radius-based
    bounds := Object clone do(
        x := 0; y := 0; width := 50; height := 50
        setPosition := method(newX, newY, x = newX; y = newY; self)
        setSize := method(newW, newH,
            width = newW; height = newH
            # Update radius based on size
            owner radius = (newW min(newH)) / 2
            self
        )
        containsPoint := method(px, py,
            centerX := self x + (self width / 2)
            centerY := self y + (self height / 2)
            distance := ((px - centerX) squared + (py - centerY) squared) sqrt
            distance <= owner radius
        )
    )

    // Enhanced drawing with proper Canvas delegation
    drawSelfOn := method(canvas,
        # Calculate center from bounds
        centerX := self bounds x + (self bounds width / 2)
        centerY := self bounds y + (self bounds height / 2)

        # Use Canvas abstraction for drawing
        canvas fillCircle(self bounds, self radius, self color)
        self
    )

    // Factory method for creating circles
    withCenterAndRadius := method(centerX, centerY, radius,
        newMorph := self clone
        newMorph radius = radius
        newMorph bounds setPosition(centerX - radius, centerY - radius)
        newMorph bounds setSize(radius * 2, radius * 2)
        newMorph
    )

    // Factory method with color
    withCenterRadiusAndColor := method(centerX, centerY, radius, r, g, b, a,
        newMorph := self withCenterAndRadius(centerX, centerY, radius)
        newMorph color setColor(r, g, b, a)
        newMorph
    )

    // Interactive behavior - scale on click
    leftMouseDown := method(event,
        # Call parent method first
        resend

        # Additional behavior: scale up temporarily
        originalRadius := self radius
        self radius = originalRadius * 1.2
        self bounds setSize(self radius * 2, self radius * 2)

        # Log interaction
        if(Telos hasSlot("walAppend"),
            walEntry := "CIRCLE_CLICK {\"id\":\"" .. self id .. "\",\"radius\":" .. self radius .. "}"
            Telos walAppend(walEntry)
        )

        self
    )

    leftMouseUp := method(event,
        # Call parent method first
        resend

        # Additional behavior: scale back down
        self radius = self radius / 1.2
        self bounds setSize(self radius * 2, self radius * 2)

        self
    )

    description := method(
        "CircleMorph(" .. self bounds x .. "," .. self bounds y .. ",r=" .. self radius .. ")"
    )
)

// === TEXT MORPH ===
// Text display morph with font and content

TextMorph := Morph clone do(
    type := "text"
    text := "Text"
    fontSize := 16
    fontName := "default"

    // Enhanced drawing with proper Canvas delegation
    drawSelfOn := method(canvas,
        # Use Canvas abstraction for text drawing
        canvas drawText(self text, self bounds, self color)
        self
    )

    // Factory method for creating text morphs
    withText := method(textString,
        newMorph := self clone
        newMorph text = textString
        newMorph
    )

    // Factory method with position
    withTextAt := method(textString, x, y,
        newMorph := self withText(textString)
        newMorph bounds setPosition(x, y)
        newMorph
    )

    // Factory method with full styling
    withTextAtAndColor := method(textString, x, y, r, g, b, a,
        newMorph := self withTextAt(textString, x, y)
        newMorph color setColor(r, g, b, a)
        newMorph
    )

    // Interactive behavior - change text on click
    leftMouseDown := method(event,
        # Call parent method first
        resend

        # Additional behavior: append click indicator
        self text = self text .. " [clicked]"

        # Log interaction
        if(Telos hasSlot("walAppend"),
            walEntry := "TEXT_CLICK {\"id\":\"" .. self id .. "\",\"text\":\"" .. self text .. "\"}"
            Telos walAppend(walEntry)
        )

        self
    )

    description := method(
        "TextMorph(\"" .. self text .. "\"," .. self bounds x .. "," .. self bounds y .. ")"
    )
)

// === ENHANCED CANVAS IMPLEMENTATION ===
// Io-level fallback drawing when C-level SDL2 is unavailable

Canvas do(
    // Enhanced rectangle drawing with fallback
    fillRectangle := method(bounds, color,
        # Extract bounds and color data
        x := bounds x
        y := bounds y
        width := bounds width
        height := bounds height
        r := color r
        g := color g
        b := color b
        a := color a

        # Try C-level drawing first
        if(Telos hasSlot("Telos_rawDrawRect"),
            Telos Telos_rawDrawRect(x, y, width, height, r, g, b, a)
        ,
            # Fallback: ASCII art representation
            writeln("Canvas: Rectangle at (" .. x .. "," .. y .. ") size " .. width .. "x" .. height .. " color(" .. r .. "," .. g .. "," .. b .. ")")
            # Draw simple ASCII rectangle
            for(i, 0, height - 1,
                line := ""
                for(j, 0, width - 1,
                    if(i == 0 or i == height - 1 or j == 0 or j == width - 1,
                        line = line .. "#"
                    ,
                        line = line .. " "
                    )
                )
                writeln(line)
            )
        )
        self
    )

    // Enhanced circle drawing with fallback
    fillCircle := method(bounds, radius, color,
        # Calculate center from bounds
        centerX := bounds x + (bounds width / 2)
        centerY := bounds y + (bounds height / 2)
        r := color r
        g := color g
        b := color b
        a := color a

        # Try C-level drawing first
        if(Telos hasSlot("Telos_rawDrawCircle"),
            Telos Telos_rawDrawCircle(centerX, centerY, radius, r, g, b, a)
        ,
            # Fallback: ASCII art circle
            writeln("Canvas: Circle at (" .. centerX .. "," .. centerY .. ") radius " .. radius .. " color(" .. r .. "," .. g .. "," .. b .. ")")
            # Draw simple ASCII circle approximation
            size := radius * 2
            for(i, 0, size - 1,
                line := ""
                for(j, 0, size - 1,
                    dx := j - radius
                    dy := i - radius
                    distance := (dx squared + dy squared) sqrt
                    if(distance <= radius,
                        line = line .. "O"
                    ,
                        line = line .. " "
                    )
                )
                if(line strip != "", writeln(line))
            )
        )
        self
    )

    // Enhanced text drawing with fallback
    drawText := method(text, bounds, color,
        x := bounds x
        y := bounds y
        r := color r
        g := color g
        b := color b
        a := color a

        # Try C-level drawing first
        if(Telos hasSlot("Telos_rawDrawText"),
            Telos Telos_rawDrawText(text, x, y, r, g, b, a)
        ,
            # Fallback: simple text output
            writeln("Canvas: Text '" .. text .. "' at (" .. x .. "," .. y .. ") color(" .. r .. "," .. g .. "," .. b .. ")")
        )
        self
    )
)

// Register shape morphs in global namespace
Lobby RectangleMorph := RectangleMorph
Lobby CircleMorph := CircleMorph
Lobby TextMorph := TextMorph

// Module load method
TelosMorphicShapes load := method(
    writeln("TelosMorphic-Shapes: Basic shape morphs loaded")
    writeln("TelosMorphic-Shapes: RectangleMorph, CircleMorph, TextMorph registered")
    writeln("TelosMorphic-Shapes: Enhanced Canvas drawing with fallbacks")
    self
)

writeln("TelosMorphic-Shapes: Basic shape morphs module loaded")

// Register TelosMorphicShapes in global namespace
Lobby TelosMorphicShapes := TelosMorphicShapes