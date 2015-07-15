package HTTP::HttpServerImpl;

use strict; use warnings;
#use experimental qw(smartmatch);
# ix for dima's perl
no if $] >= 5.018, warnings => "experimental::smartmatch";

# Perl libs & vars
use Exporter;
use IO::Socket;
use feature qw(switch);
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

use lib qw(../);
use RepoManagement::Configuration qw($MYCVS_REPO_STORE $MYCVS_GLOBAL_BASEDIR);
use UserManagement::Impl;
use VersionManagement::Impl;

$VERSION = 1.00;
@ISA = qw(Exporter);
@EXPORT = ();
@EXPORT_OK = qw();

# Local imports

##########################
#                        #
#   ACCESSOR FUNCTIONS   #
#                        #
##########################

sub type {
    my $obj = shift;
    @_ ? $obj->{type} = shift
	: $obj->{type};
}

sub port {
    my $obj = shift;
    @_ ? $obj->{port} = shift
	: $obj->{port};
}

sub socket {
    my $obj = shift;
    @_ ? $obj->{socket} = shift
	: $obj->{socket};
}

###################################################
# Pre: A server type, local port                  #
#      Optional: ssl certificate, ssl key         #
# Post: Returns a perl web server                 #
# Function: Constructor for the perl web server.  #
#           Defines HTTP or HTTPS.                #
###################################################
sub new {
    my ($type, $port, $cert, $key) = @_;
    my $server = IO::Socket::INET->new(Proto => 'tcp',
				       LocalPort => $port,
				       Listen => SOMAXCONN,
				       Type => SOCK_STREAM,
				       Reuse => 1);
    if ($type eq 'http') {
	my $perl_server = bless {
	    "socket"   => $server,
	    "type"     => $type,
	    "port"     => $port
	    };
	return $perl_server;
    } else {
	die "Invalid server type!!!\n";
    }
}
 
###################################################
# Pre: Unparsed CGI data string                   #
# Post: Formatted CGI variables and values        #
# Function: Formats CGI data from client request  #
###################################################
sub parse_cgi {
    my $cgi_vars;
        foreach (@_){
            if ($_ =~ m/\=/i){
                my @split1 = split (/\&/, $_);
                foreach (@split1) {
                    $_ =~ s/^\s+|\s+$//g;
                    $_ =~ s/\+/ /g;
                    (my $var, my $val) = split (/\=/, $_);
                    $cgi_vars .= "\$$var \= \"$val\"\;\n";
                }
            }
        }
    return $cgi_vars;
}

###################################################
# Pre: Server type, response header,              #
#      requested file, client socket connection   #
# Post: None                                      #
# Function: Sends header and file to client.      #
###################################################
sub send_response {
    my ($type, $header, $request_file, $client) = @_;
	send ($client, $header, 0);
	send ($client, $request_file, 0);
}

###################################################
# Pre: Server type, client socket connection      #
# Post: Request line/headers, CGI data            #
# Function: Reads request from appropriate        #
#           connection.  Parses off any existing  #
#           CGI data into a separate scalar       #
###################################################
sub get_request_params {
    my ($type, $client) = @_;
    my ($cgi_data, $content_length, $request, $line);
    my $message_body = 0;

	while ($line = <$client>) {
	    if ($line eq "\r\n") {
            last;
	    }
	    if ($line =~ /Content\-Length/) {
		(my $temp, $content_length) = split (/ /, $line);
            $message_body = 1;
	    }
	    $request .= $line;
	} 
    if ($message_body) {
	    for (my $count = 1; $count <= $content_length; $count++) {
            $cgi_data .= $client->getc;
	    }
	if (length($cgi_data) != $content_length) {
	    print "ERROR 400\n";
	}
    }
    return ($request, $cgi_data);
}

