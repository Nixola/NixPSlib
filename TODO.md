# TODO
* Rework Message: messages should know their sender, their room (if not private), and they should have a reply method to automatically send a reply via the proper channel (either the same room or PM), plus additional methods for more specific replies, e.g. replyPrivate to either send a PM or send an in-room reply only visible to the sender. replyPM shouldn't be needed, as one could just send a PM to the sender.
* Fix dependencies: add indirect dependencies to the rockspec
