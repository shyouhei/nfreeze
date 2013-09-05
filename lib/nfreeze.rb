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
   # @raise  [ArgumentError] the obj is not serializable using this method.
   #
   # Not all kind of objects are serializable.  For instance Classes, which are
   # serializable  using Marshal.dump,  cannot  be serialized  by this  method,
   # because it makes no sense to have a class represented in Perl.
   #
   # Also for  the sake  of simple implementation  this method  pays relatively
   # little attention  to make the  generated binary smaller.  There  are cases
   # where more  compact expressions is  possible.  All generated  binaries are
   # properly understood by perl though.
   def nfreeze obj
      NFREEZE.new.nfreeze obj
   end

   # Deserialize perl-generated nfreeze strings into ruby objects.
   # @param  [IO, String] obj the source
   # @return [Object] deserialized object
   # @raise  [TypeError] the obj is not deserializable
   #
   # Not all kind of inputs are understood.  One big issue is a reference -- in
   # perl a [] and a \\[] are  different, but in ruby you cannot represent such
   # difference.
   #
   # In practice  you would better think  this method can understand  as far as
   # JSON or YAML or MessagePack or that sort.
   def thaw obj
      THAW.new.thaw obj
   end

   class NFREEZE
      def nfreeze obj
         @io.rewind
         @io.write "\x5\x8"
         recur obj
         return @io.string
      end

      private

      def initialize
         buf   = "".encode Encoding::BINARY
         @io   = StringIO.new buf
         @seen = Hash.new
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
         when NilClass   then dump 14
         when TrueClass  then dump 15
         when FalseClass then dump 16
         when Integer    then dump_int    obj
         when Float      then dump_double obj
         when String     then dump_string obj
         when Array      then dump 4 if refp; dump_array obj
         when Hash       then dump 4 if refp; dump_hash  obj
         else
            raise ArgumentError, "unsupported class encountered: #{obj.inspect}"
         end
      end

      def dump x
         @io.write x.chr
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

   class THAW
      def thaw obj
         @io = (obj.to_io rescue StringIO.new(obj.to_str))
         version_check
         recur
      end

      private

      def initialize
         @io   = nil # assigned later
         @seen = Hash.new
      end

      def version_check
         str = @io.read 2
         x, minor = str.unpack 'cc'
         netorder = x & 1
         major    = x >> 1
         if major != 2 or minor <= 6
            raise "unsupported version #{major}.#{minor}"
         elsif netorder != 1
            raise "machine-endian unpredictalbe for this input"
         end
      end

      @@e = Exception.new

      def recur
         case type = @io.getbyte
         when 0x01 then load_binary_large
         when 0x02 then load_array
         when 0x03 then load_hash
         when 0x04 then raise @@e # this is ref
         when 0x05 then nil
         when 0x06 then raise "Endian mismatch" # machine-natives
         when 0x07 then load_double
         when 0x08 then load_byte
         when 0x09 then load_int
         when 0x0a then load_binary_tiny
         # some cases here...
         when 0x0e then nil
         when 0x0f then true
         when 0x10 then false
         # some cases here...
         when 0x17 then load_string_tiny
         when 0x18 then load_string_large
         else raise TypeError, "can't understand type ##{type}"
         end
      rescue Exception => e
         if e == @@e
            retry # ignore refs
         else
            raise
         end
      end

      def load_byte
         @io.getbyte - 128
      end

      def load_int
         str = @io.read 4
         len, = str.unpack 'N'
         len
      end

      def load_binary len
         raise "broken #{len}" if len < 0
         str = @io.read len
         str.force_encoding Encoding::BINARY
         str
      end

      def load_binary_large
         load_binary load_int
      end

      def load_binary_tiny
         load_binary load_byte + 128
      end

      def load_string len
         raise "broken #{len}" if len < 0
         str = @io.read len
         str.force_encoding Encoding::UTF_8
         str
      end

      def load_string_large
         load_string load_int
      end

      def load_string_tiny
         load_string load_byte + 128
      end

      def load_array
         load_int.times.map { recur }
      end

      def load_hash
         load_int.times.each_with_object Hash.new do |i, ret|
            # order matters
            v = recur
            k = load_binary_large
            ret.store k, v
         end
      end
   end
   private_constant:THAW
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
