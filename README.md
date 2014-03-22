WebInk-Demo is a small blog software intended to show the capabilities of
**webink** available here: https://github.com/matthias-geier/WebInk
The blog is intended to work with the current nightly build and is not
backwards compatible. The implementation is crude and does not make use
of **webinkforms** to show the basic framework capabilities.

## Installation

* **sqlite3**, **webink** and **thin** (or any rack-based server) are required
* Clone the blog sources from github
* Navigate into the cloned folder
* Run *webink_database* which should create the database and add all necessary
  tables
* Run *thin start*

## Using the demo blog

The blog is available under http://localhost:3000/rblog unless configured
differently and the admin interface responds to
http://localhost:3000/rblog/admin
A new user automatically receives the commenter role unless it is the first
user ever, which is raised to the awesome admin status and can promote, demote
and administrate.
