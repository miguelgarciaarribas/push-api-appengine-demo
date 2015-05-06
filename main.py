"""`main` is the top level module for your Bottle application."""

import bottle
from bottle import get, post, route, abort, redirect, template, request, response
import cgi
from google.appengine.api import app_identity, urlfetch, users
from google.appengine.ext import ndb
from google.appengine.ext.ndb import msgprop
import datetime
import json
import logging
import re
import os
import soccer_collect_handler
import soccer_feed_handler
from protorpc import messages
from soccer_parser import SoccerProvider, SoccerResult
import urllib

DEFAULT_GCM_ENDPOINT = 'https://android.googleapis.com/gcm/send'

# Hand-picked from
# https://developer.android.com/google/gcm/server-ref.html#error-codes
PERMANENT_GCM_ERRORS = {'InvalidRegistration', 'NotRegistered',
                        'InvalidPackageName', 'MismatchSenderId'}

class RegistrationType(messages.Enum):
    LEGACY = 1
    CHAT = 2
    CHAT_STALE = 3  # GCM told us the registration was no longer valid.

class PushService(messages.Enum):
    GCM = 1
    FIREFOX = 2  # SimplePush

class GcmSettings(ndb.Model):
    SINGLETON_DATASTORE_KEY = 'SINGLETON'

    @classmethod
    def singleton(cls):
        return cls.get_or_insert(cls.SINGLETON_DATASTORE_KEY)

    endpoint = ndb.StringProperty(
            default=DEFAULT_GCM_ENDPOINT,
            indexed=False)
    sender_id = ndb.StringProperty(default="", indexed=False)
    api_key = ndb.StringProperty(default="", indexed=False)

# The key of a GCM Registration entity is the push subscription ID;
# the key of a Firefox Registration entity is the push endpoint URL.
# If more push services are added, consider namespacing keys to avoid collision.
class Registration(ndb.Model):
    type = msgprop.EnumProperty(RegistrationType, required=True, indexed=True)
    service = msgprop.EnumProperty(PushService, required=True, indexed=True)
    creation_date = ndb.DateTimeProperty(auto_now_add=True)

class Message(ndb.Model):
    creation_date = ndb.DateTimeProperty(auto_now_add=True)
    text = ndb.StringProperty(indexed=False)

def thread_key(thread_name='default_thread'):
    return ndb.Key('Thread', thread_name)

@route('/setup', method=['GET', 'POST'])
def setup():
    # app.yaml should already have ensured that the user is logged in as admin.
    if not users.is_current_user_admin():
        abort(401, "Sorry, only administrators can access this page.")

    is_dev = os.environ.get('SERVER_SOFTWARE', '').startswith('Development')
    setup_scheme = 'http' if is_dev else 'https'
    setup_url = '%s://%s/setup' % (setup_scheme,
                                   app_identity.get_default_version_hostname())
    if request.url != setup_url:
        redirect(setup_url)

    result = ""
    settings = GcmSettings.singleton()
    if (request.forms.sender_id and request.forms.api_key and
            request.forms.endpoint):
        # Basic CSRF protection (will block some valid requests, like
        # https://1-dot-johnme-gcm.appspot.com/setup but ohwell).
        if request.get_header('Referer') != setup_url:
            abort(403, "Invalid Referer.")
        settings.endpoint = request.forms.endpoint
        settings.sender_id = request.forms.sender_id
        settings.api_key = request.forms.api_key
        settings.put()
        result = 'Updated successfully'
    return template('setup', result=result,
                             endpoint=settings.endpoint,
                             sender_id=settings.sender_id,
                             api_key=settings.api_key)
@get('/feed/soccer')
def feedSoccer():
  results = soccer_feed_handler.soccer_feed_request()
  return "<p>This should be working... </p>" + str(results)

