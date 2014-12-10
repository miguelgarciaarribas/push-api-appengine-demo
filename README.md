## Push API demo on App Engine

A demo App Engine server using https://w3c.github.io/push-api/ to send push
messages to web browsers.

Live version: https://johnme-gcm.appspot.com/chat/

Currently requires Chrome with "Enable experimental Web Platform features"
enabled in chrome://flags. As other browsers land support for the Push API, this
repository will be updated, and should start working with flag-less Chrome,
Firefox, etc.

See [requirements.txt][1] for instructions on installing dependencies, if you
want to run your own copy on App Engine.

[1]: https://github.com/johnmellor/push-api-appengine-demo/blob/master/requirements.txt
