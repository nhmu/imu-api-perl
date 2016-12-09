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
# This class is used to create a set of search terms that is passed to the 
# IMu server.
#
# A `Terms` object can be passed to the **findTerms( )** 
# [$<link>(:module:findTerms)] method of either a `IMu::Module`
# [$<link>(:module:module)] or `IMu::Modules` object.
#
# @usage
#   use IMu::Terms
# @end
#
# @since 2.0
#
package IMu::Terms;

use overload ('""' => 'toString');

# Constructor
#
###
# @param $kind string
#   The `boolean` operator for search terms.
#
sub new
{
    my $package = shift;
    my $kind = shift;

    if (! defined($kind))
    {
        $kind = 'and';
    }
    $kind = lc($kind);
    if ($kind ne 'and' && $kind ne 'or')
    {
        die("Illegal kind: $kind\n");
    }
    my $this = bless({}, $package);
    $this->{'kind'} = $kind;
    $this->{'list'} = [];
    return($this);
}

# Properties
#
## 
# @property $kind string
#   Gets the ``kind`` property.
# 
sub getKind
{
    my $this = shift;

    return($this->{'kind'});
}

##
# @property $list mixed
#   Gets the ``list`` property.
# 
sub getList
{
    my $this = shift;

    return($this->{'list'});
}

# Methods
#
##
# Adds a new term to the list.
#
# Omitting ``$op`` is the preferred method for adding terms in many cases as it
# allows the server to choose the most suitable operator.
#
# @param $name string
#   The name of a column or search alias.
#
# @param $value string
#   The value to match.
#
# @param $op string ['matches']
#   An operator (such as ``contains``, ``=``, ``<``, etc.) for the 
#   server to apply when searching.
# 
sub add
{
    my $this = shift;
    my $name = shift;
    my $value = shift;
    my $op = shift;

    my $term = [$name, $value, $op];
    push(@{$this->{'list'}}, $term);
}

## 
# Adds an initially empty nested set of terms to the list.
#
# @param $kind string
#   The ``boolean`` operator to use for search terms added to the
#   returned `IMu::Terms` object.
#   
# @returns IMu::Terms 
#   The newly added `IMu::Terms` object.
## 
sub addTerms
{
    my $this = shift;
    my $kind = shift;

    my $child = IMu::Terms->new($kind);
    push(@{$this->{'list'}}, $child);
    return($child);
}

## 
# Adds an initially empty nested set of AND terms to the list.
#
# Equivalent to:
# @code{.pl}
#	addTerms('and');
# @endcode
#
# @returns IMu::Terms 
#   The newly added `IMu::Terms` object.
## 
sub addAnd
{
    my $this = shift;

    return($this->addTerms('and'));
}

## 
# Adds an initially empty nested set of ``OR`` terms to the list.
# 
# Equivalent to:
# @code{.pl}
#	addTerms('or');
# @endcode
#
# @returns IMu::Terms
#   The newly added `IMu::Terms` object.
## 
sub addOr
{
    my $this = shift;

    return($this->addTerms('or'));
}

## 
# Returns the `IMu::Terms` object as a reference to an array.
#
# @returns [] 
#   The `IMu::Terms` object as an array.
## 
sub toArray
{
    my $this = shift;

    my $result = [];
    $result->[0] = $this->{'kind'};

    my $list = [];
    for (my $i = 0; $i < @{$this->{'list'}}; $i++)
    {
        my $term = $this->{'list'}->[$i];
        if (ref($term) eq 'IMu::Terms')
        {
            $term = $term->toArray();
        }
        $list->[$i] = $term;
    }
    $result->[1] = $list;

    return($result);
}

## 
# Returns a `string` representation of the `IMu::Terms` object.
#
# @returns string 
#   A `string` representation of the `IMu::Terms` object.
# 
sub 
toString
{
    my $this = shift;

    my $result = '[';
    $result .= $this->{'kind'};
    $result .= ', [';
    for (my $i = 0; $i < @{$this->{'list'}}; $i++)
    {
        if ($i > 0)
        {
            $result .= ', ';
        }    
        my $term = $this->{'list'}->[$i];
        if (ref($term) eq 'IMu::Terms')
        {
            $term = $term->toString();
        }
        else
        {
            $term = '[' . join(', ', @$term) . ']';
        }
        $result .= $term;
    }
    $result .= ']]';
    return($result);
}

1;
