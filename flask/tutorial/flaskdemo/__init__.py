#7/23/2019
from flask import Flask
from flask_sqlalchemy import SQLAlchemy

#Instantiate the Flask class
app = Flask(__name__)

#Need a secret key to validate our forms (need a better way to handle this secret later on)
app.config['SECRET_KEY'] = '1d6ad6c2c107847c9ee3900cfdb9b88d'
#We are using SQLite which is simply a file on the localhost, the /// represents a relative path from the current file
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///site.db'

#Create the database instance
db = SQLAlchemy(app)

#Need to import routes after we initialize the app to avoid a circular import (since routes.py imports app)
from flaskdemo import routes