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
# Provides access to an EMu module.
#
# @extends IMu.Handler
#
# @usage
#   use IMu::Module;
# @end
#
# @since 1.0
#
package IMu::Module;

use base 'IMu::Handler';
use IMu::Exception;
use IMu::Trace;

# Constructor
#
##
# Creates an onject which can be used to access the EMu module specified
# by ``$table``.
#
# If the ``$session`` parameter is ``undef`` a new session is created
# automatically using the `IMu::Session` [$<link>(:session:session)] class's 
# **defaultHost** [$<link>(:session:defaultHost)] and **defaultPort** 
# [$<link>(:session:defaultPort)] values.
#
# @param $table string
#   Name of the EMu module to be accessed.
#
# @param $session IMu::Session 
#   A `Session` object [$<link>(:session:session)] to be used to communicate
#   with the IMu server.
#
sub new
{
	my $package = shift;
	my $table = shift;
	my $session = @_ ? shift : undef;

	my $this = $package->SUPER::new($session);

	$this->{name} = 'Module';
	$this->{create} = $table;

	$this->{table} = $table;

	return $this;
}

# Properties
#
##
# @property $table string
#   The name of the table associated with the `IMu::Module` object
#   [$<link>(:module:module)].
#
sub getTable
{
	my $this = shift;

	return $this->{table};
}

# Methods
#
##
# Associates a set of columns with a logical name in the server.
#
# The name can be used instead of a column list when retrieving data
# using **fetch( )** [$<link>(:module:fetch)].
#
# @param $name string
#   The logical name to associate with the set of columns.
#
# @param $columns mixed
#   A `string` or an array of `string`\s containing the names of the columns to
#   be used when $name is passed to **fetch( )** [$<link>(:module:fetch)].
#  
#  Each `string` can contain one or more column names, separated by a 
#  ``semi-colon`` or a ``comma``.
#
# @returns int
#   The number of sets (including this one) registered in the server.
#
# @throws IMuException
#   A server-side error occurred.
#
sub addFetchSet
{
	my $this = shift;
	my $name = shift;
	my $columns = shift;

	my $args = {};
	$args->{name} = $name;
	$args->{columns} = $columns;
	return $this->call('addFetchSet', $args) + 0;
}

##
# Associates several sets of columns with logical names in the server. 
#
# This is the equivalent of calling **addFetchSet( )** 
# [$<link>(:module:addFetchSet)] for each entry in the map but is more efficient.
#
# @param $sets string
#   A `hash` reference containing mappings between names and sets of columns.
#
# @returns int
#   The number of sets (including these ones) registered in the server.
#
# @throws IMu::Exception
#   If a server-side error occurred.
#
sub addFetchSets
{
	my $this = shift;
	my $sets = shift;

	return $this->call('addFetchSets', $sets) + 0;
}

##
# Associates a set of columns with a logical name in the server. 
#
# The name can be used when specifying search terms to be passed to 
# **findTerms( )** [$<link>(:module:findTerms)].
# The search becomes the equivalent of an ``OR`` search involving the columns.
#
# @param $name string
#   The logical name to associate with the set of columns.
#
# @param $columns mixed
#   A `string` or reference to an array of `string`\s containing the names of 
#   the columns to be used when ``$name`` is passed to **findTerms( )**
#   [$<link>(:module:findTerms)].
#
#   Each `string` can contain one or more column names, separated by a 
#   ``semi-colon`` or a ``comma``.
#
# @returns int
#   The number of aliases (including this one) registered in the server.
#
# @throws IMu::Exception
#   If a server-side error occurred.
#
sub addSearchAlias
{
	my $this = shift;
	my $name = shift;
	my $columns = shift;

	my $args = {};
	$args->{name} = $name;
	$args->{columns} = $columns;
	return $this->call('addSearchAlias', $args) + 0;
}

