# Make sure the user passed in a platform
if [ -z "$1" ]
  then
    echo "Please use ./install.sh PLATFORM where platform is one of these:"
    echo "aix bsd c89 freebsd generic linux macosx mingw posix solaris"
    exit 0
fi

# Download lua and install it in gen
curl -O http://www.lua.org/ftp/lua-5.3.1.tar.gz
tar -xf lua-5.3.1.tar.gz
rm lua-5.3.1.tar.gz
cd lua-5.3.1
make $1
mv src/lua ../lua/
cd ../
rm -rf lua-5.3.1
