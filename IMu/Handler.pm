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
# Provides a general low-level interface to creating server-side objects.
#
# @usage
#   use IMu::Handler;
# @end
#
# @since 1.0
#
package IMu::Handler;

use IMu::Exception;
use IMu::Session;
use IMu::Trace;

# Constructor
#
##
# Creates an object which can be used to interact with server-side objects.
#
# @param $session string
#   An `IMu::Session` [$<link>(:session:session)] object to be used to
#   communicate with the IMu server.
#
#   If this parameter is not supplied, a new session is created automatically
#   using the `IMu::Session` class's **defaultHost** 
#   [$<link>(:session:defaultHost)]
#   and **defaultPort** [$<link>(:session:defaultPort)] values.
#
sub new
{
	my $package = shift;
	my $session = shift;

	my $this = bless({}, $package);

	if (! defined($session))
	{
		$this->{session} = IMu::Session->new();
	}
	else
	{
		$this->{session} = $session;
	}

	$this->{create} = undef;
	$this->{destroy} = undef;
	$this->{id} = undef;
	$this->{language} = undef;
	$this->{name} = undef;

	return $this;
}

# Properties
#
##
# @property $create mixed
#   An object to be passed to the server when the server-side object is created.
#
#   To have any effect this must be set before any object methods are called.
#   This property is usually only set by sub-classes of `IMu::Handler`
#   [$<link>(:handler:handler)].
#
sub getCreate
{
	my $this = shift;

	return $this->{create};
}

sub setCreate
{
	my $this = shift;
	my $create = shift;

	$this->{create} = $create;
}

##
# @property $destroy boolean
#   A flag controlling whether the corresponding server-side object should be
#   destroyed when the session is terminated.
#
sub getDestroy
{
	my $this = shift;

	if (! defined($this->{destroy}))
	{
		return 0;
	}
	return $this->{destroy};
}

sub setDestroy
{
	my $this = shift;
	my $destroy = shift;

	$this->{destroy} = $destroy;
}

##
# @property $id string
#   The unique identifier assigned to the server-side object once it has been 
#   created.
#
sub getID
{
	my $this = shift;

	return $this->{id};
}

sub setID
{
	my $this = shift;
	my $id = shift;

	$this->{id} = $id;
}

##
# @property $language string
#   The language to be used in the server.
#
sub getLanguage
{
	my $this = shift;

	return $this->{language};
}

sub setLanguage
{
	my $this = shift;
	my $language = shift;

	$this->{language} = $language;
}

##
# @property $name string
#   The name of the server-side object to be created. 
#   This must be set before any object methods are called.
#
sub getName
{
	my $this = shift;

	return $this->{name};
}

sub setName
{
	my $this = shift;
	my $name = shift;

	$this->{name} = $name;
}

##
# @property $session IMu::Session
#   The `Session` object [$<link>(:session:session)] used by the handler to
#   communicate with the IMu server.
#
sub getSession
{
	my $this = shift;

	return $this->{session};
}

# Methods
#
##
# Calles a method on the server-side object.
#
# @param $method string
#   The name of the method to be called.
#
# @param $parameters mixed
#   Any parameters to be passed to the method. 
#   The **call( )** method uses Perl's reflection to determine the structure of 
#   the parameters to be transmitted to the server.
#
#   Parsing ``$parameters`` is optional.
#
# @returns mixed
#   An object containing the result returned by the server-side method.
#
# @throws IMu::Exception
#   If a server-side error occurred.
#
sub call
{
	my $this = shift;
	my $method = shift;
	my $params = shift;

	my $request = {};
	$request->{method} = $method;
	if (defined($params))
	{
		$request->{params} = $params;
	}
	my $response = $this->request($request);
	return $response->{result};
}

##
# Submits a low-level reque	st to the IMu server. 
# This method is chiefly used by the **call( )** method
# [$<link>(:handler:call)] above.
#
# @param $request mixed
#   An object containing the request parameters.
#
# @returns mixed
#   A variable containing the server response.
#
# @throws IMu::Exception
#   If a server-side error occurred.
#
sub request
{
	my $this = shift;
	my $request = shift;

	if (defined($this->{id}))
	{
		$request->{id} = $this->{id};
	}
	elsif (defined($this->{name}))
	{
		$request->{name} = $this->{name};
		if (defined($this->{create}))
		{
			$request->{create} = $this->{create};
		}
	}
	if (defined($this->{destroy}))
	{
		$request->{destroy} = $this->{destroy};
	}
	if (defined($this->{language}))
	{
		$request->{language} = $this->{language};
	}

	my $response = $this->{session}->request($request);

	if (exists($response->{id}))
	{
		$this->{id} = $response->{id};
	}

	return $response;
}

1;
