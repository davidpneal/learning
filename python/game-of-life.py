#!/usr/bin/python3

#Implements Conways Game of Life
#https://mathworld.wolfram.com/GameofLife.html



#Key points
#Uses an agent based model where the 'cell' manages all changes to local state
#The gol class implements the game state and logic




class cell:

    import random

    def __init__(self, x, y, state = random.choice([True, False])):

        self._x = x
        self._y = y
        self._state = state
        self._previous_state = state
        #might want to add type checks - x,y int; state bool
 

    def state(): #implement this as __bool__ instead?
        return self._state


    def previous_state():
        return self._previous_state


    def update():
        self._previous_state = self._state
        #calculate neighborhood value
        #update state as needed




class gol:

    def __init__(self):
        #define the gridsize as a named tuple
        #create the grid of Cells - list of lists
        

    def update():
        #run .update() on all cells
        #use modulus math so the edges wrap


    def draw():
        #use a library to draw a representation of the grid


    def is_stable():
        #compares all Cell's state to previous_state -- if no values change return True; the game is finished 






if __name__ == '__main__':

    #Instantiate the game
    game = gol()

    while True:
        game.update()
        game.draw()

        if game.isstable():
            break
        
        #might need a delay here

    #pause here to leave the last draw() state on the screen



