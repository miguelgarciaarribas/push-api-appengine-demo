# common definitions to sending/registering stuff to GCM/firefox
from google.appengine.ext import ndb
from google.appengine.ext.ndb import msgprop
import json
from protorpc import messages

DEFAULT_GCM_ENDPOINT = 'https://android.googleapis.com/gcm/send'

# Hand-picked from
# https://developer.android.com/google/gcm/server-ref.html#error-codes
PERMANENT_GCM_ERRORS = {'InvalidRegistration', 'NotRegistered',
                        'InvalidPackageName', 'MismatchSenderId'}
class RegistrationType(messages.Enum):
    SOCCER = 1
    STALE = 2  # GCM told us the registration was no longer valid.

class PushService(messages.Enum):
    GCM = 1
    FIREFOX = 2  # SimplePush

# The key of a GCM Registration entity is the push subscription ID;
# the key of a Firefox Registration entity is the push endpoint URL.
# If more push services are added, consider namespacing keys to avoid collision.
# It only allows to register for one team, will probably need add some
# level of indirection here.
class SoccerRegistration(ndb.Model):
    type = msgprop.EnumProperty(RegistrationType, required=True, indexed=True)
    service = msgprop.EnumProperty(PushService, required=True, indexed=True)
    team =  ndb.StringProperty(required=True, indexed=True)
    creation_date = ndb.DateTimeProperty(auto_now_add=True)

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
