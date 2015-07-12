curl -O http://www.lua.org/ftp/lua-5.3.1.tar.gz
tar -xf lua-5.3.1.tar.gz
rm lua-5.3.1.tar.gz
cd lua-5.3.1
make $1
mv src/lua ../gen/
cd ../
rm -rf lua-5.3.1
