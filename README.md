# atlnts-backend
Fortran Backend API For ATLNTS Web App - JHack 2021!

# Install
- Run `nginx/install_nginx.sh`
- Edit `/usr/local/nginx/conf/nginx.conf` to change the root location to `web` folder. Absolute path is required 
    - ```
            location / {
            root   /home/bishoy/Documents/jhack2020/server/src/atlnts-backend/web;
            fastcgi_pass   127.0.0.1:9000;
            fastcgi_index  index.html;
            include        fastcgi_params;
        }
    ```
- Install FastCGI using `fastcgi/install_fcgi.sh`
- Make sure `libsqllite3` and `libsqlite3-dev` is install on the system
- Make sure `libfcgi` and `libfcgi-dev` is install on the system
- In the main directory run `make`
- Run `run_api.sh`