## 
# Associates several sets of columns with logical names in the server. 
#
# This is the equivalent of calling **addSearchAlias( )**
# [$<link>(:module:addSearchAlias)] for each entry in the map but is more 
# efficient.
#
# @param $aliases hash
#   A `hash` reference containing a set of mappings between a name and a set of 
#   columns.
#
# @returns int
#   The number of sets (including these ones) registered in the server.
#
# @throws IMu::Exception
#   If a server-side error occurred.
#
sub addSearchAliases
{
	my $this = shift;
	my $aliases = shift;

	return $this->call('addSearchAliases', $aliases) + 0;
}

##
# Accociates a set of sort keys with a logical name in the server. 
#
# The name can be used instead of a sort key list when sorting the current 
# result set using **sort( )** [$<link>(:module:sort)].
#
# @param $name string
#   The logical name to associate with the set of columns.
#
# @param $keys mixed
#   A `string` or a reference to an array of `string`\s containing the names of 
#   the keys to be used when ``$name`` is passed to **sort( )**
#   [$<link>(:module:sort)].
#
# @returns int
#   The number of sets (including this one) registered in the server.
#
# @throws IMu::Exception
#   If a server-side error occurred.
#
sub addSortSet
{
	my $this = shift;
	my $name = shift;
	my $columns = shift;

	my $args = {};
	$args->{name} = $name;
	$args->{columns} = $columns;
	return $this->call('addSortSet', $args) + 0;
}

##
# Associates several sets of sort keys with logical names in the server. 
#
# This is the equivalent of calling **addSortSet( )** [$<link>(:module:addSortSet)]
# for each entry in the map but is more efficient.
#
# @param $sets hash
#   A `hash` reference containing a set of mappings between a name and a set of 
#   keys.
#
# @returns int
#   The number of sets (including these ones) registered in the server.
#
# @throws IMu::Exception
#   If a server-side error occurred.
#
sub addSortSets
{
	my $this = shift;
	my $sets = shift;

	return $this->call('addSortSets', $sets) + 0;
}

##
# Fetches ``$count`` records from the position described by a combination of 
# ``$flag`` and ``$offset``.
#
# @param $flag string
#   The Position to start fetching records from. 
#   Must be one of:
#     ``start``
#     ``current``
#     ``end``
#
# @param $offset int
#   The position relative to ``$flag`` to start fetching from.
#
# @param $count int
#   The number of records to fetch. 
#   A ``$count`` of ``0`` is permitted to change the location of the current 
#   record without returning any results. 
#   A ``$count`` of less than ``0`` causes all the remaining records in the 
#   result set to be returned.
#
# @param $columns mixed
#   A `string` or a reference to an array of `string`\s containing the names 
#   of the columns to be returned for each record or the name of a column set 
#   which has been registered previously using **addFetchSet( )** 
#   [$<link>(:module:addFetchSet)].
#   Each `string` can contain one or more column names, separated by a 
#   ``semi-colon`` or a ``comma``.
#
#   If this parameter is not supplied, no column data is returned. 
#   The results will still include the pseudo-column ``rownum`` for each fetched
#   record.
#
# @returns hash
#   A `hash` reference
#
# @throws IMu::Exception
#   If a server-side error occurred.
#
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

sub fetchHierarchy
{
	my $this = shift;
	my $key = shift;
	my $parent = shift;
	my $options = shift;

	my $args = {};
	$args->{key} = $key;
	$args->{parent} = $parent;
	if (defined($options))
	{
		$args->{options} = $options;
	}
	return $this->call('fetchHierarchy', $args);
}

##
# Searches for a record with the key value ``$key``.
#
# @param $key int
#   The key of the record being searched for.
#
# @returns int
#   The number of records found. 
#   This will be either ``1`` if the record was found or ``0`` if not found.
#
# @throws IMu::Exception
#   If a server-side error occurred.
#
sub findKey
{
	my $this = shift;
	my $key = shift;

	return $this->call('findKey', $key) + 0;
}

##
# Searches for records with key values in the array ``keys``.
#
# @param $keys array ref
#   A reference to the array of keys being searched for.
#
# @returns int
#   The number of records found.
#
# @throws IMu::Exception
#   If a server-side error occurred.
#   
sub findKeys
{
	my $this = shift;
	my $keys = shift;

	return $this->call('findKeys', $keys) + 0;
}

