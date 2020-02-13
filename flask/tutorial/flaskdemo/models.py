#7/23/2019
from flaskdemo import db
from datetime import datetime


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