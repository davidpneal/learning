#!/usr/bin/python3

#Implements Conways Game of Life
#https://mathworld.wolfram.com/GameofLife.html



#Key points
#Uses an agent based model where the 'cell' manages all changes to local state.
#The cell class expects to be in a square grid (for the neighbor calculations)
#The gol class implements the game state and logic



class cell:

    import random

    def __init__(self, x, y, state = random.choice([True, False])):

        self._x = x
        self._y = y
        self._revision = 0
        self._state = bool(state)
        self._previous_state = None
 

    def __bool__(self):
        return self._state


    def state(self, revision):
        #This method should allow for updating the cells in a parallel manor
        if revision is None:
            return self._state
        elif revision == self._revision:
            return self._state
        elif revision == self._revision-1:
            return self._previous_state
        else:
            print("Cell state revision is more than 1 update off")
            exit()


    def update(self, grid, gridsize):
        
        #Calculate neighborhood value
        self._neighbors = 0
        for xpos in range(self._x-1,self._x+1):
            for ypos in range(self._y-1,self._y+1):
                
                col = (xpos + gridsize.x) % gridsize.x
                row = (ypos + gridsize.y) % gridsize.y

                if grid[col][row].state(self._revision) is True:
                    self._neighbors += 1
                    ## This will cause a cell to call itself with state() -- make sure this works as expected

        #Need to subtract out self._state
        if self._state is True:
            self._neighbors -= 1
        

        #Update state
        self._previous_state = self._state
        
        if self._neighbors <= 1:
            self._state = False     #Dies from loneliness (0-1)
        elif self._neighbors == 2:
            pass                    #Two neighbors = no change
        elif self._neighbors == 3:
            self._state = True      #Will always return true since dead cells become live with 3 neighbors
        elif self._neighbors >= 4:
            self._state = False     #Dies from overpopulation (4+)


        self._revision += 1





class gol:

    def __init__(self):
        from collections import namedtuple
        size = namedtuple('size','x, y')
        self._gridsize = size(100,100)
        
        self._grid = [[cell(x,y) for x in range(self._gridsize.x)] for y in range(self._gridsize.y)] 
        #self._revision = 0


    def update(self):
                
        for xpos in range(self._gridsize.x):
            for ypos in range(self._gridsize.y):
                self._grid[xpos][ypos].update(self._grid, self._gridsize) #can you pass 'self' in the function all like this? ######################

        #self._grid[[for x in range(self._gridsize.x)] for y in range(self._gridsize.y)].update(self._grid, self._revision) ##will this work? -or-
        #[[self._grid[posx][posy].update(self._grid, self._revision) for posx in range(self._gridsize.x)] for posy in range(self._gridsize.y)]

        #self._revision += 1 #not really needed



    def draw(self):
        #use a library to draw a representation of the grid
        #from matplotlib import pyplot, colors
        #colormap = colors.ListedColormap(["white","black"])

        print("draw update")
        #print(str(self._grid))

        #print(''.join(str([['\u2588' if self._grid[x][y] is True else ' ' for x in range(self._gridsize.x)] for y in range(self._gridsize.y)]))) #update to use grid


    def is_stable(self):
        #compares all Cell's state to previous_state -- if no values change return True; the game is finished 

        return False
        





if __name__ == '__main__':

    #Instantiate the game
    game = gol()

    while True:
        game.update()
        game.draw()

        if game.is_stable():
            break
        
        #might need a delay here

    #pause here to leave the last draw() state on the screen



