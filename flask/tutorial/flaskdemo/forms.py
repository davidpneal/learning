#7/20/2019
#Forms for the website

from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, SubmitField, BooleanField

#Import some validator classes so we can validate the input data
from wtforms.validators import DataRequired, Length, Email, EqualTo

#Create a form where users can sign up for the website
class RegistrationForm(FlaskForm):
    #Params: name of the field, validators (these are classes and require parenthesis)
    username = StringField('Username', validators=[DataRequired(), Length(min=2, max=20)])
    #The Email() validator verifies the input matches an email address format
    email = StringField('Email', validators=[DataRequired(), Email()])
    password = PasswordField('Password', validators=[DataRequired()])
    #The EqualTo() validator checks to see if the value equals the value we stored in password
    confirm_password = PasswordField('Confirm Password', validators=[DataRequired(), EqualTo('password')])

    #Need a way to submit this data - this will add a button to the form to do this
    submit = SubmitField('Sign Up')


#Create a form so the users can login with existing credentials
class LoginForm(FlaskForm):
    email = StringField('Email', validators=[DataRequired(), Email()])
    password = PasswordField('Password', validators=[DataRequired()])

    #Add a bool field to remember the user
    remember = BooleanField('Remember Me')

    submit = SubmitField('Login')
