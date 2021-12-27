#!/usr/bin/expect

spawn wget -O /root/go-pear.phar http://pear.php.net/go-pear.phar --no-check-certificate
expect eof

sleep 1
spawn php /root/go-pear.phar

expect "1-12, 'all' or Enter to continue:"
send "\r"

expect eof

spawn rm /root/go-pear.phar
