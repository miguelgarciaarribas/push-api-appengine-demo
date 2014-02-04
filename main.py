"""`main` is the top level module for your Bottle application."""

import json
import urllib
import bottle
from bottle import get, post, abort, template, request, response
from google.appengine.api import urlfetch
from google.appengine.ext import ndb

# TODO: Have the user provide this, and store it in the datastore
# rather than hardcoding it.
GCM_API_KEY = "INSERT_API_KEY"

# TODO: Probably cheaper to have a singleton entity with a repeated property?
class Registration(ndb.Model):
    gcm_registration_id = ndb.StringProperty()
    creation_date = ndb.DateTimeProperty(auto_now_add=True)

# Define an handler for the root URL of our application.
@get('/')
def index():
    """Show form allowing user to send push messages."""
    return input_form()

@post('/')
def send():
    """User asked us to send push messages."""
    url = "https://android.googleapis.com/gcm/send"
    # TODO: Should limit batches to 1000 registration_ids at a time.
    registration_ids = [r.gcm_registration_id
                        for r in Registration.query().iter()]
    if not registration_ids:
        abort(500, "No registered devices.")
    post_data = json.dumps({
        'registration_ids': registration_ids,
        'data': {
            'data': request.forms.msg,
        },
        #"collapse_key": "score_update",
        #"time_to_live": 108,
        #"delay_while_idle": true,
    })
    result = urlfetch.fetch(url=url,
                            payload=post_data,
                            method=urlfetch.POST,
                            headers={
                                'Content-Type': 'application/json',
                                'Authorization': 'key=' + GCM_API_KEY,
                            })
    if result.status_code != 200:
        abort(500, "Sending failed (status code %d)." % result.status_code)
    return input_form("%d message(s) sent successfully."
                      % len(registration_ids))

def input_form(status_html=""):
    count = Registration.query().count()
    return template("""
        <!doctype html>
        <html><head>
            <title>Push message sender</title>
        </head><body>
            <em>{{status}}</em>
            <form action="/" method="post">
                <h3>Send message to {{count}} registered ids.</h3>
                <input type="text" name="msg"><button type="submit">Send</button>
            </form>
        </body></html>
    """, status=status_html, count=count)

@post('/register')
def register():
    """A device is registering to receive messages."""
    if not request.forms.registration_id:
        abort(400, "Invalid registration id.")
    registration = Registration(
        gcm_registration_id=request.forms.registration_id)
    registration.put()
    response.status = 201
    return ""

bottle.run(server='gae', debug=True)
app = bottle.app()