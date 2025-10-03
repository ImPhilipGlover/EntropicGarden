#!/usr/bin/env iovm

TestObject := Object clone do(
    testMethod := method(
        "Hello from Io" println
        return "success"
    )
)

if(System args size > 0 and System args at(0) containsSeq("fresh_test"), 
    TestObject testMethod
)
