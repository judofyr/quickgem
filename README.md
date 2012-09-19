# QuickGem

Before:

    $ time rails -v
    Rails 3.2.6

    real    0m0.314s
    user    0m0.293s
    sys     0m0.019s

After:

    $ time rails -v
    Rails 3.2.6

    real    0m0.077s
    user    0m0.067s
    sys     0m0.008s

## Installation

    $ git clone http://github.com/judofyr/quickgem.git
    $ cd quickgem

    # Build initial cache
    $ ruby quickgem.rb

    # Then put this in bashrc:
    export RUBYOPT="-r/full/path/to/quickgem/quickgem.rb"

