#7/22/2019
from flask import Flask, render_template, url_for, flash, redirect
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime

#Import the forms we created in the forms.py file
from forms import RegistrationForm, LoginForm

#Instantiate the Flask class
app = Flask(__name__)

#Need a secret key to validate our forms (need a better way to handle this secret later on)
app.config['SECRET_KEY'] = '1d6ad6c2c107847c9ee3900cfdb9b88d'
#We are using SQLite which is simply a file on the localhost, the /// represents a relative path from the current file
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///site.db'

#Create the database instance
db = SQLAlchemy(app)

#Define the class models for the database - these classes represent tables in the database
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(20), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    #The image files will be hashed and the hash will be stored here-
    image_file = db.Column(db.String(20), nullable=False, default ='default.jpg')
    #The password hashing algorithm will generate a 60 character hash
    password = db.Column(db.String(60), nullable=False)
    #User (author) to Post is a one to many relationship, create that relationship here
    posts = db.relationship('Post', backref='author', lazy=True)

    #Define a method that will format the output when a row is printed out
    def __repr__(self):
        return f"User('{self.username}','{self.email}', '{self.image_file}'"

class Post(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(100), nullable=False)
    #For datetime.utcnow we are omitting () -> this will pass the function as the argument instead of the current time
    date = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    content = db.Column(db.Text, nullable=False)
    #Add a foreign key to store the User primary key
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)

    def __repr__(self):
        return f"Post('{self.title}','{self.date}'"


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


@app.route("/")
@app.route("/index")
def index():
    return render_template('index.html', posts=posts_list)

@app.route("/about")
def about():
    return render_template('about.html', title='About')

@app.route("/register", methods=['GET', 'POST'])
def register():
    form = RegistrationForm()

    #If the data validates OK, redirect back to the index page
    if form.validate_on_submit():
        flash(f'Account created for {form.username.data}!')
        return redirect(url_for('index'))

    return render_template('register.html', title='Registration', form=form)

@app.route("/login", methods=['GET', 'POST'])
def login():
    form = LoginForm()

    #Add some validation code, we dont have a user db so we will dummy it up for now
    if form.validate_on_submit():
        if form.email.data == 'admin@blog.com' and form.password.data == 'password':
            flash('You have been logged in!')
            return redirect(url_for('index'))
        else:
            flash('Login unsuccessful. Please check username and password.')

    return render_template('login.html', title='Login', form=form)


#If run from the command line with python script.py, this will run flask to stand up a temp dev webserver
#Want to run this application in debug mode so changes are visible without restarting the www server
if __name__ == '__main__':
    app.run(debug=True)
