git clone https://github.com/zyedidia/Literate
cd Literate
rm -rf src lua examples tools
printf '.' | ./install_lua.sh
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

sed "1s%.*%#!$DIR/lua%" ./bin/lit > lit
chmod +x lit
rm -rf bin
