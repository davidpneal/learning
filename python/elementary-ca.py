#!/usr/bin/python3

#Implements an elementary cellular automaton class
#https://mathworld.wolfram.com/ElementaryCellularAutomaton.html


class ca:

    def __init__(self, rule, width = 15):

        #Should add code to validate rule is between 0 and 255
        self._rule = format(rule, '08b') #this creates a string

        #We always want an odd number 3 or greater, the first and last elements will be hidden
        if width < 1:
            self._width = 3
        elif width % 2 == 0:
            self._width = width + 1
        else:
            self._width = width + 2

        self._state = [0] * self._width  #Need to decide if want to use False / True instead of 0/1
        self._state[self._width//2] = 1



    #Can this be implemented as __iter__ or __next__ instead?
    def step(self):
        #logic to update to the next generation
        pass


    def state(self):
        return self._state[1:-1]




if __name__ == '__main__':
    
    #Instantiate the class to use rule 30
    ca30 = ca(30)

    print(ca30.state())
    
    #print(ca30._state)

    
    #for _ in range(10):
    #    ca30.step()
    #    print(ca30.state())

