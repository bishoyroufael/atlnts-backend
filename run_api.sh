make clean
make
sudo /usr/local/nginx/sbin/nginx -s reload
kill $(lsof -t -i:9000)
spawn-fcgi -a 127.0.0.1 -p 9000 ./api