@get('/collect/soccer')
def feedSoccer():
  day = request.query.get('day') or datetime.datetime.now().day
  month = request.query.get('month') or datetime.datetime.now().month
  year = request.query.get('year') or datetime.datetime.now().year
  return soccer_collect_handler.display_results(day, month, year)

@get('/display/soccer')
def feedSoccer():
  return template('soccer', user_from_get = 'hello')


@get('/manifest.json')
def manifest():
    return {
        "short_name": "Chat App",
        "name": "Chat App",
        "icons": [{
            "src": "/static/hangouts.png",
            "sizes": "42x42",
            "type": "image/png"
        }],
        "display": "standalone",
        "start_url": "/chat/",
        "gcm_sender_id": GcmSettings.singleton().sender_id,
        "gcm_user_visible_only": True
    }

@get('/')
def root_redirect():
    redirect("/chat/")

@get('/chat')
def chat_redirect():
    redirect("/chat/")

@get('/chat/')
def chat():
    """Single page chat app."""
    return template_with_sender_id('chat', user_from_get = request.query.get('user') or '')

@get('/chat/messages')
def chat_messages():
    """XHR to fetch the most recent chat messages."""
    messages = reversed(Message.query(ancestor=thread_key())
                               .order(-Message.creation_date).fetch(20))
    return "\n".join(re.sub(r'\r\n|\r|\n', ' ', cgi.escape(m.text))
                     for m in messages)

@get('/admin')
def legacy_chat_admin_redirect():
    redirect("/chat/admin")

@get('/chat/admin')
def chat_admin():
    """Lets "admins" clear chat registrations."""
    # Despite the name, this route has no credential checks - don't put anything
    # sensitive here!
    # This template doesn't actually use the sender_id, but we want the warning.
    return template_with_sender_id('chat_admin')

def template_with_sender_id(*args, **kwargs):
    settings = GcmSettings.singleton()
    if not settings.sender_id or not settings.api_key:
        abort(500, "You need to visit /setup to provide a GCM sender ID and "
                   "corresponding API key")
    kwargs['sender_id'] = settings.sender_id
    return template(*args, **kwargs)

@post('/chat/subscribe')
def register_chat():
    return register(RegistrationType.CHAT)

def register(type):
    """XHR adding a registration ID to our list."""
    if not request.forms.endpoint:
        abort(400, "Missing endpoint")

    if request.forms.endpoint == DEFAULT_GCM_ENDPOINT:
        if not request.forms.subscription_id:
            abort(400, "Missing subscription_id")
        registration = Registration.get_or_insert(request.forms.subscription_id,
                                                  type=type,
                                                  service=PushService.GCM)
    else:
        # Assume unknown endpoints are Firefox Simple Push.
        # TODO: Find a better way of distinguishing these.
        registration = Registration.get_or_insert(request.forms.endpoint,
                                                  type=type,
                                                  service=PushService.FIREFOX)
    registration.put()
    response.status = 201
    return ""

@post('/chat/clear-registrations')
def clear_chat_registrations():
    ndb.delete_multi(
            Registration.query(Registration.type == RegistrationType.CHAT)
                        .fetch(keys_only=True))
    ndb.delete_multi(
            Registration.query(Registration.type == RegistrationType.CHAT_STALE)
                        .fetch(keys_only=True))
    return ""

@post('/chat/send')
def send_chat():
    return send(RegistrationType.CHAT, request.forms.message)

