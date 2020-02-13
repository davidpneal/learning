#7/23/2019
from flask import render_template, url_for, flash, redirect
from flaskdemo import app
from flaskdemo.forms import RegistrationForm, LoginForm
from flaskdemo.models import User, Post


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