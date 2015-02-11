au BufRead */log/apache2/{,other_vhosts_,ssl_}access.log{,.[0-9]{,.gz}} setf httplog
au BufRead */log/apache2/*error.log{,.[0-9]{,.gz}} setf apachelogs
