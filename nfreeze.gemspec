#! /your/favourite/path/for/gem
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

require 'rubygems'

Gem::Specification.new do |gem|
   gem.required_ruby_version = '>= 1.9.3'
   gem.name                  = 'nfreeze'
   gem.version               = '0.0.3'
   gem.author                = 'Urabe, Shyouhei'
   gem.homepage              = 'https://github.com/shyouhei/nfreeze'
   gem.license               = 'MIT'
   gem.executables           = [ ] # not yet
   gem.files                 = Dir.glob ['lib/**/*.rb', 'README']
   gem.summary               = <<-end.chomp.sub /^\s+/, ''
		Ruby translation of p5-Storable
   end
   gem.description           = <<-end.chomp.sub /^\s+/, ''
		Adds two  methods, thaw and  nfreeze, into  Marshal module, so  that your
		program can understand Perl-generated nfreeze strings.
   end

   gem.add_development_dependency 'yard'
   gem.add_development_dependency 'rdoc'
   gem.add_development_dependency 'rspec'
   gem.add_development_dependency 'simplecov'
   gem.add_development_dependency 'pry'
   gem.add_development_dependency 'rake'
   gem.add_development_dependency 'bundler'
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
