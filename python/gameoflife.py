
#!/usr/bin/python3

#Implements an cellular automation
#https://mathworld.wolfram.com/CellularAutomaton.html


#Use Numpy as part of this?



#TODO: Check this syntax - just guessing here
#self -- prob need to use this in the methods

class cell(object):
    
    #Class variables \ state
    state
    state_next
    

    #Can I pass a '1' through the call with the built in init method, or will I need a separate method: ie: cell.init(1) - marks it live, 0 or no input = dead
    def __init__(self):
        
    
    # step - calculate and return the next generation based on current state -- this is the 'main' function for the class - calls calc neighbors, then does the logic to live\die
    def step():
        n = calc_neighbors()
        
        #Logic to calculate the next generation state


    def calc_neighbors():
        #Need to be able to access the array / grid storing these class objects for this step

        #Basic logic to check the array +- one element along with -+ one row in the grid
        #Edges of the grid - either have an invisible edge row, or create looping logic

    def consolodate():
        #Set state = state_next





gridsize = 30,30
#Create the matrix (array of arrays) to store the cell instances
#Initialize the matrix (maybe while creating it) with some starting data

while True: #Or define some type of stop condition
    #For each element in array, item.step()
    #And then item.consolodate -- the idea here is to keep the same array of classes without needing to destroy\recreate them each iteration
    #Draw the matrix to screen



##OTHER NOTES
#The class needs to be able to read info from dataset / matrix
#Later - how about an 'infinite' grid -- no set size, it grows as needed (how fast will this be though)

