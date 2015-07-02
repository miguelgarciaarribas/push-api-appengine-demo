"""`main` is the top level module for your Bottle application."""

import bottle
from bottle import get, post, route, abort, redirect, template, request, response
import cgi
from google.appengine.api import app_identity, users
from google.appengine.ext import ndb
import datetime
import logging
import re
import os
import urllib

from server import soccer_change_sender
from server import soccer_collect_handler
from server import soccer_feed_handler
from server.parser.soccer_parser import SoccerProvider, SoccerResult
from server.model import soccer_registration_model
from server.model.soccer_registration_model import GcmSettings


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
    return template('templates/setup', result=result,
                             endpoint=settings.endpoint,
                             sender_id=settings.sender_id,
                             api_key=settings.api_key)

# TODO Make this an admin url
@get('/test/sendmessage')
def testSend():
  stats = soccer_change_sender.send("Real Perdiz")
  if stats:
     response.status = 201
  return str(stats)

@route('/test/feed', method=['GET', 'POST'])
def feedTest():
    competition = request.forms.competition
    hometeam = request.forms.hometeam
    homescore = request.forms.homescore
    visitorteam = request.forms.visitorteam
    visitorscore = request.forms.visitorscore

    try:
        int(homescore)
        int(visitorscore)
    except:
        return template('templates/feed-test',
            competition = request.forms.competition,
            hometeam ="",
            homescore ="",
            visitorteam ="",
            visitorscore ="",
            result = "Scores invalid")
    if competition != "" and hometeam != "" and visitorteam != "":
        soccer_feed_handler.merge_test_entry(
            competition, hometeam, str(homescore), visitorteam, str(visitorscore),
            soccer_change_sender.notify_changes)
        return template('feed-test',
                        competition = competition,
                        hometeam = hometeam,
                        homescore = str(homescore),
                        visitorteam = visitorteam,
                        visitorscore = str(visitorscore),
                        result = " Test result saved successfully.")
    return template('feed-test',
                    competition = request.forms.competition,
                    hometeam = "",
                    homescore = "",
                    visitorteam = "",
                    visitorscore = "",
                    result = "not enough data")


@get('/feed/soccer')
def feedSoccer():
  results = soccer_feed_handler.soccer_feed_request(soccer_change_sender.notify_changes)
  return "<p>This should be working... </p>" + str(results)

@get('/collect/soccer')
def feedSoccer():
  day = request.query.get('day') or datetime.datetime.now().day
  month = request.query.get('month') or datetime.datetime.now().month
  year = request.query.get('year') or datetime.datetime.now().year
  return soccer_collect_handler.display_results(day, month, year)


#TODO user_from_get probably obsolete
@get('/display/soccer')
def feedSoccerOffline():
  return template('templates/soccer', user_from_get = 'hello')


@get('/manifest.json')
def manifest():
    return {
        "short_name": "Sports Latest",
        "name": "Sport Latest",
        "icons": [{
            "src": "/static/hangouts.png",
            "sizes": "42x42",
            "type": "image/png"
        }],
        "display": "standalone",
        "start_url": "/display/soccer_offline",
        "gcm_sender_id": GcmSettings.singleton().sender_id,
        "gcm_user_visible_only": True
    }

@get('/')
def root_redirect():
    redirect("/display/soccer_offline")

#TODO: redirect to a chatless place and rename the chat template
@get('/admin')
def legacy_chat_admin_redirect():
    redirect("/chat/admin")

@get('/chat/admin')
def chat_admin():
    """Lets "admins" clear chat registrations."""
    # Despite the name, this route has no credential checks - don't put anything
    # sensitive here!
    # This template doesn't actually use the sender_id, but we want the warning.
    return template_with_sender_id('templates/chat_admin')

def template_with_sender_id(*args, **kwargs):
    settings = GcmSettings.singleton()
    if not settings.sender_id or not settings.api_key:
        abort(500, "You need to visit /setup to provide a GCM sender ID and "
                   "corresponding API key")
    kwargs['sender_id'] = settings.sender_id
    return template(*args, **kwargs)

@post('/subscribe/soccer')
def register_soccer():
    return register(RegistrationType.SOCCER)

def register(type):
    """XHR adding a registration ID to our list."""
    if not request.forms.endpoint:
        abort(400, "Missing endpoint")
    if not request.forms.team:
        abort(400, "Missing team")

    if DEFAULT_GCM_ENDPOINT in request.forms.endpoint:
        logging.error("Subscription ID:" + str(request.forms.subscription_id))
        if not request.forms.subscription_id:
            abort(400, "Missing subscription_id")

        registration = SoccerRegistration.get_or_insert(request.forms.subscription_id,
                                                    type=type,
                                                    team=request.forms.team,
                                                    service=PushService.GCM)
    else:
        # Assume unknown endpoints are Firefox Simple Push.
        # TODO: Find a better way of distinguishing these.
        registration = SoccerRegistration.get_or_insert(request.forms.endpoint,
                                                    type=type,
                                                    team=request.forms.team,
                                                    service=PushService.FIREFOX)
    registration.put()
    response.status = 201
    return ""

# TODO: PORT THIS TO SOCCER
@post('/chat/clear-registrations')
def clear_chat_registrations():
    ndb.delete_multi(
            Registration.query(Registration.type == RegistrationType.CHAT)
                        .fetch(keys_only=True))
    ndb.delete_multi(
            Registration.query(Registration.type == RegistrationType.CHAT_STALE)
                        .fetch(keys_only=True))
    return ""


bottle.run(server='gae', debug=True)
app = bottle.app()
