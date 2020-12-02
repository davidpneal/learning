
#!/usr/bin/python3

#Implements the game of life using classes
#https://mathworld.wolfram.com/GameofLife.html


#Use Numpy ?


class gameoflife(object):
 
    def __init__(self, gridsize):
        #Create the matrix and populate it with cells
        self.grid[] = some_matrix_class(gridsize)

        for each row in grid:
            for each col in grid:
                self.grid[row,col] = True / False #DEFAULT VALUES?

                #Later on - have a way to init a specific pattern into the matrix (set specific cells to live)


    def step():
        #Calculate the number of the neighbors for each cell in the matrix
        self.num_neighbors[] = some_matrix_class(len(grid))

        for each row in grid:
            for each col in grid:
                self.num_neighbors[row,col] = self.grid[row,col].calc_neighbors()
            
        #Use the num_neighbors matrix to calc next state for each cell, can directly update the state
        for each row in grid:
            for each col in grid:
                #Logic to calculate the next generation state
                #Check this syntax
                if num_neighbors[row,col] <= 1:
                    self.grid[row,col] = False  #Dies from loneliness
                elif num_neighbors[row,col] = 2:
                    pass                        #Two neighbors = no change
                elif num_neighbors[row,col] = 3:
                    self.grid[row,col] = True   #Will always return true since dead cells become live with 3 neighbors
                elif num_neighbors[row,col] >= 4:
                    seld.grid[row,col] = False  #Dies from overcrowding


        #Can have some code to detect no life - break the while loop and/or reset the board and start over


    def state():
        return self.grid


    def calc_neighbors():
        self.neighbors = 0

        #Need some edge case handling - either looping code, or an invisible edge row

        #posx and posy should work
        for posx - 1 to posx + 1:
            for posy -1 to posy + 1: 
                if grid[x][y].state == True
                    neighbors = neighbors + 1
        
        return self.neighbors








if __name__ == '__main__':

    gridsize = 100,100

    life = gameoflife(gridsize)
    
    steps = 0
    iteration = 0
    while steps = 0 or iteration != steps:
        life.step()
        draw(life.state())

        iteration = iteration + 1






#OTHER NOTES
#Later - how about an 'infinite' grid -- no set size, it grows as needed (how fast will this be though)

