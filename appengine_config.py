"""This file is loaded when starting a new application instance."""
import sys
import os.path

# add `lib` subdirectory to `sys.path`, so our `main` module can load
# third-party libraries.
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'lib'))

appstats_CALC_RPC_COSTS = True
appstats_SHELL_OK = True

def webapp_add_wsgi_middleware(app):
  from google.appengine.ext.appstats import recording
  app = recording.appstats_wsgi_middleware(app)
  return app