def send(type, data):
    """XHR requesting that we send a push message to all users."""
    # Store message
    message = Message(parent=thread_key())
    message.text = data
    message.put()

    gcm_stats = sendGCM(type, data)
    firefox_stats = sendFirefox(type, data)

    if gcm_stats.total_count + firefox_stats.total_count \
            != Registration.query(Registration.type == type).count():
        # Migrate old registrations that don't yet have a service property;
        # they'll miss this message, but at least they'll work next time.
        # TODO: Remove this after a while.
        registrations = Registration.query(Registration.type == type).fetch()
        registrations = [r for r in registrations if r.service == None]
        for r in registrations:
            r.service = PushService.GCM
        ndb.put_multi(registrations)

    if gcm_stats.success_count + firefox_stats.success_count == 0:
        if gcm_stats.total_count + firefox_stats.total_count == 0:
            abort(500, "No devices are registered to receive messages")
        else:
            abort(500, "Failed to send message to any of the %d registered "
                       "devices" % failure_total)

    response.status = 201
    return "Message sent successfully to %d/%d GCM devices and %d/%d Firefox " \
           "devices%s%s" % (gcm_stats.success_count, gcm_stats.total_count,
                            firefox_stats.success_count,
                            firefox_stats.total_count,
                            gcm_stats.text, firefox_stats.text)

class SendStats:
    success_count = 0
    total_count = 0
    text = ""

def sendFirefox(type, data):
    firefox_registration_keys = \
            Registration.query(Registration.type == type,
                               Registration.service == PushService.FIREFOX) \
                        .fetch(keys_only=True)
    push_endpoints = [key.string_id() for key in firefox_registration_keys]

    stats = SendStats()
    stats.total_count = len(push_endpoints)
    if not push_endpoints:
        return stats

    for endpoint in push_endpoints:
        result = urlfetch.fetch(url=endpoint,
                                payload="",
                                method=urlfetch.PUT)
        if result.status_code == 200:
            stats.success_count += 1
        else:
            logging.error("Firefox send failed %d:\n%s" % (result.status_code,
                                                           result.content))
        # TODO: Deal with stale connections.
    return stats

def sendGCM(type, data):
    gcm_registration_keys = \
            Registration.query(Registration.type == type,
                               Registration.service == PushService.GCM) \
                        .fetch(keys_only=True)
    registration_ids = [key.string_id() for key in gcm_registration_keys]

    stats = SendStats()
    stats.total_count = len(registration_ids)
    if not registration_ids:
        return stats

    # TODO: Should limit batches to 1000 registration_ids at a time.
    post_data = json.dumps({
        'registration_ids': registration_ids,
        # Chrome doesn't yet support receiving data https://crbug.com/434808
        # (this is blocked on standardizing an encryption format).
        # Hence it's optimal to use collapse_key so device only gets woken up
        # once if multiple messages are sent whilst the device is offline (when
        # the Service Worker asks us what has changed since it last synced, by
        # fetching /chat/messages, it'll get all the new messages).
        #'data': {
        #    'data': data,  #request.forms.msg,
        #},
        'collapse_key': str(type),
        #'time_to_live': 108,
        #'delay_while_idle': true,
    })
    settings = GcmSettings.singleton()
    result = urlfetch.fetch(url=settings.endpoint,
                            payload=post_data,
                            method=urlfetch.POST,
                            headers={
                                'Content-Type': 'application/json',
                                'Authorization': 'key=' + settings.api_key,
                            },
                            validate_certificate=True,
                            allow_truncated=True)
    if result.status_code != 200:
        logging.error("GCM send failed %d:\n%s" % (result.status_code,
                                                   result.content))
        return stats

    try:
        result_json = json.loads(result.content)
        stats.success_count = result_json['success']
        if users.is_current_user_admin():
            stats.text = '\n\n' + result.content
    except:
        logging.exception("Failed to decode GCM JSON response")
        return stats

    # Stop sending messages to registrations that GCM tells us are stale.
    stale_keys = []
    for i, res in enumerate(result_json['results']):
        if 'error' in res and res['error'] in PERMANENT_GCM_ERRORS:
            stale_keys.append(gcm_registration_keys[i])
    stale_registrations = ndb.get_multi(stale_keys)
    for registration in stale_registrations:
        registration.type = RegistrationType.CHAT_STALE
    ndb.put_multi(stale_registrations)

    return stats


bottle.run(server='gae', debug=True)
app = bottle.app()
