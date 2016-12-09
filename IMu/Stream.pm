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

package IMu::Stream;

use Encode;
use IO::File;

use IMu::Exception;
use IMu::Trace;

my $_blockSize = 8192;

# Static Properties
#
sub getBlockSize
{
	return $_blockSize;
}

sub setBlockSize
{
	my $size = shift;

	$_blockSize = $size;
}

# Constructor
#
sub new
{
	my $package = shift;
	my $socket = shift;

	my $this = bless({}, $package);

	$this->{socket} = $socket;

	$this->{input} = '';
	$this->{token} = undef;
	$this->{string} = undef;
	$this->{file} = undef;

	$this->{buffer} = '';
	$this->{length} = 0;

	return $this;
}

# Methods
#
sub get
{
	my $this = shift;

	my $what = undef;
	eval
	{
		$this->getInput();
		$this->getToken();
		$what = $this->getValue();
	};
	if ($@)
	{
		if (ref($@))
		{
			die $@;
		}
		die IMu::Exception->new('StreamGet', $@);
	}
	return $what;
}

sub put
{
	my $this = shift;
	my $what = shift;

	eval
	{
		$this->putValue($what, 0);
		$this->putLine();
		$this->putFlush();
	};
	if ($@)
	{
		if (ref($@))
		{
			die $@;
		}
		die IMu::Exception->new('StreamPut', $@);
	}
}

# Private
#
sub getValue
{
	my $this = shift;

	if ($this->{token} eq 'end')
	{
		return undef;
	}
	if ($this->{token} eq 'string')
	{
		return $this->{string};
	}
	if ($this->{token} eq 'number')
	{
		return $this->{string} + 0;
	}
	if ($this->{token} eq '{')
	{
		my $hash = {};
		$this->getToken();
		while ($this->{token} ne '}')
		{
			my $name;
			if ($this->{token} eq 'string')
			{
				$name = $this->{string};
			}
			elsif ($this->{token} eq 'identifier')
			{
				# Extension - allow simple identifiers
				$name = $this->{string};
			}
			else
			{
				die IMu::Exception->new('StreamSyntaxName', $this->{token});
			}

			$this->getToken();
			if ($this->{token} ne ':')
			{
				die IMu::Exception->new('StreamSyntaxColon', $this->{token});
			}

			$this->getToken();
			$hash->{$name} = $this->getValue();

			$this->getToken();
			if ($this->{token} eq ',')
			{
				$this->getToken();
			}
		}
		return $hash;
	}
	if ($this->{token} eq '[')
	{
		my $array = [];
		$this->getToken();
		while ($this->{token} ne ']')
		{
			push(@$array, $this->getValue());

			$this->getToken();
			if ($this->{token} eq ',')
			{
				$this->getToken();
			}
		}
		return $array;
	}
	if ($this->{token} eq 'true')
	{
		return 1;
	}
	if ($this->{token} eq 'false')
	{
		return 0;
	}
	if ($this->{token} eq 'null')
	{
		return undef;
	}
	if ($this->{token} eq 'binary')
	{
		return $this->{file};
	}

	die IMu::Exception->new('StreamSyntaxToken', $this->{token});
}

