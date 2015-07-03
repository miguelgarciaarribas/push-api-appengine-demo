# Main class to send notification results to subscribers
from google.appengine.api import urlfetch, users
from google.appengine.ext import ndb

import logging
import json

from model.soccer_registration_model import *

class SendStats:
    success_count = 0
    total_count = 0
    text = ""

def notify_changes(results):
    """ Extract the teams involved in the results and notify about changes. """
    teams = set()
    for result in results:
        # TODO: Probably sanitize that the date is reasonable
        # before deciding to send notifications
        teams.add(result.home_team)
        teams.add(result.visitor_team)
    for team in teams:
        send(team)

# TODO: Store stats somewhere?
def send(team, type=RegistrationType.SOCCER):
    """XHR requesting that we send a push message to all users."""
    gcm_stats = _sendGCM(type, team)
    firefox_stats = _sendFirefox(type, team)

    if gcm_stats.success_count + firefox_stats.success_count == 0:
        if gcm_stats.total_count + firefox_stats.total_count == 0:
            print "No devices are registered to receive messages"
        else:
            logging.error("Failed to send message to any of the %d registered "
                       "devices" % failure_total)

    print "Message sent successfully to %d/%d GCM devices and %d/%d Firefox " \
           "devices%s%s" % (gcm_stats.success_count, gcm_stats.total_count,
                            firefox_stats.success_count,
                            firefox_stats.total_count,
                            gcm_stats.text, firefox_stats.text)
    return


def _sendGCM(type, team):
    gcm_registration_keys = \
            SoccerRegistration.query(SoccerRegistration.type == type,
                                     SoccerRegistration.team == team,
                                     SoccerRegistration.service == PushService.GCM) \
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
        # once if multiple messages are sent whilst the device is offline.
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
        registration.type = RegistrationType.STALE
    ndb.put_multi(stale_registrations)

    return stats


# TODO: FIX
def _sendFirefox(type, team):
    firefox_registration_keys = \
            SoccerRegistration.query(SoccerRegistration.type == type,
                                SoccerRegistration.team == team,
                                SoccerRegistration.service == PushService.FIREFOX) \
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
