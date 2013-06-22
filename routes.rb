
# relative path to the blog
# if it is located inside the root,
# this should contain an empty string without a tailing slash
Ink::Beauty.root = "/rblog"

# route priority:
# /:controller/:module/:page [-- :page can only consist of numbers
# /:controller/:module       [--
# /:controller               [-- :module is set to index per default
# /                          [-- :controller defaults to blog, :module to index
Ink::Beauty.routes = [
  [ /^\/([^\/]+)\/([^\/]+)(\/([0-9]+)\/?)$/, {:controller => "$1", :module => "$2", :page => "$4"} ],
  [ /^\/([^\/]+)\/([^\/]+)\/?$/, {:controller => "$1", :module => "$2"} ],
  [ /^\/([^\/]+)\/?$/, {:controller => "$1", :module => "index"} ],
  [ /^\/?$/, {:controller => "blog", :module => "index"} ],
]
