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

package IMu::Trace;

use Data::Dumper;
use Fcntl ':flock';
use IO::File;

BEGIN
{
	$Data::Dumper::Indent = 1;
}

my $_file = 'STDOUT';
my $_handle = IO::Handle->new_from_fd(fileno(STDOUT), 'w');
my $_level = 1;
my $_prefix = '%D %T: ';

sub getFile
{
	return $_file;
}

sub setFile
{
	my $file = shift;

	$_file = $file;

	if (defined($_handle) && $_handle->fileno() != fileno(STDOUT))
	{
		$_handle->close();
	}

	if (! defined($_file) || $file eq '')
	{
		$_file = '';
		$_handle = undef;
	}
	elsif ($_file eq 'STDOUT')
	{
		$_handle = IO::Handle->new_from_fd(fileno(STDOUT), 'w');
	}
	else
	{
		$_handle = IO::File->new($_file, 'a');
		if (! defined($_handle))
		{
			$_file = '';
			$_handle = undef;
		}
	}
}

sub getLevel
{
	return $_level;
}

sub setLevel
{
	my $level = shift;

	$_level = $level;
}

sub getPrefix
{
	return $_prefix;
}

sub setPrefix
{
	my $prefix = shift;

	$_prefix = $prefix;
}

sub write
{
	my $level = shift;
	my $format = shift;

	if (! defined($_handle))
	{
		return;
	}
	if ($level > $_level)
	{
		return;
	}

	# time
	my @now = localtime();
	my $y = $now[5] + 1900;
	my $m = sprintf('%02d', $now[4] + 1);
	my $d = sprintf('%02d', $now[3]);
	my $D = $y . '-' . $m . '-' . $d;

	my $H = sprintf('%02d', $now[2]);
	my $M = sprintf('%02d', $now[1]);
	my $S = sprintf('%02d', $now[0]);
	my $T = $H . '-' . $M . '-' . $S;

	# process id
	my $p = $$;

	# function information
	my $F = '(unknown)';
	my $L = '(unknown)';
	my $f = '(none)';
	my $g = '(none)';
	for (my $i = 0; ; $i++)
	{
		my @frame = caller($i);
		if (@frame == 0)
		{
			last;
		}
		if ($frame[1] ne __FILE__)
		{
			$F = $frame[1];
			$L = $frame[2];
			@frame = caller($i + 1);
			if (@frame != 0)
			{
				$f = $frame[3];
				$g = $f;
				$g =~ s/^IMu:://;
			}
			last;
		}
	}

	# Build the prefix
	my $prefix = $_prefix;

	$prefix =~ s/%y/$y/g;
	$prefix =~ s/%m/$m/g;
	$prefix =~ s/%d/$d/g;
	$prefix =~ s/%D/$D/g;

	$prefix =~ s/%H/$H/g;
	$prefix =~ s/%M/$M/g;
	$prefix =~ s/%S/$S/g;
	$prefix =~ s/%T/$T/g;

	$prefix =~ s/%l/$level/g;

	$prefix =~ s/%p/$p/g;

	$prefix =~ s/%F/$F/g;
	$prefix =~ s/%L/$L/g;
	$prefix =~ s/%f/$f/g;
	$prefix =~ s/%g/$g/g;

	# Build the string
	my @strs = ();
	foreach my $arg (@_)
	{
		my $str;
		if (! defined($arg))
		{
			$str = '(undef)';
		}
		elsif (ref($arg))
		{
			$str = Dumper($arg);
			$str =~ s/^\$VAR1 = /\n/;
			$str =~ s/;\s+$//;
		}
		else
		{
			$str = $arg;
		}
		push(@strs, $str);
	}
	$format = "$format";
	if (@strs > 0)
	{
		$format = sprintf($format, @strs);
	}
	my $text = $prefix . $format;
	$text =~ s/\s+$//;
	$text .= "\n";

	# Write it out
	if ($_handle->fileno() != fileno(STDOUT))
	{
		# Lock
		if (! flock($_handle, LOCK_EX))
		{
			return;
		}
		if (! $_handle->seek(0, SEEK_END))
		{
			flock($_handle, LOCK_UN);
			return;
		}
	}
	$_handle->print($text);
	if ($_handle->fileno() != fileno(STDOUT))
	{
		flock($_handle, LOCK_UN);
	}
}

1;
