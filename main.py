"""`main` is the top level module for your Bottle application."""

import json
import urllib
import bottle
from bottle import get, post, abort, template, request, response
from google.appengine.api import urlfetch
from google.appengine.ext import ndb

GCM_ENDPOINT = 'https://android.googleapis.com/gcm/send'

# TODO: Have the user provide this, and store it in the datastore
# rather than hardcoding it.
GCM_API_KEY = 'INSERT_API_KEY'

TYPE_STOCK = 1
TYPE_CHAT = 2

# TODO: Probably cheaper to have a singleton entity with a repeated property?
class Registration(ndb.Model):
    type = ndb.IntegerProperty(required=True, choices=[TYPE_STOCK, TYPE_CHAT])
    creation_date = ndb.DateTimeProperty(auto_now_add=True)

@get('/stock')
def stock():
    """Single page stock app. Displays stock data and lets users register."""
    return template('stock')

@get('/stock/admin')
def stock_admin():
    """Lets "admins" trigger stock price drops."""
    return template('stock_admin')

@get('/chat')
def chat():
    """Single page chat app."""
    return template('chat')

@post('/stock/register')
def register_stock():
    return register(TYPE_STOCK)

@post('/chat/register')
def register_chat():
    return register(TYPE_CHAT)

def register(type):
    """XHR adding a registration ID to our list."""
    if request.forms.registration_id:
        if request.forms.endpoint != GCM_ENDPOINT:
            abort(500, "Push servers other than GCM are not yet supported.")

        registration = Registration.get_or_insert(request.forms.registration_id,
                                                  type=type)
        registration.put()
    response.status = 201
    return ""

@post('/stock/trigger-drop')
def send_stock():
    return send(TYPE_STOCK, '["May", 183]')

@post('/chat/send')
def send_chat():
    return send(TYPE_CHAT, request.forms.message)

def send(type, data):
    """XHR requesting that we send a push message to all users."""
    # TODO: Should limit batches to 1000 registration_ids at a time.
    registration_ids = [r.key.string_id() for r in Registration.query(
                        Registration.type == TYPE_STOCK).iter()]
    if not registration_ids:
        abort(500, "No registered devices.")
    post_data = json.dumps({
        'registration_ids': registration_ids,
        'data': {
            'data': data,  #request.forms.msg,
        },
        #"collapse_key": "score_update",
        #"time_to_live": 108,
        #"delay_while_idle": true,
    })
    result = urlfetch.fetch(url=GCM_ENDPOINT,
                            payload=post_data,
                            method=urlfetch.POST,
                            headers={
                                'Content-Type': 'application/json',
                                'Authorization': 'key=' + GCM_API_KEY,
                            })
    if result.status_code != 200:
        abort(500, "Sending failed (status code %d)." % result.status_code)
    #return "%d message(s) sent successfully." % len(registration_ids)
    response.status = 202
    return ""

bottle.run(server='gae', debug=True)
app = bottle.app()