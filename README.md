# SharedList

SharedList is a small application to share a list (of spending) between two users.
Contracted work for two friends of mine. :-)
It is currently under development and may crash for no reason. 

## How it works
SharedList is using a pretty simple data model of spending objects (price, date, name, user). Those objects are stored on a local CouchDB instance, powered by [CouchBase Lite](http://www.couchbase.com/mobile).
Due to the nature of CoucDB, sync comes for free and all the magic happens almost automatically!


