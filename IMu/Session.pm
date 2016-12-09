# KE Software Open Source Licence
# 
# Notice: Copyright (c) 2011-2013 KE SOFTWARE PTY LTD (ACN 006 213 298)
# (the "Owner"). All rights reserved.
# 
# Licence: Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files
# (the "Software"), to deal with the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions.
# 
# Conditions: The Software is licensed on condition that:
# 
# (1) Redistributions of source code must retain the above Notice,
#     these Conditions and the following Limitations.
# 
# (2) Redistributions in binary form must reproduce the above Notice,
#     these Conditions and the following Limitations in the
#     documentation and/or other materials provided with the distribution.
# 
# (3) Neither the names of the Owner, nor the names of its contributors
#     may be used to endorse or promote products derived from this
#     Software without specific prior written permission.
# 
# Limitations: Any person exercising any of the permissions in the
# relevant licence will be taken to have accepted the following as
# legally binding terms severally with the Owner and any other
# copyright owners (collectively "Participants"):
# 
# TO THE EXTENT PERMITTED BY LAW, THE SOFTWARE IS PROVIDED "AS IS",
# WITHOUT ANY REPRESENTATION, WARRANTY OR CONDITION OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING (WITHOUT LIMITATION) AS TO MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. TO THE EXTENT
# PERMITTED BY LAW, IN NO EVENT SHALL ANY PARTICIPANT BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS WITH THE SOFTWARE.
# 
# WHERE BY LAW A LIABILITY (ON ANY BASIS) OF ANY PARTICIPANT IN RELATION
# TO THE SOFTWARE CANNOT BE EXCLUDED, THEN TO THE EXTENT PERMITTED BY
# LAW THAT LIABILITY IS LIMITED AT THE OPTION OF THE PARTICIPANT TO THE
# REPLACEMENT, REPAIR OR RESUPPLY OF THE RELEVANT GOODS OR SERVICES
# (INCLUDING BUT NOT LIMITED TO SOFTWARE) OR THE PAYMENT OF THE COST OF SAME.
#
use strict;
use warnings;

##
# Manages a connection to an IMu server.
#
# The server’s host name and port can be specified by setting properties on
# the object or by setting class-based default properties.
#
# @usage
#   use IMu::Session;
# @end
#
# @since 1.0
#
package IMu::Session;

use IO::Socket::INET;

use IMu::Exception;
use IMu::Stream;
use IMu::Trace;

my $_defaultHost = '127.0.0.1';
my $_defaultPort = 40000;

# Static Properties
#
##
# @property $defaultHost string
#   The name of the host used to create a connection if no object-specific host 
#   has been supplied.
#
sub getDefaultHost
{
	return $_defaultHost;
}

sub setDefaultHost
{
	my $host = shift;

	$_defaultHost = $host;
}

##
# @property $defaultPort int
#   The number of the port used to create a connection if no object-specific 
#   host has been supplied.
#
sub getDefaultPort
{
	return $_defaultPort;
}

sub setDefaultPort
{
	my $port = shift;

	$_defaultPort = $port;
}

# Constructor
#
##
# Creates an `IMu::Session` [$<link>(:session:session)] object with the specified
# ``$host`` and ``$port``.
# 
# @param $host string
#   The default server host.
#
# @param $port string
#   The default server port.
#
# @param $timeout int
#   The default timeout value (in seconds).
#
sub new
{
	my $package = shift;
	my $host = shift;
	my $port = shift;
	my $timeout = shift;

	my $this = bless({}, $package);
	$this->initialise();
	if (defined($host))
	{
		$this->{host} = $host;
	}
	if (defined($port))
	{
		$this->{port} = $port;
	}
	return $this;
}

# Properties
#
##
# @property $close boolean
#
sub getClose
{
	my $this = shift;

	if (! defined($this->{close}))
	{
		return 0;
	}
	return $this->{close};
}

sub setClose
{
	my $this = shift;
	my $close = shift;

	$this->{close} = $close;
}

##
# @property $context string
#
sub getContext
{
	my $this = shift;

	return $this->{context};
}

sub setContext
{
	my $this = shift;
	my $context = shift;

	$this->{context} = $context;
}

##
# @property $host string
#
sub getHost
{
	my $this = shift;

	return $this->{host};
}

sub setHost
{
	my $this = shift;
	my $host = shift;

	$this->{host} = $host;
}

##
# @property $port int
#
sub getPort
{
	my $this = shift;

	return $this->{port};
}

sub setPort
{
	my $this = shift;
	my $port = shift;

	$this->{port} = $port;
}

