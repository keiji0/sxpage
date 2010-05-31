#!/usr/bin/env perl

use strict;
use warnings;
use Cwd;

my $conf = do('../%tmp/lighttp-conf.pl');

print '
server.modules = ("mod_access", "mod_rewrite", "mod_accesslog", "mod_alias", "mod_cgi")
server.username = "'.$ENV{USER}.'"
server.document-root = "'.(getcwd).'/../"
server.pid-file = "%tmp/lighttpd.pid"
accesslog.filename = "%tmp/access.log"
server.errorlog = "%tmp/error.log"
server.port = '.$conf->{HTTP_PORT}.'
url.access-deny = ("~", ".inc", ".conf")

include_shell "/usr/share/lighttpd/create-mime.assign.pl"
include_shell "/usr/share/lighttpd/include-conf-enabled.pl"

static-file.exclude-extensions = (".php", ".cgi", ".fcgi")
index-file.names = ("index.cgi", "index.php", "index.html")
cgi.assign = (".cgi" => "")

url.rewrite-once = ("(.*/[^/]+\.(jpg|gif|png|js|txt|pdf|css|html|php))$" => "$1")
url.rewrite-once += ("(.+)" => "/index.cgi$1")
'
