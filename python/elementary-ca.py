#!/usr/bin/python3

#Implements an elementary cellular automaton class
#https://mathworld.wolfram.com/ElementaryCellularAutomaton.html


#Key points
#Subsequent generations are based on the parent ('neighborhood') cells
#An 8 bit 'rule' string (represented as an int) can be used to determine the value of the new generation
#Due to the way the binary representation of the rule is structured, can use binary math to lookup the new value
#Some interesting rules: 30, 54, 90, 122, 126, 150, 182


class ca:

    def __init__(self, rule, width = 63):

        if rule < 0 or rule > 255:
            raise ValueError("Rule value must be a value from 0 to 255")
        else:
            self._rule = format(rule, '08b') #This creates an 8 character string of 1 and 0's

        #We always want an odd number, 3 or greater since the first and last elements will be hidden 0 value placeholders
        if width < 1:
            self._width = 3
        elif width % 2 == 0:
            self._width = width + 1
        else:
            self._width = width + 2

        self._state = [False] * self._width
        self._state[self._width//2] = True


    #Can this be implemented as __iter__ or __next__ instead?
    def step(self):
        parent_state = self._state.copy()

        for pos in range(1, self._width-1):

            #The new value is based on the 3 neighboring parent cells; these cells can be treated as a 3 bit number (0-7)
            neighbors = (parent_state[pos-1], parent_state[pos], parent_state[pos+1])
            bits = neighbors[0] * 4 + neighbors[1] * 2 + neighbors[2] * 1

            #The bit value can be used as an index to lookup the new generation's value from the rule
            if self._rule[7-bits] == "1":
                self._state[pos] = True
            else:
                self._state[pos] = False


    def state(self):
        return self._state[1:-1]


    def draw(self):
        return ''.join(['\u2588' if x is True else ' ' for x in self._state[1:-1]])



if __name__ == '__main__':
    
    #Instantiate the class to use rule 30
    cell = ca(30)

    print(cell.draw())
    for _ in range(30):
        cell.step()
        print(cell.draw())

