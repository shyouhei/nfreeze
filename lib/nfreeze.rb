#! /your/favourite/path/for/ruby
# -*- coding: utf-8; -*-
#
# Copyright(c) 2013 URABE, Shyouhei.
#
# Permission is hereby granted, free of  charge, to any person obtaining a copy
# of  this code, to  deal in  the code  without restriction,  including without
# limitation  the rights  to  use, copy,  modify,  merge, publish,  distribute,
# sublicense, and/or sell copies of the code, and to permit persons to whom the
# code is furnished to do so, subject to the following conditions:
#
#        The above copyright notice and this permission notice shall be
#        included in all copies or substantial portions of the code.
#
# THE  CODE IS  PROVIDED "AS  IS",  WITHOUT WARRANTY  OF ANY  KIND, EXPRESS  OR
# IMPLIED,  INCLUDING BUT  NOT LIMITED  TO THE  WARRANTIES  OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE  AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
# AUTHOR  OR  COPYRIGHT  HOLDER BE  LIABLE  FOR  ANY  CLAIM, DAMAGES  OR  OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF  OR IN CONNECTION WITH  THE CODE OR THE  USE OR OTHER  DEALINGS IN THE
# CODE.

require 'stringio'

# Adds two methods named nfreeze and thaw to Marshal module.
#
# @note  It is worth  mentioning that in spite of its being written using not a
#        little  knowledge of  both  perl internals  and  ruby internals,  this
#        library  contains  absolutely  0.00   octets  originates  from  either
#        projects (as of this writing, at  least).  So it is both perl-free and
#        ruby-free, in  the sense of  licensing.  You should strictly  stick to
#        the terms shown at the top of the source code.
#
# @note  Also, for future updates  of this library, do  not copy &  paste other
#        projects,  including  perl  and/or   ruby.   That  should  contaminate
#        licenses.
class << Marshal

   # Serialize the given object in a way compatible with perl.
   # @param  [Object] obj the target object
   # @return [String] a serialized version of obj.
   #
   # Not all kind of objects are serializable.  For instance Classes, which are
   # serializable  using Marshal.dump,  cannot  be serialized  by this  method,
   # because it makes no sense to have a class represented in Perl.
   def nfreeze obj
      NFREEZE.new.nfreeze obj
   end

   def thaw obj
      raise "TBW"
   end

   # @api private
   class NFREEZE
      def initialize
         buf   = "".encode(Encoding::ASCII_8BIT)
         @io   = StringIO.new buf
         @seen = Hash.new
      end

      def nfreeze obj
         @io.rewind
         @io.write "\x5\x8"
         recur obj
         return @io.string
      end

      def recur obj, refp = false
         # We  are not  implementing Torjan's  topological sort  algorithm here
         # because our  restriction is stronger  than just unable  to represent
         # infinite loops; we can only serlalize pure trees.
         if @seen.has_key? obj.object_id
            raise ArgumentError, "cyclic data structures not supportted for now"+
               obj.inspect
         else
            case obj when NilClass, Integer, String then
               # immediates
            else
               @seen.store obj.object_id, nil
            end
         end
         case obj
         when NilClass   then dump_nil
         when TrueClass  then dump_yes
         when FalseClass then dump_no
         when Integer    then dump_int    obj
         when Float      then dump_double obj
         when String     then dump_string obj
         when Array      then dump_ref if refp; dump_array obj
         when Hash       then dump_ref if refp; dump_hash  obj
         else
            raise ArgumentError, "unsupported class encountered: #{obj.inspect}"
         end
      end

      def dump_nil
         @io.write "\xe"
      end

      def dump_yes
         @io.write "\xf"
      end

      def dump_no
         @io.write "\x10"
      end

      def dump_ref
         @io.write "\x4"
      end

      def dump_array obj
         len = obj.length
         if len > 2147483647
            raise ArgumentError, "#{len} elems array is too big for perl"
         else
            @io.write [2, len].pack('cN')
            obj.each do |i|
               recur i, :ref
            end
         end
      end

      def dump_hash obj
         len = obj.keys.length
         if len > 2147483647
            raise ArgumentError, "#{len} elems hash is too big for perl"
         else
            @io.write [3, len].pack('cN')
            obj.each_pair do |k, v|
               case k when String then
                  len = k.bytesize
                  if len > 2147483647
                     raise ArgumentError, "#{len} octets key is too big for perl"
                  else
                     recur v, :ref
                     @io.write [len, k].pack('NA*')
                  end
               else
                  raise ArgumentError, "non-string keys cant be represented:"+
                     k.inspect
               end                  
            end
         end
      end

      def dump_double obj
         @io.write [7, obj].pack('cd')
      end

      def dump_int obj
         case obj when (-2147483648 ... 2147483648) then
            @io.write [9, obj].pack('cN')
         else
            raise ArgumentError, "#{obj.inspect} is too big for perl"
         end
      end

      def dump_string obj
         # Perl can only understand Unicodes
         newobj = obj.encode Encoding::UTF_8
         newlen = newobj.bytesize
         if newlen > 2147483647
            raise ArgumentError, "#{newlen} octets string is too big for perl"
         else
            @io.write [24, newlen, newobj].pack('cNA*')
         end
      end
   end
   private_constant:NFREEZE
end

# 
# Local Variables:
# mode: ruby
# coding: utf-8
# indent-tabs-mode: nil
# tab-width: 3
# ruby-indent-level: 3
# fill-column: 79
# default-justification: full
# End:
# vi:ts=3:sw=3:
