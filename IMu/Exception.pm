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
# Class for IMu-specific exceptions.
#
# @useage
#   use IMu::Exception;
# @end
#
# @since 1.0
#
package IMu::Exception;

use overload ('""' => 'toString');

use IMu::Trace;

# Constructor
#
##
# Creates an IMu specific exception.
#
# @param $id string
#   A `string` exception code.
#
# @param $args mixed
#   Any additional arguments used to provide further information about the 
#   exception.
#
sub new
{
	my $package = shift;
	my $id = shift;

	my $this = bless({}, $package);
	$this->{id} = $id;
	$this->{args} = [ @_ ];
	IMu::Trace::write(2, 'exception %s', $this->toString());
	return $this;
}

# Properties
#
##
# @property $args mixed
#   The set of arguments associated with the exception.
#
sub getArgs
{
	my $this = shift;

	return $this->{args};
}

sub setArgs
{
	my $this = shift;
	my $args = shift;

	$this->{args} = $args;
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

# Methods
#
##
# Used to override the standard Perl "" (stringify) operator.
#
# @returns string
#   A `string` description of the exception.
#
sub toString
{
	my $this = shift;

	my $str = $this->{id};
	if (defined($this->{args}) && @{$this->{args}} > 0)
	{
		$str .= ' (' . join(',', @{$this->{args}}) . ')';
	}
	return $str;
}

1;
