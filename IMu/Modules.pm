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

package IMu::Modules;

use base 'IMu::Handler';
use IMu::Exception;
use IMu::Trace;

# Constructor
#
sub new
{
	my $package = shift;

	my $this = $package->SUPER::new(@_);

	$this->{name} = 'Modules';

	return $this;
}

# Methods
#
sub addFetchSet
{
	my $this = shift;
	my $name = shift;
	my $set = shift;

	my $args = {};
	$args->{name} = $name;
	$args->{set} = $set;
	return $this->call('addFetchSet', $args) + 0;
}

sub addFetchSets
{
	my $this = shift;
	my $sets = shift;

	return $this->call('addFetchSets', $sets) + 0;
}

sub addSearchAlias
{
	my $this = shift;
	my $name = shift;
	my $set = shift;

	my $args = {};
	$args->{name} = $name;
	$args->{set} = $set;
	return $this->call('addSearchAlias', $args) + 0;
}

sub addSearchAliases
{
	my $this = shift;
	my $aliases = shift;

	return $this->call('addSearchAliases', $aliases) + 0;
}

sub addSortSet
{
	my $this = shift;
	my $name = shift;
	my $set = shift;

	my $args = {};
	$args->{name} = $name;
	$args->{set} = $set;
	return $this->call('addSortSet', $args) + 0;
}

sub addSortSets
{
	my $this = shift;
	my $sets = shift;

	return $this->call('addSortSets', $sets) + 0;
}

sub fetch
{
	my $this = shift;
	my $flag = shift;
	my $offset = shift;
	my $count = shift;
	my $columns = shift;

	my $args = {};
	$args->{flag} = $flag;
	$args->{offset} = $offset;
	$args->{count} = $count;
	if (defined($columns))
	{
		$args->{columns} = $columns;
	}
	return $this->call('fetch', $args);
}

sub findAttachments
{
	my $this = shift;
	my $table = shift;
	my $column = shift;
	my $key = shift;

	my $args = {};
	$args->{table} = $table;
	$args->{column} = $column;
	$args->{key} = $key;
	return $this->call('findAttachments', $args);
}

sub findKeys
{
	my $this = shift;
	my $keys = shift;
	my $include = shift;

	my $args = {};
	$args->{keys} = $keys;
	if (defined($include))
	{
		$args->{include} = $include;
	}
	return $this->call('findKeys', $args);
}

sub findTerms
{
	my $this = shift;
	my $terms = shift;
	my $include = shift;

    if (ref($terms) eq 'IMu::Terms')
    {
        $terms = $terms->toArray();
    }
	my $args = {};
	$args->{terms} = $terms;
	if (defined($include))
	{
		$args->{include} = $include;
	}
	return $this->call('findTerms', $args);
}

sub getHits
{
	my $this = shift;
	my $module = shift;

	return $this->call('getHits', $module) + 0;
}

sub restoreFromFile
{
	my $this = shift;
	my $file = shift;
	my $module = shift;

	my $args = {};
	$args->{file} = $file;
	if (defined($module))
	{
		$args->{module} = $module;
	}
	return $this->call('restoreFromFile', $args) + 0;
}

sub restoreFromTemp
{
	my $this = shift;
	my $file = shift;
	my $module = shift;

	my $args = {};
	$args->{file} = $file;
	if (defined($module))
	{
		$args->{module} = $module;
	}
	return $this->call('restoreFromTemp', $args) + 0;
}

sub setModules
{
	my $this = shift;
	my $list = shift;

	return $this->call('setModules', $list) + 0;
}

sub sort
{
	my $this = shift;
	my $set = shift;
	my $flags = shift;

	my $args = {};
	$args->{set} = $set;
	if (defined($flags))
	{
		$args->{flags} = $flags;
	}
	return $this->call('sort', $args);
}

1;
