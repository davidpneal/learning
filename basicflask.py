#6/29/2019
from flask import Flask

#Instantiate the Flask class
app = Flask(__name__)


#Add some basic view functions
@app.route("/")
@app.route("/index")
def index():
    return "<h1>Hello World</h1>"

@app.route("/about")
def about():
    return "<h1>About Page</h1>"


#If run from the command line with python script.py, this will run flask to stand up a temp dev webserver
#Want to run this application in debug mode so changes are visible without restarting the www server
if __name__ == '__main__':
    app.run(debug=True)