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
#           Defines HTTP (can add https if needed)#
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
    my $error_page = "Error 401.  Unauthorized.\r\n";
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
    my $header = "HTTP/1.0 501 Not Implemented\r\nContent-Type: text/plain\r\n";
    my $content_len = "Content-Length: ".length($body)."\r\n\r\n";
    my $message = $header.$content_len.$body;
    return $message;
}
sub bad_request_message {
    my $body = "Mallformed HTTP Request\r\n";
    my $header = "HTTP/1.0 400 Bad request\r\nContent-Type: text/plain\r\n";
    my $content_len = "Content-Length: ".length($body)."\r\n\r\n";
    my $message = $header.$content_len.$body;
    return $message;
}

sub file_locked_message {
    my ($repo, $file_path, $user) = @_;
    my $body = "Given file: $file_path in Repo: $repo locked by user: $user.\r\n";
    my $header = "HTTP/1.0 403 Forbidden\r\nContent-Type: text/plain\r\n";
    my $content_len = "Content-Length: ".length($body)."\r\n\r\n";
    my $message = $header.$content_len.$body;
    return $message;
}

sub not_found_message {
    my $body = "Not Found";
    my $header = "HTTP/1.0 404 Not Found\r\nContent-Type: text/plain\r\n";
    my $content_len = "Content-Length: ".length($body)."\r\n\r\n";
    my $message = $header.$content_len.$body;
    return $message;
}

sub process_post {
    my ($request_path, $user, $pass, $data) = @_;
    my ($command_line, $command, $vars_line, $header, %vars);
    if (authorize_user($user, $pass) ne 200) {
        return (get_auth_message(), "");
    }
    
    # Here user was already been authorized.
    ($command_line, $vars_line) = split_address($request_path);
    %vars = parse_vars($vars_line);
    
    given(get_parent_command($command_line)) {
        when("repo") {
            print "Processing 'repo' Request\n";
            $header = repo_post_commands(get_sub_command($command_line), $user, $data, %vars);
        }
        when("user") {
            print "Processing 'user' Request\n";
            $header = user_post_commands(get_sub_command($command_line), $user, %vars);
        }
        default {
            print "'".$command_line."' Not supported Request\n";
            return (not_supported_message($request_path), "");
        }
    }
    
    if ((!defined($header))) {
        $header = not_supported_message($request_path);
    } elsif ($header eq "locked") {
        $header = file_locked_message($vars{'reponame'}, $vars{'filename'});
    } else {
        $header = default_header(0, $header);
    }
    
    
    return ($header, "");
    
}
# Returns Header + Data content
sub process_get {
    my ($request_path, $user, $pass) = @_;
    my ($command_line, $command, $vars_line, $data, $header, %vars);
    
    if (authorize_user($user, $pass) ne 200) {
        return (get_auth_message(), "");
    }
    
    # Here user was already been authorized.
    ($command_line, $vars_line) = split_address($request_path);
    %vars = parse_vars($vars_line);
    
    given(get_parent_command($command_line)) {
        when("repo") {
            print "Processing 'repo' Request\n";
            ($header, $data) = repo_get_commands(get_sub_command($command_line), $user, %vars);
        }
        default {
            print "'".$command_line."' Not supported Request\n";
            return (not_supported_message($request_path), "");
        }
    }
    
    if (!defined($data)) {
        $header = not_found_message();
        $data = "";
    } elsif (!defined($header)) {
        $header = not_supported_message($request_path);
    } elsif (defined($header) && !defined($data)) {
        $data = "";
    } else {
        $header = default_header(length($data), $header);
    }
    return ($header, $data);
}

sub process_delete {
    my ($request_path, $user, $pass) = @_;
    my ($command_line, $command, $vars_line, $header, %vars);
    if (authorize_user($user, $pass) ne 200) {
        return (get_auth_message(), "");
    }
    
    # Here user was already been authorized.
    ($command_line, $vars_line) = split_address($request_path);
    %vars = parse_vars($vars_line);
    
    given(get_parent_command($command_line)) {
        when("repo") {
            print "Processing 'repo' Request\n";
            $header = repo_delete_commands(get_sub_command($command_line), $user, %vars);
        }
        when("user") {
            print "Processing 'user' Request\n";
            $header = user_delete_commands(get_sub_command($command_line), $user, %vars);
        }
        default {
            print "'".get_parent_command($command_line)."' Not supported Request\n";
            return (not_supported_message($request_path), "");
        }
    }
    
    if ((!defined($header))) {
        $header = not_supported_message($request_path);
    } else {
        $header = default_header(0, $header);
    }
    
    
    return ($header, "");
    
}

# Receives request path
# Returns command and vars string in query path
sub split_address {
    my ($request_path) = @_;
    if (!defined($request_path)) {
        return;
    }
    
    return split('\?', $request_path);
}
# Extracts subcommand from command line
# Example: from /repo/user/add -> /user/add
sub get_sub_command {
    my ($command) = @_;
    my $pcommand;
    if (!defined($command)) {
        return;
    }
    $pcommand = get_parent_command($command);
    $command =~ s/^\/$pcommand//;
    return $command;
}

sub get_parent_command {
    my ($command) = @_;
    my $pcommand;
    if (!defined($command)) {
        return;
    }
    my @splitted = split('/', $command);
    $pcommand = $splitted[1];
    return $pcommand;
}

