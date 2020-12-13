
#!/usr/bin/python3

#Implements the game of life using classes
#https://mathworld.wolfram.com/GameofLife.html


#The package numpy has some tools that can help with the multidimensional arrays
#Note that numpy uses matrix indexing (i,j / row,col) vs cartesian indexing (x,y) --> if the matrix is printed out, it will be "rotated"
import numpy as np



class gameoflife(object): #Check this syntax
 
    #Variables declared here are shared by all instances
    gridsize = 80,60

    def __init__(self, gridsize):
        #Variables declared here are unique to each instance
        
        #Create the matrix to store the state initialize to all false
        self.grid = np.full(shape=(self.gridsize[1],self.gridsize[0]), False, dtype=bool) #Test -- not clear the shape syntax works with full
        #If this fails, can also try: self.grid = np.zeros(shape=(300,300),dtype=bool)
        
        #can we set this to have a default value that is overridden if a param is passed?
        self.gridsize = gridsize #default to 100,100 if no variable passed

        #Modify this to set some live cells to start -- random, or have a way to init a specific pattern into the matrix (set specific cells to live)
        for row in range(gridsize[1]):
            for col in range(gridsize[0]):
                self.grid[row][col] #= set a value


    #Update the state to the next generation
    def step(self):
        #Create grid and set to 0: use ints (defaults to float)
        self.num_neighbors = np.zeros(shape=(gridsize[0],gridsize[1]),dtype=int)

        #Calculate the number of the neighbors for each cell in the matrix
        for row in range(gridsize[1]):
            for col in range(gridsize[0]):
                self.num_neighbors[row,col] = self.grid[row,col].calc_neighbors(row, col)
            
        #Use the num_neighbors matrix to calculate and set the next generation state for each cell
        for row in range(gridsize[1]):
            for col in range(gridsize[0]):
                if num_neighbors[row,col] <= 1:
                    self.grid[row,col] = False  #Dies from loneliness (0-1)
                elif num_neighbors[row,col] == 2:
                    pass                        #Two neighbors = no change
                elif num_neighbors[row,col] == 3:
                    self.grid[row,col] = True   #Will always return true since dead cells become live with 3 neighbors
                elif num_neighbors[row,col] >= 4:
                    self.grid[row,col] = False  #Dies from overpopulation (4+)

        #Can have some code to detect no life - break the while loop and/or reset the board and start over


    def state(self):
        return self.grid #Does this return a pointer or a copy?  Update this to the parameter 


    def calc_neighbors(self, row, col):
        self.neighbors = 0

        #Need some edge case handling - either looping code, or an invisible edge row

        for posy in range(row-1,row+2):
            for posx in range(col-1,col+2):
                if self.grid[posy,posx] == True:
                    self.neighbors = self.neighbors + 1





if __name__ == '__main__':

    gridsize = 100,100

    life = gameoflife(gridsize) #If no gridsize is passed, default to 100x100 or something
    
    steps = 0
    iteration = 0
    while steps == 0 or iteration != steps:
        life.step()
        draw(life.state()) #Use mathplotlib for the draw function?

        iteration = iteration + 1


