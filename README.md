# nfreeze: a Ruby translation of p5-Storable

This is a very limited version of Storable of perl 5, written in Ruby.

## Needs of this library

I happen to encounter a Memcached cluster whose main users are Perl programs.

Perl's memcache client use Storable to serialize/deserialize structures so the cluser is full of strings in that format.

In order to smoothly migrate into Ruby I have to use that cluster as-is.  My program had to understand that thing.  So this library.


## How to use

This library adds 2 methods, `nfreeze` and `thaw`, to `Marshal`.  `nfreeze` is much like `Marshal.dump`, while `thaw` is like `Marshal.load`; the format is different form Ruby's though.


## Limitations

  * Not every strings that Perl generats can be understood by us.
      * For instance we theoretically cant deserialize a Perl OOP class.
      * Perl strings that are not network portable are also not supported.
  * Poorly tested.
      * You need a working perl to test this library and that's a pain for me.
        I have relatively few motivation to test this.
  * Slow.  It is in pure-Ruby.
