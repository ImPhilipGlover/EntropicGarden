/*
   TelosMorphic-UI.io - Interactive UI Widgets
   ButtonMorph, TextInputMorph, and other interactive components
   Part of the modular TelosMorphic system
*/

// === TELOS MORPHIC UI MODULE ===

TelosMorphicUi := Object clone
TelosMorphicUi version := "1.0.0 (modular-prototypal)"
TelosMorphicUi loadTime := Date clone now

// === BUTTON MORPH ===
// Interactive button with click actions and visual feedback

ButtonMorph := RectangleMorph clone do(
    type := "button"
    label := "Button"
    action := nil  # Block to execute when clicked
    isPressed := false

    // Enhanced appearance for button-like behavior
    color := Color clone setColor(0.7, 0.7, 0.9, 1.0)  # Light blue-gray
    pressedColor := Color clone setColor(0.5, 0.5, 0.7, 1.0)  # Darker when pressed

    // Draw button with label
    drawSelfOn := method(canvas,
        # Draw button background
        currentColor := if(self isPressed, self pressedColor, self color)
        canvas fillRectangle(self bounds, currentColor)

        # Draw button border
        borderColor := Color clone setColor(0.3, 0.3, 0.3, 1.0)
        canvas fillRectangle(Object clone do(x := self bounds x; y := self bounds y; width := self bounds width; height := 2), borderColor)
        canvas fillRectangle(Object clone do(x := self bounds x; y := self bounds y + self bounds height - 2; width := self bounds width; height := 2), borderColor)
        canvas fillRectangle(Object clone do(x := self bounds x; y := self bounds y; width := 2; height := self bounds height), borderColor)
        canvas fillRectangle(Object clone do(x := self bounds x + self bounds width - 2; y := self bounds y; width := 2; height := self bounds height), borderColor)

        # Draw label centered
        textX := self bounds x + (self bounds width / 2) - (self label size * 4)  # Rough centering
        textY := self bounds y + (self bounds height / 2) - 8  # Rough vertical centering
        textBounds := Object clone do(x := textX; y := textY)
        textColor := Color clone setColor(0.1, 0.1, 0.1, 1.0)  # Dark text
        canvas drawText(self label, textBounds, textColor)

        self
    )

    // Factory method for creating buttons
    withLabel := method(buttonLabel,
        newMorph := self clone
        newMorph label = buttonLabel
        newMorph
    )

    // Factory method with action
    withLabelAndAction := method(buttonLabel, buttonAction,
        newMorph := self withLabel(buttonLabel)
        newMorph action = buttonAction
        newMorph
    )

    // Factory method with position and size
    withBoundsAndLabel := method(x, y, width, height, buttonLabel,
        newMorph := self withLabel(buttonLabel)
        newMorph bounds setPosition(x, y)
        newMorph bounds setSize(width, height)
        newMorph
    )

    // Enhanced mouse interaction
    leftMouseDown := method(event,
        # Call parent method first
        resend

        # Button-specific behavior: show pressed state
        self isPressed = true

        # Log interaction
        if(Telos hasSlot("walAppend"),
            walEntry := "BUTTON_DOWN {\"id\":\"" .. self id .. "\",\"label\":\"" .. self label .. "\"}"
            Telos walAppend(walEntry)
        )

        self
    )

    leftMouseUp := method(event,
        # Call parent method first
        resend

        # Button-specific behavior: execute action and release
        self isPressed = false

        # Execute action if defined
        if(self action != nil,
            try(
                self action call
                writeln("Button '" .. self label .. "' action executed")
            ) catch(Exception e,
                writeln("Button action error: " .. e error)
            )
        )

        # Log interaction
        if(Telos hasSlot("walAppend"),
            walEntry := "BUTTON_UP {\"id\":\"" .. self id .. "\",\"label\":\"" .. self label .. "\",\"action\":\"" .. (if(self action, "executed", "none")) .. "\"}"
            Telos walAppend(walEntry)
        )

        self
    )

    description := method(
        "ButtonMorph(\"" .. self label .. "\"," .. self bounds x .. "," .. self bounds y .. "," .. self bounds width .. "," .. self bounds height .. ")"
    )
)

