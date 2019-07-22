# Flask Tutorial

Based on the excellent tutorial by Corey Schafer: [Link](https://www.youtube.com/playlist?list=PL-osiE80TeTs4UjLw5MM6OjgkjFeUxCYH)


### Required packages

Flask is a python framework, so it will obviously need to be installed.  I used version 3.7.1.

These packages can be installed via pip:
* Flask
* Flask-WTF, installing this will also automatically install the WTForms package
* Flask-sqlalchemy, this will also install SQLAlchemy automatically


### Starting the Flask web server

Flask helpfully includes a dev webserver that can be used to run the site on the local machine.  It can be launched by navigating to the folder containing the project and running `python flaskdemo.py`

The site will be available at `http://localhost:5000`
