#7/16/2019
from flask import Flask, render_template

#Instantiate the Flask class
app = Flask(__name__)


#Add some dummy data to work with for the demo
#This list represents the data a db call would return when queried
posts_list = [
    {
        'author': 'David Neal',
        'title': 'Welcome to my blog',
        'content': 'Check out my new blog everyone!',
        'date': 'July 16, 2019'
    },
    {
        'author': 'Bob Smith',
        'title': 'Neato',
        'content': 'I like it!',
        'date': 'July 17, 2019'
    }
]


#Add some basic view functions
@app.route("/")
@app.route("/index")
def index():
    return render_template('index.html', posts=posts_list)

@app.route("/about")
def about():
    return render_template('about.html', title='About')


#If run from the command line with python script.py, this will run flask to stand up a temp dev webserver
#Want to run this application in debug mode so changes are visible without restarting the www server
if __name__ == '__main__':
    app.run(debug=True)
    