sub repo_get_commands {
    my ($command, $user, %vars) = @_;
    my $content = "";
    my @tmp_lines;
    my $header = "";
    my $timestamp;
    my $reponame = $vars{'reponame'};
    my $filename = $vars{'filename'};
    my $revision = $vars{'revision'};
    
    if ((! defined($reponame)) || (! defined($filename))) {
        return;
    }
    
    if (! exist_user_in_group($user, $reponame)) {
        return (get_auth_message(), "");
    }
    
    
    
    given(get_parent_command($command)) {
        when("revision") {
            print "Processing 'revision' Request\n";
            my $file = $MYCVS_REPO_STORE.'/'.$reponame.$filename;
            if (! -f $file) {
                return;
            }
            
            ($timestamp, @tmp_lines) = get_merged_plain_file($file, $revision);
            if (! @tmp_lines) {
                return;
            }
            
            
            if (!defined($timestamp)) {
                $timestamp = 0;
            }
            $header = "Time-Stamp: ".$timestamp."\r\n";
            
            foreach my $line(@tmp_lines) {
                $content .= $line;
            }
        }
        when ("checkout") {
            print "Processing 'checkout' Request\n";
            my $file = $MYCVS_REPO_STORE.'/'.$reponame.$filename;
            
            if (! -f $file) {
                return;
            }
            
            if (!is_file_locked($file)) {
                lock_file($file, $user);
            } elsif (get_locked_user($file) ne $user) {
                return (file_locked_message($reponame, $filename, $user), "");
            }
            
            ($timestamp, @tmp_lines) = make_checkout($file, $revision);
            if (! @tmp_lines) {
                return;
            }
            
            
            if (!defined($timestamp)) {
               $timestamp = 0;
            }
            $header = "Time-Stamp: ".$timestamp."\r\n";
            
            foreach my $line(@tmp_lines) {
                $content .= $line;
            }
        }
        when("revisions") {
            print "Processing 'revisions' Request\n";
            @tmp_lines = print_revisions_to_array($MYCVS_REPO_STORE.'/'.$reponame.$filename);
            
            if (!@tmp_lines) {
                return;
            }
            
            foreach my $line(@tmp_lines) {
                $content .= $line;
            }
            
            $header = "";
        }
        when("timestamp") {
            print "Processing 'timestamp' Request\n";
            my $file = $MYCVS_REPO_STORE.'/'.$reponame.$filename;
            $timestamp = get_timestamp($file, $revision);
            
            if (defined($timestamp)) {
                $header = "Time-Stamp: ".$timestamp."\r\n";
                $content = $header;
            } else {
                return;
            }
        }
        when("filelist") {
            print "Processing 'filelist' Request\n";
            my @tmp_lines = get_dir_contents_recur($MYCVS_REPO_STORE.'/'.$reponame);
            use Data::Dumper;
            print Dumper @tmp_lines;
            foreach my $line(@tmp_lines) {
                print "OK";
                $content .= $line."\n";
            }
            $header = "";
        }
        default {
            print "'".$command."' not supported Request\n";
            return;
        }
    }
    return ($header, $content);
}

sub repo_delete_commands {
    my ($command, $user, %vars) = @_;
    my $reponame = $vars{'reponame'};
    my $username = $vars{'username'};
    my $header;
    
       
    if (! is_user_admin($user)) {
        return (get_auth_message(), "");
    }
    
    given($command) {
        when("/del") {
            print "Processing 'del' Request\n";
            # Delete Repository
        }
        when("/user/del") {
            print "Processing 'user/del' Request\n";
            # Revoke user permission on repository
        }
        default {
            print "'".$command."' Not supported Request\n";
            return;
        }
    }
    return $header;
}

sub repo_post_commands {
    my ($command, $user, $data, %vars) = @_;
    my $reponame = $vars{'reponame'};
    my $filename = $vars{'filename'};
    my $revision = $vars{'revision'};
    my $header;
    
    
    given($command) {
        when("/checkin") {
            print "Processing 'checkin' Request\n";
            if ((! defined($reponame)) || (! defined($filename))) {
                return;
            }
            if (! exist_user_in_group($user, $reponame)) {
                return get_auth_message();
            }
            my $real_file_path = $MYCVS_REPO_STORE.'/'.$reponame.$filename;
            
            if ((is_file_locked($real_file_path)) && ($user ne get_locked_user())) {
                return file_locked_message($reponame, $filename);
            }
            
            save_string_to_new_file($data, $real_file_path);
            make_checkin($real_file_path);
            
            unlock_file($real_file_path);
            $header = "";
        }
        when("/add") {
            print "Processing 'add' Request\n";
        }
        when("/user/add") {
            print "Processing '/user/add' Request\n";
            my $username = $vars{'username'};
            my $passhash = $vars{'pass'};
            my $isAdmin = $vars{'admin'};
            
        }
        when("/unlock") {
            print "Processing 'unlock' Request\n";
            
        }
        default {
            print "'".$command."' Not supported Request\n";
            return;
        }
    }
    
    return $header;
}

sub user_post_commands {
    my ($command, $user, %vars) = @_;
    my $reponame = $vars{'reponame'};
    my $filename = $vars{'filename'};
    my $revision = $vars{'revision'};
    my $header;
    
    
    return $header;
}
sub user_delete_commands {
    my ($command, $user, %vars) = @_;
    my $reponame = $vars{'reponame'};
    my $filename = $vars{'filename'};
    my $revision = $vars{'revision'};
    my $header;
    
    
    return $header;
}

sub authorize_user {
    my ($user, $password) = @_;
    if ((! defined($user)) || (! defined($password))) {
        return 401;
    }
    chomp $password;
    chomp $user;
    if ((! exists_user($user)) || (generate_pass_hash($password) ne get_pass_hash($user))) {
        return 401;
    }
    
    return 200;
}

sub parse_vars {
    my ($string_variables) = @_;
    my %vars = ();
    if (!defined($string_variables)) {
        return;
    }
    
    my @splitted = split('&', $string_variables);
    foreach my $line(@splitted) {
        my @sv = split('=', $line);
        $vars{$sv[0]} = $sv[1];
    }
    return %vars;
}

1;
