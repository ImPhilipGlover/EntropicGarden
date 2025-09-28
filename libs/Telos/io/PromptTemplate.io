//
// PromptTemplate.io - Versioned Prompt Template Management
//
// This file implements the PromptTemplate prototype that manages versioned
// prompt templates with persona priming, context injection, and autopoiesis.
//

PromptTemplate := Object clone do(
    // Template storage (would be persisted in L3 cache)
    templates := Map clone
    templateVersions := Map clone

    // Initialize with default templates
    init := method(
        templates = Map clone
        templateVersions = Map clone

        // Default doesNotUnderstand template
        defaultTemplate := Map clone
        defaultTemplate atPut("name", "doesNotUnderstand_v1")
        defaultTemplate atPut("version", 1)
        defaultTemplate atPut("template", "I received a message I don't understand: {message}. Context: {context}. Please help me understand what this means and how to respond.")
        defaultTemplate atPut("variables", list("message", "context"))
        defaultTemplate atPut("created", Date now)
        defaultTemplate atPut("performance", Map clone)

        templates atPut("doesNotUnderstand", defaultTemplate)
        templateVersions atPut("doesNotUnderstand", list(defaultTemplate))
        markChanged

        self
    )

    // Get a template for rendering
    getTemplate := method(templateName, query, context,
        template := templates at(templateName)
        if(template isNil,
            return "I don't understand: {message}"  // Fallback
        )

        // Render template with variables
        rendered := template at("template")

        // Simple variable substitution
        if(query hasSlot("message"),
            rendered = rendered replaceSeq("{message}", query at("message"))
        )
        if(context,
            rendered = rendered replaceSeq("{context}", context asJson)
        )

        rendered
    )

    // Evolve a template based on cycle analysis
    evolveTemplate := method(analysis,
        templateName := "doesNotUnderstand"  // For now, only evolve this one

        currentTemplate := templates at(templateName)
        if(currentTemplate isNil, return false)

        // Create new version
        newVersion := currentTemplate clone
        newVersion atPut("version", currentTemplate at("version") + 1)
        newVersion atPut("name", templateName .. "_v" .. newVersion at("version"))
        newVersion atPut("created", Date now)
        newVersion atPut("parentVersion", currentTemplate at("version"))

        // Modify template based on analysis
        reason := analysis at("evolutionReason")
        if(reason == "recurring_unknown_message",
            // Make template more specific for recurring messages
            newTemplateText := currentTemplate at("template") .. " This appears to be a recurring pattern. Please provide a more detailed explanation."
            newVersion atPut("template", newTemplateText)
        )

        if(reason == "high_iteration_complexity",
            // Simplify template for complex cases
            newTemplateText := "Complex query requiring deep reasoning: {message}. Context: {context}. Please break this down step by step."
            newVersion atPut("template", newTemplateText)
        )

        // Store new version
        templates atPut(templateName, newVersion)
        versions := templateVersions at(templateName, list())
        versions append(newVersion)
        templateVersions atPut(templateName, versions)
        markChanged

        true
    )

    // Get template statistics
    getStatistics := method(
        stats := Map clone
        stats atPut("totalTemplates", templates size)
        stats atPut("totalVersions", templateVersions values map(v, v size) sum)

        // Calculate evolution rate
        evolvedTemplates := templateVersions values select(v, v size > 1)
        stats atPut("evolvedTemplates", evolvedTemplates size)

        stats
    )
)

// Export to global namespace
if(Lobby hasSlot("Telos") not, Lobby Telos := Object clone)
Telos PromptTemplate := PromptTemplate clone init