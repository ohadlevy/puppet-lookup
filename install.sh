#! /bin/sh

DIR=$(dirname $0)
YLOOKUP=ylookup.rb
if [ -x /usr/bin/install ] ; then
    install --mode=0644 --owner=root --group=root $DIR/$YLOOKUP /usr/lib/ruby/site_ruby/1.8/puppet/parser/functions/ylookup.rb
else 
    cp $DIR/$YLOOKUP /usr/lib/ruby/site_ruby/1.8/puppet/parser/functions/ylookup.rb
    chown root:root /usr/lib/ruby/site_ruby/1.8/puppet/parser/functions/ylookup.rb
fi
