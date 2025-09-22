#!/usr/bin/env io

// Simple test to see what methods Telos has
("Available Telos methods:" println)
Telos slotNames foreach(name, name println)

// Try a method that should exist
("Testing getPythonVersion..." println)
try(
    version := Telos getPythonVersion
    ("Python version: " .. version println)
) catch(Exception,
    ("Exception: " .. Exception description println)
)