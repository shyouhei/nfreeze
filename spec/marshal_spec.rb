#! /your/favourite/path/for/rspec
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

require_relative 'spec_helper'
require 'tempfile'

describe Marshal do
   before:suite do
      # check perl existance
      ret = system %w"perl", '-MStorable', '-e',
         'print Storable::nfreeze(\undef);',
         %i"out err" => :close

      pending "no perl" unless ret
   end

   describe ".nfreeze" do
      it "takes one arg" do
         expect { Marshal.nfreeze }.to raise_exception(ArgumentError)
      end

      context "generates something understandable by perl" do
         file = nil
         before:all do
            file = Tempfile.new ''
            file.rewind
            file.write <<-'};'
               use Storable ();
               use Data::Dumper ();
               $Data::Dumper::Indent = 0;
               $Data::Dumper::Terse = 1;
               $Data::Dumper::Useqq = 1;
               $str = ""; while(<>){$str.=$_};
               $obj = Storable::thaw($str);
               print Data::Dumper::Dumper($obj);
            };
            file.close(false) # flush
         end

         [ # Ruby data vs. Perl data
          [ nil         , "\\undef"             ],
          [ 1           , "\\1"                 ],
          [ -1          , "\\-1"                ],
          [ 128         , "\\128"               ],
          [ -128        , "\\-128"              ],
          [ -129        , "\\-129"              ],
          [ 1.0         , "\\1"                 ],
          [ 1.5         , '\\"1.5"'             ],
          [ ""          , '\\""'                ],
          [ "\0"        , '\\"\\0"'             ],
          [ "a"         , '\\"a"'               ],
          [ "\u3042"    , '\\"\\x{3042}"'       ],
          [ []          , "[]"                  ],
          [ [[]]        , "[[]]"                ],
          [ [{}]        , "[{}]"                ],
          [ [nil]       , "[undef]"             ],
          [ [true]      , "[1]"                 ],
          [ [false]     , '[""]'                ],
          [ [1]         , "[1]"                 ],
          [ [1.5]       , '["1.5"]'             ],
          [ [1.5, "あ"] , '["1.5","\\x{3042}"]' ],
          [ {}          , "{}"                  ],
          [ {"1"=>1}    , "{1 => 1}"            ],
          [ {"1"=>[]}   , "{1 => []}"           ],
          [ {"1"=>""}   , '{1 => ""}'           ],
          [ {"1"=>{}}   , '{1 => {}}'           ],
         ].each do |ruby, perl|

            it "for #{ruby.inspect}" do
               IO.popen ['perl', file.path], "r+" do |fp|
                  serialized = Marshal.nfreeze ruby
                  fp.puts serialized
                  fp.close_write
                  deserialized = fp.read
                  expect(deserialized).to eq(perl)
               end
            end

         end

         it "for a complex structure" do
            ruby = {
               'production' => {
                  'servers' => [
                    'localhost', 'example.com'
                  ],
                  'ports' => [
                    65535, 65534
                  ]
               },
               'staging' => {
                  'server' => 'localhost',
                  'port'   => 65535,
               },
               'sandbox' => {
                  'server' => 'localhost',
                  'port'   => 65535,
               },
            }
            IO.popen ['perl', file.path], "r+" do |fp|
               serialized = Marshal.nfreeze ruby
               fp.puts serialized
               fp.close_write
               deserialized = fp.read
               expect(deserialized).to_not eq("undef")
            end
         end
      end
   end

   describe ".thaw" do
   end
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
