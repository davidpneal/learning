
#!/usr/bin/python3

#Implements the game of life using classes
#https://mathworld.wolfram.com/GameofLife.html


#Use Numpy ?



#TODO: Check this syntax - just guessing here
#self -- prob need to use this in the methods

class cell(object):
    
    #Class variables \ state
    state
    state_next
    posx
    posy    

    #Can I pass a '1' through the call with the built in init method, or will I need a separate method: ie: cell.init(1) - marks it live, 0 or no input = dead
    def __init__(self, row, col, state):
        posx = row
        posy = col
        #If state was passed, store it
        state = state
        ##ELSE -- if NO var is passed, set a default of 0
    
    # step - calculate and return the next generation based on current state
    def step():
        #decide: should the calc_neighbors code go in here?
        n = calc_neighbors() #Is this right way to re-pass data?
        
        #Logic to calculate the next generation state
        #Check this syntax
        if n <= 1:
            state_next = False #Dies from loneliness
        elif n = 2:
            state_next = state #2 neighbors = no change
        elif n = 3:
            state_next = True #Will always return true since dead cells become live with 3 neighbors
        elif n >= 4:
            state_next = False #Dies from overcrowding


    def calc_neighbors():
        neighbors = 0

        #Need some edge case handling - either looping code, or an invisible edge row

        #posx and posy should work
        for posx - 1 to posx + 1:
            for posy -1 to posy + 1: 
                if grid[x][y].state == True
                    neighbors = neighbors + 1
        
        return neighbors


    def save(): 
        state = state_next






steps = 0 #zero = infinite steps (later auto detect when all life dies), or an int value
gridsize = 30,30

#This makes grid global data -- is there a better way to handle this?
#Later on - have a way to init a specific pattern into the matrix (set specific cells to live)
grid = ?.generate(gridsize), add an instance of the cell class to each location
for each row in grid:
    for each col in grid:
        grid[pos].init()



#This seems sloppy - is there a way to not loop this grid so much?

iteration = 0
while steps = 0 or iteration != steps:
    #step all cells in the grid
    for each row in grid:
        for each col in grid:
            grid[pos].step()

    #save the next generation's state as the current state
    for each row in grid:
        for each col in grid:
            grid[pos].save()

    #draw the matrix to screen
    for each row in grid:
        for each col in grid:
            state = grid[pos].state #test this syntax
            #draw this T/F value to the screen - pygame?

    iteration = iteration + 1

    #Can have some code to detect no life - break the while loop and/or reset the board and start over



##OTHER NOTES
#The class needs to be able to read info from dataset / matrix
#Later - how about an 'infinite' grid -- no set size, it grows as needed (how fast will this be though)