// === TEXT INPUT MORPH ===
// Text input field with cursor and editing capabilities

TextInputMorph := RectangleMorph clone do(
    type := "textInput"
    text := ""
    cursorPosition := 0
    hasFocus := false
    placeholder := "Enter text..."

    // Appearance
    backgroundColor := Color clone setColor(1.0, 1.0, 1.0, 1.0)  # White background
    borderColor := Color clone setColor(0.5, 0.5, 0.5, 1.0)  # Gray border
    textColor := Color clone setColor(0.0, 0.0, 0.0, 1.0)  # Black text
    cursorColor := Color clone setColor(0.0, 0.0, 0.0, 1.0)  # Black cursor

    // Draw text input field
    drawSelfOn := method(canvas,
        # Draw background
        canvas fillRectangle(self bounds, self backgroundColor)

        # Draw border
        borderWidth := 2
        canvas fillRectangle(Object clone do(x := self bounds x; y := self bounds y; width := self bounds width; height := borderWidth), self borderColor)
        canvas fillRectangle(Object clone do(x := self bounds x; y := self bounds y + self bounds height - borderWidth; width := self bounds width; height := borderWidth), self borderColor)
        canvas fillRectangle(Object clone do(x := self bounds x; y := self bounds y; width := borderWidth; height := self bounds height), self borderColor)
        canvas fillRectangle(Object clone do(x := self bounds x + self bounds width - borderWidth; y := self bounds y; width := borderWidth; height := self bounds height), self borderColor)

        # Draw text content
        displayText := if(self text size > 0, self text, self placeholder)
        textBounds := Object clone do(x := self bounds x + 5; y := self bounds y + (self bounds height / 2) - 8)
        canvas drawText(displayText, textBounds, self textColor)

        # Draw cursor if focused
        if(self hasFocus,
            cursorX := self bounds x + 5 + (self cursorPosition * 8)  # Rough character width
            cursorY := self bounds y + 5
            cursorHeight := self bounds height - 10
            canvas fillRectangle(Object clone do(x := cursorX; y := cursorY; width := 2; height := cursorHeight), self cursorColor)
        )

        self
    )

    // Factory method for creating text inputs
    withPlaceholder := method(placeholderText,
        newMorph := self clone
        newMorph placeholder = placeholderText
        newMorph
    )

    // Factory method with bounds
    withBoundsAndPlaceholder := method(x, y, width, height, placeholderText,
        newMorph := self withPlaceholder(placeholderText)
        newMorph bounds setPosition(x, y)
        newMorph bounds setSize(width, height)
        newMorph
    )

    // Enhanced mouse interaction - gain focus on click
    leftMouseDown := method(event,
        # Call parent method first
        resend

        # Text input behavior: gain focus
        self hasFocus = true
        Telos focusedMorph = self

        # Calculate cursor position based on click location
        relativeX := event x - self bounds x - 5
        self cursorPosition = (relativeX / 8) floor max(0) min(self text size)

        # Log interaction
        if(Telos hasSlot("walAppend"),
            walEntry := "TEXTINPUT_FOCUS {\"id\":\"" .. self id .. "\",\"cursor\":" .. self cursorPosition .. "}"
            Telos walAppend(walEntry)
        )

        self
    )

    // Keyboard input handling
    keyDown := method(keyName,
        if(self hasFocus,
            if(keyName == "backspace",
                if(self cursorPosition > 0,
                    self text = self text removeSlice(self cursorPosition - 1, self cursorPosition)
                    self cursorPosition = self cursorPosition - 1
                )
            )
            if(keyName == "left",
                self cursorPosition = (self cursorPosition - 1) max(0)
            )
            if(keyName == "right",
                self cursorPosition = (self cursorPosition + 1) min(self text size)
            )
            if(keyName == "return" or keyName == "enter",
                self hasFocus = false
                Telos focusedMorph = nil
            )

            # Log key input
            if(Telos hasSlot("walAppend"),
                walEntry := "TEXTINPUT_KEY {\"id\":\"" .. self id .. "\",\"key\":\"" .. keyName .. "\",\"text\":\"" .. self text .. "\"}"
                Telos walAppend(walEntry)
            )
        )

        self
    )

    // Text input handling
    textInput := method(inputText,
        if(self hasFocus,
            # Insert text at cursor position
            beforeCursor := self text slice(0, self cursorPosition)
            afterCursor := self text slice(self cursorPosition)
            self text = beforeCursor .. inputText .. afterCursor
            self cursorPosition = self cursorPosition + inputText size

            # Log text input
            if(Telos hasSlot("walAppend"),
                walEntry := "TEXTINPUT_TEXT {\"id\":\"" .. self id .. "\",\"text\":\"" .. self text .. "\"}"
                Telos walAppend(walEntry)
            )
        )

        self
    )

    description := method(
        "TextInputMorph(\"" .. self text .. "\"," .. self bounds x .. "," .. self bounds y .. "," .. self bounds width .. "," .. self bounds height .. ")"
    )
)