###################################################
# Pre: request file path, length of request file  #
# Post: HTTP header                               #
# Function: Creates an HTTP header using the file #
#           extension of the request and the      #
#           length of the request page            #
###################################################
sub create_header {
    my ($request_path, $length) = @_;
    my @request_file = split (/\//, $request_path);
    (my $temp, my $file_ext) = split (/\./, $request_file[-1]);
    my $mime_type;
    open MIME_TYPES, '../conf/MIME.types' || die "Can't find MIME type file!";
    while (<MIME_TYPES>) {
	(my $ext, my $mime) = split (/ /, $_);
	if ($ext eq '.'.$file_ext) {package UserManagement::Impl;
	    $mime_type = $mime;
	}
    }
    if (!$mime_type) {
	$mime_type = 'text/html';
    }
    close MIME_TYPES;
    my $HTTP_header = "HTTP/1.0 200 OK\nServer: MyCVS WebServer\nContent-Length: ".($length)."\nContent-Type: $mime_type\n\n";
    return $HTTP_header;
}

sub default_header {
    my ($body_len, $aditional_header) = @_;
    my $header = "HTTP/1.0 200 OK\r\nServer: MyCVS WebServer\r\n";
    
    if (! defined($aditional_header)) {
        $aditional_header = "";
    }
    if (! defined($body_len)) {
        $body_len = 0;
    }
    
    $header .= $aditional_header;
    $header .= "Content-Type: text/plain\r\n";
    $header .= "Content-Lenght: ".$body_len."\r\n\r\n";
    
    return $header;
}

# Generates authentication message
sub get_auth_message {
    my $error_page = "<html><h2>Error 401.  Unauthorized.\n</h2></html>";
    my $length = length($error_page);
    my $header = "HTTP/1.0 401 Unauthorized\r\nWWW-Authenticate: Basic realm=\"Test\"\r\n";
    $header .= "Cache-Control: private, no-cache, no-store, must-revalidate, max-age=0, proxy-revalidate, s-maxage=0\r\n";
    $header .= "Expires: 0\r\nPragma: no-cache\r\nVary: *\r\n";
    $header .= "Content-Length: $length\r\nContent-Type: text/html\r\n\r\n";
    $header .= $error_page;
    return $header;
}


sub not_supported_message {
    my ($request) = @_;
    my $body = "Command: $request not supported\r\n";
    my $header = "HTTP/1.0 501 Not Implemented\nContent-Type: text/plain\r\n";
    my $content_len = "Content-Length: ".length($body)."\r\n\r\n";
    my $message = $header.$content_len.$body;
    return $message;
}

sub not_found_message {
    my $body = "<html><h2>Not Found</h2></html>";
    my $header = "HTTP/1.0 404 Not Foundr\nContent-Type: text/plain\r\n";
    my $content_len = "Content-Length: ".length($body)."\r\n\r\n";
    my $message = $header.$content_len.$body;
    return $message;
}

sub process_post {
    my ($request_path, $user, $pass) = @_;
    
}
# Returns Header + Data content
sub process_get {
    my ($request_path, $user, $pass) = @_;
    my ($command_with_vars, $command, $vars_line, $data, $header, %vars, @splitted_path);
    #if (authorize_user($user, $pass) ne 200) {
    #    return (get_auth_message(), "");
    #}
    @splitted_path = split ('/', $request_path);
    if ((@splitted_path) && ($splitted_path[1] ne "repo")) {
        return (not_supported_message($request_path), "");
    }
    
    $command_with_vars = $splitted_path[2];
    ($command, $vars_line) = split('\?', $command_with_vars);
    %vars = parse_vars($vars_line);
    ($header, $data) = get_content($command, %vars);
    
    if ((!defined($data))) {
        $header = not_found_message();
        $data = "";
    } else {
        $header = default_header(length($data), $header);
    }
    
    
    return ($header, $data);
}

sub process_delete {
    my ($request_path, $user, $pass) = @_;
    
}

sub get_content {
    my ($command, %vars) = @_;
    my $content = "";
    my @tmp_lines;
    my $header = "";
    my $timestamp;
    my $reponame = $vars{'reponame'};
    my $filename = $vars{'filename'};
    my $revision = $vars{'revision'};
    
    
    given($command) {
        when("diff") {
            @tmp_lines = get_diff($MYCVS_REPO_STORE.'/'.$reponame.$filename, $revision);
            foreach my $line(@tmp_lines) {
                $content .= $line;
            }
        }
        when("checkin") {
            
        }
        when ("checkout") {
            my $file = $MYCVS_REPO_STORE.'/'.$reponame.$filename;
            ($timestamp, @tmp_lines) = make_checkout($file, $revision);
            
            if (defined($timestamp)) {
                $header = "Time-Stamp: ".$timestamp;
            }
            
            foreach my $line(@tmp_lines) {
                $content .= $line;
            }
        }
        when("revisions") {
            @tmp_lines = get_revisions($MYCVS_REPO_STORE.'/'.$reponame.$filename);
            foreach my $line(@tmp_lines) {
                $content .= $line;
            }
        }
        default {
            return;
        }
    }
    return ($header, $content);
}

sub authorize_user {
    my ($user, $password) = @_;
    if ((! defined($user)) || (! defined($password))) {
        return 401;
    }
    
    if ((! exists_user($user)) || (generate_pass_hash($password) ne get_pass_hash($user))) {
        return 401;
    }
    
    return 200;
}

sub parse_vars {
    my ($string_variables) = @_;
    my %vars = ();
    my @splitted = split('&', $string_variables);
    foreach my $line(@splitted) {
        my @sv = split('=', $line);
        $vars{$sv[0]} = $sv[1];
    }
    return %vars;
}

1;
