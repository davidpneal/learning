#!/usr/bin/python3

#Implements an elementary cellular automation
#https://mathworld.wolfram.com/ElementaryCellularAutomaton.html



#https://reference.wolfram.com/language/ref/CellularAutomaton.html
#Some great hints on how Wolfram's function takes\returns data
#Maybe create a wrapper, something like: e_ca.draw(rule, input, steps)


def step(rule, input):
    #Need a way to store the various rules

    #Select structure to implement each ruleset?
    #Loop through the input array and generate the next generation

    #Returns an array that will be 2 elements longer than the input array


def draw(input):
    #Draw the output 
    #Need to start drawing from the center top of the window
    #Need some logic to correctly center each subsequent line on the screen




rule = 30 #Later on, need a way to input this parameter
steps = 0 #Infinite steps
array = {1}

while True:
    draw{array} #Need this function to start drawing in the middle of the screen
    new_array = step(rule, array)
    array = new_array #Test -- does Py require this?  Might be able to directly set array to the output of e_ca()




