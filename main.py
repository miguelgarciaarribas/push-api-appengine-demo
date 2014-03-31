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
    username = ndb.StringProperty()  # Optional
    gcm_registration_id = ndb.StringProperty()
    creation_date = ndb.DateTimeProperty(auto_now_add=True)

@get('/chat')
def login():
    """Users always start at the login page."""
    return template('login')

@post('/chat')
def register():
    """Receive username and GCM registration ID, and serve chat application."""
    if request.forms.registration_id:
        if (request.forms.endpoint != 'https://android.googleapis.com/gcm/send')
            abort(500, "Push servers other than GCM are not yet supported.")
        registration = Registration(
            username=request.forms.username,
            gcm_registration_id=request.forms.registration_id)
        registration.put()
    return template('chat',
                    username=request.forms.username,
                    registered=bool(request.forms.registration_id));

@post('/chat/send')
def send():
    """XHR requesting that we send a push message to all users."""
    endpoint = 'https://android.googleapis.com/gcm/send'
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
    #return "%d message(s) sent successfully." % len(registration_ids)
    response.status = 201
    return ""

bottle.run(server='gae', debug=True)
app = bottle.app()