##
# @property $suspend boolean
#
sub getSuspend
{
	my $this = shift;

	if (! defined($this->{suspend}))
	{
		return 0;
	}
	return $this->{suspend};
}

sub setSuspend
{
	my $this = shift;
	my $suspend = shift;

	$this->{suspend} = $suspend;
}

# Methods
#
##
# Opens a connection to an IMu server.
#
# @throws IMu::Exception
#   The connection could not be opened.
#
sub connect
{
	my $this = shift;

	if (defined($this->{socket}))
	{
		return;
	}

	IMu::Trace::write(2, 'connecting to %s:%d', $this->{host}, $this->{port});
	my $socket = IO::Socket::INET->new
	(
		PeerAddr => $this->{host},
		PeerPort => $this->{port},
		Proto => 'tcp'
	);
	if (! defined($socket))
	{
		die IMu::Exception->new('SesssionConnect', $this->{host}, $this->{port},
			$!);
	}
	IMu::Trace::write(2, 'connected ok');
	$this->{socket} = $socket;
	$this->{stream} = IMu::Stream->new($this->{socket});
}

##
# Closes a connection to the IMu server
#
sub disconnect
{
	my $this = shift;

	if (! defined($this->{socket}))
	{
		return;
	}

	IMu::Trace::write(2, 'closing connection');
	$this->{socket}->close();
	$this->initialise();
}

##
# Logs in as the given user with the given password.
#
# The ``$password`` parameter may be ``null``.
# This will cause the server to use server-side authentication (such as
# .rhosts authentication) to authenticate the user.
#
# If the ``$spawn`` parameter is set to ``1`` (``true``), this will cause the
# server to create a new child process specifically to handle the newly logged 
# in user's requests.
#
# @param $user string
#   The name of the user to log in as.
#
# @param $password string
#   The user's password for authentication.
#
# @param $spawn boolean
#   A flag indicating whether the process should create a new child process
#   specifically for handling the newly logged in user's requests.
#
# @throws IMu::Exception
#   The login request failed.
#
sub login
{
	my $this = shift;
	my $user = shift;
	my $password = @_ ? shift : undef;
	my $spawn = @_ ? shift : 1;

	my $request = {};
	$request->{login} = $user;
	$request->{password} = $password;
	$request->{spawn} = $spawn;
	return $this->request($request);
}

##
# Logs out from the IMu server.
#
# @returns object
#   The result of the logout request.
#
# @since 2.0
#
sub logout
{
	my $this = shift;

	my $request = {};
	$request->{logout} = 1;
	return $this->request($request);
}

##
# Submits a low-level request to the IMu server.
#
# @returns object
#   A `hash` containing the server's response.
#
# @throws IMu::Exception
#   A server-side error occurred.
#
sub request
{
	my $this = shift;
	my $request = shift;

	$this->connect();

	if (defined($this->{close}))
	{
		$request->{close} = $this->{close};
	}
	if (defined($this->{context}))
	{
		$request->{context} = $this->{context};
	}
	if (defined($this->{suspend}))
	{
		$request->{suspend} = $this->{suspend};
	}

	$this->{stream}->put($request);
	my $response = $this->{stream}->get();
	my $type = ref($response);
	if ($type ne 'HASH')
	{
		die IMu::Exception->new('SessionResponse', $type);
	}

	if (exists($response->{context}))
	{
		$this->{context} = $response->{context};
	}
	if (exists($response->{reconnect}))
	{
		$this->{port} = $response->{reconnect};
	}

	my $disconnect = 0;
	if (defined($this->{close}))
	{
		$disconnect = $this->{close};
	}
	if ($disconnect)
	{
		$this->disconnect();
	}

	my $status = $response->{status};
	if ($status eq 'error')
	{
		IMu::Trace::write(2, 'server error');

		my $id = 'SessionServerError';
		if (exists($response->{error}))
		{
			$id = $response->{error};
		}
		elsif (exists($response->{id}))
		{
			$id = $response->{id};
		}

		my $e = IMu::Exception->new($id);

		if (exists($response->{args}))
		{
			$e->setArgs($response->{args});
		}

		IMu::Trace::write(2, 'throwing exception %s', $e->toString());

		die $e;
	}

	return $response;
}

# Private
#
sub initialise
{
	my $this = shift;

	$this->{close} = undef;
	$this->{context} = undef;
	$this->{host} = $_defaultHost;
	$this->{port} = $_defaultPort;
	$this->{socket} = undef;
	$this->{stream} = undef;
	$this->{suspend} = undef;
}

1;
