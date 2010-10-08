# configure the project
config = {
  "db_server" => "/var/run/rblog.sqlite",   # the path to the sqlite3 database file
  "db_type" => "sqlite3",                   # set the database type to sqlite3
  "escape_post_data" => false,              # use escape HTML from the CGI package to filter any POST data
}