##
# Searches for records which match the search terms specified in ``$terms``.
#
# @param $terms array
#   The search terms. 
#   The terms are specified using an array reference. 
#   Each term is itself an array reference of `string`\s.
#
# @throws IMu::Exception
#   If a server-side error occurred.
#
sub findTerms
{
	my $this = shift;
	my $terms = shift;

    if (ref($terms) eq 'IMu::Terms')
    {
        $terms = $terms->toArray();
    }
	return $this->call('findTerms', $terms) + 0;
}

##
# Searches for records which match the TexQL ``WHERE`` clause.
#
# @param $where string
#   The TexQL ``WHERE`` clause to use.
#
# @returns int
#   An estimate of the number of records found.
#
# @throws IMu::Exception
#   If a server-side error occurred.
#
sub findWhere
{
	my $this = shift;
	my $where = shift;

	return $this->call('findWhere', $where) + 0;
}

sub insert
{
	my $this = shift;
	my $values = shift;
	my $columns = shift;

	my $args = {};
	$args->{values} = $values;
	if (defined($columns))
	{
		$args->{columns} = $columns;
	}
	return $this->call('insert', $args);
}

sub remove
{
	my $this = shift;
	my $flag = shift;
	my $offset = shift;
	my $count = shift;

	my $args = {};
	$args->{flag} = $flag;
	$args->{offset} = $offset;
	if (defined($count))
	{
		$args->{count} = $count;
	}
	return $this->call('remove', $args);
}

##
# Restores a set of records from a file on the server machine which contains
# a list of keys, one per line.
#
# @param $file string
#   The file on the server machine containing the keys.
#
# @returns int
#   The number of records found.
#
# @throws IMu::Exception
#   If a server-side error occurred.
#
sub restoreFromFile
{
	my $this = shift;
	my $file = shift;

	my $args = {};
	$args->{file} = $file;
	return $this->call('restoreFromFile', $args) + 0;
}

##
# Restores a set of records from a temporary file on the server machine while
# contains a list of keys, one per line. 
# Operates the same way as **restoreFromFile( )** [$<link>(:module:restoreFromFile)]
# except that the $file parameter is relative to te server's temporary directory.
#
# @param $file string
#   The file on the server machine containing the keys.
#
# @returns int
#   The number of records found.
#
# @throws IMu::Exception
#   If a server-side error occurred.
#
sub restoreFromTemp
{
	my $this = shift;
	my $file = shift;

	my $args = {};
	$args->{file} = $file;
	return $this->call('restoreFromTemp', $args) + 0;
}

##
# Sorts the current result set by the sort keys in ``$keys``.
# Each sort is a column name optionally preceded by a ``+`` (for an ascending 
# sort) or a ``-`` (for a descending sort).
#
# @param $keys mixed
#   A `string` or reference to an array of `string`\s containing the list of 
#   sort keys.
#   Each `string` can contain one or more keys, separated by a ``semi-colon`` or
#   a ``comma``.
#
# @param $flags mixed
#   A `string` or reference to an array of `string`\s containing a set of flags 
#   specifying the behaviour of the sort. 
#   Each `string` can contain one or more flags, separated by a ``semi-colon`` 
#   or a ``comma``.
#
#   @returns mixed
#     An array reference containing the report information if the ``report`` 
#     flag has been specified. Otherwise the result will be ``undef``.
#
#   @throws IMu::Exception
#     If a server-side error occurred.
#
sub sort
{
	my $this = shift;
	my $columns = shift;
	my $flags = shift;

	my $args = {};
	$args->{columns} = $columns;
	if (defined($flags))
	{
		$args->{flags} = $flags;
	}
	return $this->call('sort', $args);
}

sub update
{
	my $this = shift;
	my $flag = shift;
	my $offset = shift;
	my $count = shift;
	my $values = shift;
	my $columns = shift;

	my $args = {};
	$args->{flag} = $flag;
	$args->{offset} = $offset;
	$args->{count} = $count;
	$args->{values} = $values;
	if (defined($columns))
	{
		$args->{columns} = $columns;
	}
	return $this->call('update', $args);
}

1;
