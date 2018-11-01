#!/usr/bin/perl

# Use XML RPC to upload a file into a running exist and set permissions, or to
# execute an XQuery.
#
# Usage: upload-xmlrpc.pl [opts] dbpath < datafile
#        execute-xmlrpc.pl [opts] < xqueryfile
# Help:  upload-xmlrpc.pl -h

use Data::Dumper;
use File::Basename;
use Getopt::Std;
use RPC::XML::Client;
use strict;
use warnings;

# config defaults
my $CONF = {
    user   => 'admin',
    pass   => '',
    host   => 'localhost',
    port   => 8443,
    tls    => 1,
    mime   => 'application/xml',
    parse  => 1,
    replace => 1,
    owner  => 'admin',
    group  => 'SYSTEM',
    mode   => 'rw-r--r--',
    debug  => 0,
};

# check how this program was called
my ($PROGNAME) = fileparse($0);

# parse cmdline options, override defaults
my $OPTS = {};
getopts('dg:hH:Lm:M:o:p:P:Qu:T', $OPTS) or usage();
usage()                     if $OPTS->{h};
$CONF->{debug} = 1          if $OPTS->{d};
$CONF->{user}  = $OPTS->{u} if $OPTS->{u};
$CONF->{pass}  = $OPTS->{p} if $OPTS->{p};
$CONF->{host}  = $OPTS->{H} if $OPTS->{H};
$CONF->{port}  = $OPTS->{P} if $OPTS->{P};
$CONF->{tls}   = 0          if $OPTS->{T};
$CONF->{parse} = 0          if ($OPTS->{Q} or $OPTS->{L});
$CONF->{mime}  = 'application/xquery' if $OPTS->{Q};
$CONF->{mime}  = 'text/html'          if $OPTS->{L};
$CONF->{mime}  = $OPTS->{M} if $OPTS->{M};
$CONF->{owner} = $OPTS->{o} if $OPTS->{o};
$CONF->{group} = $OPTS->{g} if $OPTS->{g};
$CONF->{mode}  = $OPTS->{m} if $OPTS->{m};

# read filename from args and content from STDIN
my $fname  = shift @ARGV;
my @data   = <STDIN>;
my $data   = join("", @data);

# connect to exist XML RPC
my $url    = sprintf("%s://%s:%s\@%s:%d/exist/xmlrpc",
		     $CONF->{tls} ? 'https' : 'http',
		     $CONF->{user}, $CONF->{pass},
		     $CONF->{host}, $CONF->{port});
my $client = RPC::XML::Client->new($url);
#my $client = RPC::XML::Client->new($url, 'useragent', ['ssl_opts', { verify_hostname => 0 }]);

# execute query instead of uploading a file
if ($PROGNAME eq 'execute-xmlrpc.pl') {
    my $code   = RPC::XML::string->new($data);
    my $num    = RPC::XML::int->new(100);
    my $start  = RPC::XML::int->new(0);
    my $parms  = RPC::XML::struct->new({});
    my $exreq  = RPC::XML::request->new('query', $code, $num, $start, $parms);
    my $exres  = $client->send_request($exreq);
    my $exresp;
    if (ref $exres) {
	$exresp = $exres->value;
	print "Execute response: $exresp\n" if $CONF->{debug};
	exit;
    } else {
	print STDERR "Error executing XQuery: $exres\n";
	exit 4;
    }
}

# upload file
my $b64    = RPC::XML::base64->new($data);
my $upreq  = RPC::XML::request->new('upload', $b64, length $b64->value());
my $upres  = $client->send_request($upreq);
my $upresp;
if (ref $upres) {
    $upresp = $upres->value;
    print "Upload response: $upresp\n" if $CONF->{debug};
} else {
    print STDERR "Error uploading file: $upres\n";
    exit 1;
}

# call parseLocal() to store, need to force some explicit data types here
my $desc    = RPC::XML::string->new($upres);
my $parse   = RPC::XML::boolean->new($CONF->{parse});
my $replace = RPC::XML::boolean->new($CONF->{replace});
my $pareq   = RPC::XML::request->new('parseLocalExt', $desc, $fname, 
				     $replace, $CONF->{mime}, $parse);
my $pares   = $client->send_request($pareq);
my $paresp;
if (ref $pares) {
    $paresp = $pares->value;
    print "Store response: $paresp\n" if $CONF->{debug};
    print Dumper($paresp) if $CONF->{debug};
} else {
    print STDERR "Error storing file: $pares\n";
    exit 2;
}

# set owner/group/perms - perms are expected as "rw-r--r--", not 0644
my $mode    = RPC::XML::string->new($CONF->{mode});
my $spreq   = RPC::XML::request->new('setPermissions', $fname,
				     $CONF->{owner}, $CONF->{group}, $mode);
my $spres   = $client->send_request($spreq);
my $spresp;
if (ref $spres) {
    $spresp = $spres->value;
    print "SetPermissions response: $spresp\n" if $CONF->{debug};
    print Dumper($spresp) if $CONF->{debug};
} else {
    print STDERR "Error storing file: $spres\n";
    exit 3;
}

exit;


sub usage {
    print <<USAGE;
Use XML RPC to upload a file into a running exist and set permissions, or to
execute an XQuery.

Usage:

  upload-xmlrpc.pl [OPTIONS] target-filename
  execute-xmlrpc.pl [OPTIONS]

Filename is the eXist DB path where to store the file.
File content to upload or XQuery to execute is expected on STDIN.  Examples:

  upload-xmlrpc.pl /db/apps/foo/bar.xml < bar.xml
  execute-xmlrpc.pl < foo.xql

OPTIONS:

-d       enable debug output
-h       help (this text)
-u user  username to login to eXist XML RPC (default: admin)
-p pass  password to login to eXist XML RPC (default: "")
-H host  URL hostname (default: localhost)
-P port  URL port (default: 8443)
-T       disable TLS connection (default: enabled)
-o owner set owner of uploaded file (default: admin)
-g group set group of uploaded file (default: SYSTEM)
-m mode  set mode  of uploaded file (default: rw-r--r--) - NOT 0644 format!
-M type  set MIME type of uploaded file (default: application/xml)
-Q       uploaded file is XQuery, shortcut for "-M application/xquery"
-L       uploaded file is HTML, shortcut for "-M text/html"
-B       uploaded file is binary [NOT IMPLEMENTED YET]

You probably need to use "-T -P 8080" to force unencrypted HTTP connections
to localhost if untrusted X.509 certs are used.

USAGE
    exit 1;
}