// === SCROLLABLE TEXT AREA ===
// Multi-line text display with scrolling

ScrollableTextMorph := RectangleMorph clone do(
    type := "scrollableText"
    lines := List clone
    scrollOffset := 0
    maxVisibleLines := 10

    // Add text line
    addLine := method(text,
        self lines append(text)
        # Auto-scroll to bottom
        if(self lines size > self maxVisibleLines,
            self scrollOffset = self lines size - self maxVisibleLines
        )
        self
    )

    // Clear all text
    clear := method(
        self lines empty
        self scrollOffset = 0
        self
    )

    // Scroll up/down
    scrollUp := method(
        self scrollOffset = (self scrollOffset - 1) max(0)
        self
    )

    scrollDown := method(
        maxOffset := (self lines size - self maxVisibleLines) max(0)
        self scrollOffset = (self scrollOffset + 1) min(maxOffset)
        self
    )

    // Draw scrollable text area
    drawSelfOn := method(canvas,
        # Draw background
        canvas fillRectangle(self bounds, self color)

        # Draw visible lines
        lineHeight := 16
        startY := self bounds y + 5

        visibleLines := self lines slice(self scrollOffset, self scrollOffset + self maxVisibleLines)
        visibleLines foreach(i, line,
            y := startY + (i * lineHeight)
            if(y < self bounds y + self bounds height - 5,
                textBounds := Object clone do(x := self bounds x + 5; y := y)
                textColor := Color clone setColor(0.0, 0.0, 0.0, 1.0)
                canvas drawText(line, textBounds, textColor)
            )
        )

        self
    )

    // Factory method
    withBounds := method(x, y, width, height,
        newMorph := self clone
        newMorph bounds setPosition(x, y)
        newMorph bounds setSize(width, height)
        newMorph maxVisibleLines = (height / 16) floor
        newMorph
    )

    description := method(
        "ScrollableTextMorph(" .. self lines size .. " lines," .. self bounds x .. "," .. self bounds y .. "," .. self bounds width .. "," .. self bounds height .. ")"
    )
)

// Register UI widgets in global namespace
Lobby ButtonMorph := ButtonMorph
Lobby TextInputMorph := TextInputMorph
Lobby ScrollableTextMorph := ScrollableTextMorph

// Module load method
TelosMorphicUi load := method(
    writeln("TelosMorphic-UI: Interactive UI widgets loaded")
    writeln("TelosMorphic-UI: ButtonMorph, TextInputMorph, ScrollableTextMorph registered")
    self
)

writeln("TelosMorphic-UI: Interactive UI widgets module loaded")

// Register TelosMorphicUi in global namespace
Lobby TelosMorphicUi := TelosMorphicUi