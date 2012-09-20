# QuickGem

QuickGem speeds up RubyGems loading by monkey-patching.

**NOTE:** This is just one big hack. A proper solution requires patches across
many Ruby projects (most notably RubyGems and Bundler). I'm considering do it
proerly, but for now an ugly hack works fine for me.

I've seen rougly 4 times faster startup time, but I have roughly ~250
different gems and numerous versions installed. You won't notice much if you
have few gems installed.

`rails -v` finally feels snappy as I managed to get it under 100ms:

    # Outside a Rails 3 project, without QuickGem:
    $ time rails -v
    Rails 3.2.6

    real    0m0.314s
    user    0m0.293s
    sys     0m0.019s

    # with QuickGem:
    $ time rails -v
    Rails 3.2.6

    real    0m0.077s
    user    0m0.067s
    sys     0m0.008s

`rails -v` inside a Rails project loads Bundler which makes it about 300ms. Not
snappy, but still 4 times faster than before:

    # Inside a Rails 3 project, without QuickGem:
    $ time rails -v
    Rails 3.2.6

    real	  0m1.379s
    user	  0m1.023s
    sys	    0m0.104s

    # with QuickGem
    $ time rails -v
    Rails 3.2.6

    real	  0m0.322s
    user	  0m0.291s
    sys	    0m0.028s

`heroku` is faster too. Going from ~1.7s to ~0.4s makes a notable difference:

    # Without:
    $ time heroku version
    heroku-gem/2.11.1

    real	  0m0.410s
    user	  0m0.367s
    sys	    0m0.035s

    # With:
    $ time heroku version
    heroku-gem/2.11.1

    real	  0m1.788s
    user	  0m1.665s
    sys	    0m0.101s

## Installation

    $ git clone http://github.com/judofyr/quickgem.git
    $ cd quickgem

    # Build initial cache
    $ ruby quickgem.rb

    # Then put this in bashrc:
    export RUBYOPT="-r/full/path/to/quickgem/quickgem.rb"

## Configuration

Set the `QUICKGEM_DISABLE` environment variable to disable QuickGem.

Set the `QUICKGEM_DEBUG` to output debug information.

## Problems

I haven't tested it on many different versions of Ruby, RubyGems and Bundler,
so there's probably many bugs lurking. Please open an issue if it doesn't give
any speedup on your machine. Remember to set `QUICKGEM_DEBUG=1` and post the
debug information outputted.