sub getToken
{
	my $this = shift;

	while ($this->{input} !~ s/^\s*(?=\S)//)
	{
		$this->getInput();
	}
	$this->{string} = undef;
	$this->{file} = undef;
	if ($this->{input} =~ s/^"//)
	{
		$this->{token} = 'string';
		$this->{string} = '';
		for (;;)
		{
			if ($this->{input} !~ s/^([^"\\]*)(["\\])//)
			{
				$this->{string} .= $this->{input};
				$this->getInput();
				next;
			}
			$this->{string} .= $1;
			if ($2 eq '"')
			{
				last;
			}
			if ($this->{input} =~ s/^"//)
			{
				$this->{string} .= '"';
			}
			elsif ($this->{input} =~ s/^\\//)
			{
				$this->{string} .= '\\';
			}
			elsif ($this->{input} =~ s/^\///)
			{
				$this->{string} .= '/';
			}
			elsif ($this->{input} =~ s/^b//)
			{
				$this->{string} .= "\b";
			}
			elsif ($this->{input} =~ s/^f//)
			{
				$this->{string} .= "\f";
			}
			elsif ($this->{input} =~ s/^n//)
			{
				$this->{string} .= "\n";
			}
			elsif ($this->{input} =~ s/^r//)
			{
				$this->{string} .= "\r";
			}
			elsif ($this->{input} =~ s/^t//)
			{
				$this->{string} .= "\t";
			}
			elsif ($this->{input} =~ s/^u([[:xdigit:]]{1,4})//)
			{
				$this->{string} .= chr($1);
			}
			else
			{
				die IMu::Exception->new('StreamSyntaxEscape', $this->{input});
			}
		}
	}
	elsif ($this->{input} =~ s/^(-?(\d+)(\.\d+)?([eE][-+]?\d+)?)//)
	{
		$this->{token} = 'number';
		$this->{string} = $1;
	}
	elsif ($this->{input} =~ s/^(\w+)//)
	{
		$this->{token} = 'identifier';
		$this->{string} = $1;
		my $lower = lc($this->{string});
		if ($lower eq 'false')
		{
			$this->{token} = 'false';
		}
		elsif ($lower eq 'null')
		{
			$this->{token} = 'null';
		}
		elsif ($lower eq 'true')
		{
			$this->{token} = 'true';
		}
	}
	elsif ($this->{input} =~ s/^\*(\d+)//)
	{
		# Extension - allow embedded binary data
		$this->{token} = 'binary';
		my $size = $1 + 0;

		# Save data into a temporary file
		my $temp = IO::File->new_tmpfile();
		my $left = $size;
		while ($left > 0)
		{
			my $read = $_blockSize;
			if ($read > $left)
			{
				$read = $left;
			}
			my $data = '';
			my $done = $this->{socket}->read($data, $read);
			if (! defined($done))
			{
				die IMu::Exception->new('StreamInput', $!);
			}
			if ($done == 0)
			{
				die IMu::Exception->new('StreamEOF', 'binary');
			}
			$temp->print($data);
			$left -= $done;
		}
		$temp->seek(0, SEEK_SET);
		$this->{file} = $temp;

		# Invalidate input buffer
		$this->{input} = '';
	}
	else
	{
		$this->{input} =~ s/^(.)//;
		$this->{token} = $1;
	}
	if (defined($this->{string}))
	{
        $this->{string} = Encode::decode_utf8($this->{string});
	}
}

sub getInput
{
	my $this = shift;

	my $input = $this->{socket}->getline();
	if (! defined($input))
	{
		die IMu::Exception->new('StreamEOF', 'line');
	}
	$this->{input} = $input;
}

sub putValue
{
	my $this = shift;
	my $what = shift;
	my $indent = shift;

	my $ref = ref($what);
	if (! defined($what))
	{
		$this->putText('null');
	}
	elsif ($ref eq '')
	{
		# Use magic to work out if a string or a number
		use B();
		my $object = B::svref_2object(\$what);
		my $flags = $object->FLAGS;
		if ($flags & B::SVf_IOK or $flags & B::SVp_IOK)
		{
			$this->putText($what);
		}
		elsif ($flags & B::SVf_NOK or $flags & B::SVp_NOK)
		{
			$this->putText(sprintf('%e', $what));
		}
		else
		{
			$this->putString($what);
		}
	}
	elsif ($ref eq 'HASH')
	{
		$this->putObject($what, $indent);
	}
	elsif ($ref eq 'ARRAY')
	{
		$this->putArray($what, $indent);
	}
	elsif ($ref eq 'GLOB' || $ref eq 'IO::File')
	{
		$this->putFile($what);
	}
	else
	{
		die IMu::Exception->new('StreamType', $ref);
	}
}

sub putString
{
	my $this = shift;
	my $what = shift;

	$this->putText('"');
	$what =~ s/\\/\\\\/g;
	$what =~ s/"/\\"/g;
	$this->putText($what);
	$this->putText('"');
}

sub putObject
{
	my $this = shift;
	my $what = shift;
	my $indent = shift;

	$this->putText('{');
	$this->putLine();
	my @names = keys(%$what);
	for (my $i = 0; $i < @names; $i++)
	{
		my $name = $names[$i];
		$this->putIndent($indent + 1);
		$this->putString($name);
		$this->putText(' : ');
		$this->putValue($what->{$name}, $indent + 1);
		if ($i < @names - 1)
		{
			$this->putText(',');
		}
		$this->putLine();
	}
	$this->putIndent($indent);
	$this->putText('}');
}

sub putArray
{
	my $this = shift;
	my $what = shift;
	my $indent = shift;

	$this->putText('[');
	$this->putLine();
	for (my $i = 0; $i < @$what; $i++)
	{
		$this->putIndent($indent + 1);
		$this->putValue($what->[$i], $indent + 1);
		if ($i < @$what - 1)
		{
			$this->putText(',');
		}
		$this->putLine();
	}
	$this->putIndent($indent);
	$this->putText(']');
}

sub putFile
{
	my $this = shift;
	my $what = shift;

	if (! seek($what, 0, 2))
	{
		die IMu::Exception->new('StreamFileSeek', $!);
	}
	my $size = tell($what);
	if (! seek($what, 0, 0))
	{
		die IMu::Exception->new('StreamFileSeek', $!);
	}

	$this->putText('*');
	$this->putText($size);
	$this->putLine();
#	$this->putFlush();

	my $left = $size;
	while ($left > 0)
	{
		my $need = $_blockSize;
		if ($need > $left)
		{
			$need = $left;
		}
		my $data = '';
		my $done = read($what, $data, $need);
		if (! defined($done))
		{
			die IMu::Exception->new('StreamFileRead', $!);
		}
		if ($done == 0)
		{
			last;
		}
		$this->putBytes($data);
		$left -= $done;
	}
	if ($left > 0)
	{
		# The file did not contain enough bytes
		# so the output is padded with nulls
		#
		while ($left > 0)
		{
			my $need = $_blockSize;
			if ($need > $left)
			{
				$need = $left;
			}
			my $data = chr(0) x $need;
			$this->putBytes($data);
			$left -= $need;
		}
	}
}

sub putIndent
{
	my $this = shift;
	my $indent = shift;

	if ($indent > 0)
	{
		$this->putText("\t" x $indent);
	}
}

sub putLine
{
	my $this = shift;

	$this->putText("\r\n");
}

sub putText
{
	my $this = shift;
	my $text = shift;

	my $bytes = Encode::encode_utf8($text);
	$this->putBytes($bytes);
}

sub putBytes
{
	my $this = shift;
	my $bytes = shift;

	$this->{buffer} .= $bytes;
	$this->{length} += length($bytes);
	if ($this->{length} >= $_blockSize)
	{
		$this->putFlush();
	}
}

sub putFlush
{
	my $this = shift;

	if ($this->{length} == 0)
	{
		return;
	}

	my $done = 0;
	my $left = $this->{length};
	while ($left > 0)
	{
		my $wrote = $this->{socket}->syswrite($this->{buffer}, $left, $done);
		if (! defined($wrote))
		{
			die IMu::Exception->new('StreamWriteError', $!);
		}
		if ($wrote == 0)
		{
			die IMu::Exception->new('StreamWriteError');
		}
		$done += $wrote;
		$left -= $wrote;
	}
	$this->{socket}->flush();
	$this->{buffer} = '';
	$this->{length} = 0;
}

1;
