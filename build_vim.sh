#!/bin/bash
set -e

LUA_VERSION=5.2
LUA_FULL_VERSION="${LUA_VERSION}.4_4"
VIM_PREFIX="/usr/local"

if [ "$(uname)" = "Linux" ]; then
    LUA_INCLUDE_PATH="/usr/local/lib/lua${LUA_VERSION}"
else
    if [ "$(uname)" = "Darwin" ]; then
        LUA_INCLUDE_PATH="/usr/local"
        # LUA_INCLUDE_PATH="/usr/local/Cellar/lua/${LUA_FULL_VERSION}/include/lua${LUA_VERSION}"
    fi;
fi;

# Constant settings
vim_artifacts=( "/usr/local/share/vim" "/usr/bin/vim" "./vim80" "./vim" "./vim-8.0.tar*")
linux_vim_deps=( "lua${LUA_VERSION}" "liblua${LUA_VERSION}-dev" "python-dev" "ruby-dev" "libperl-dev" "mercurial" "libncurses5-dev" "liblua${LUA_VERSION}-0" )
darwin_vim_deps=( "python3" )

# Build options
common_args="
    --disable-gui \
    --disable-netbeans \
    --disable-nls \
    --disable-arabic \
    --disable-farsi \
    --enable-multibyte \
    --prefix=${VIM_PREFIX} \
    --with-features=huge \
    --enable-rubyinterp \
    --enable-fail-if-missing \
    --enable-largefile \
    --disable-netbeans \
    --enable-pythoninterp \
    --enable-python3interp \
    --enable-perlinterp \
    --enable-luainterp \
    --enable-gui=auto \
    --enable-cscope \
"
linux_args="$common_args \
    --with-python3-config-dir=/usr/lib/python3/config-i386-linux-gnu \
    --with-python-config-dir=/usr/lib/python2.7/config-i386-linux-gnu \
    --with-x \
"
darwin_args="$common_args \
    --without-x \
    --with-lua-prefix=$LUA_INCLUDE_PATH \
"

# Utility methods
_install_for_linux() {
    echo "installing for linux..."
    if [ ! "$(apt-get 2> /dev/null)" ]; then
        echo "Apt is the only linux package manager supported"
        return 1
    fi
    for i in $@
    do
        echo "installing $i"
        sudo apt-get install -y $i
        sudo apt-get install -y lua${LUA_VERSION}
    done
}
_install_for_darwin() {
    echo "installing for darwin..."
    for i in $@
    do
        echo "installing $i"
        brew install "$i"
    done
}
_install() {
    if [ "$(uname)" = "Linux" ]; then
        _install_for_linux "${@}"
    else
        if [ "$(uname)" = "Darwin" ]; then
            _install_for_darwin "${@}"
        fi
    fi
}

# Clean house
if [ "$(uname)" = "Linux" ]; then
    sudo apt-get remove -y --purge vim vim-runtime vim-gnome vim-tiny vim-common vim-gui-common
    sudo apt-get remove -y --purge vim vim-runtime vim-gnome vim-tiny vim-common vim-gui-common
fi

# Install dependencies
if [ "$(uname)" = "Linux" ]; then
    _install_for_linux $linux_vim_deps
else
    if [ "$(uname)" = "Darwin" ]; then
        _install_for_darwin $darwin_vim_deps
    fi
fi

# Remove the artifacts to avoid conflicts
for i in "${vim_artifacts}"
do
    sudo rm -rf $i
done

# Create links to the lua libraries
if [ "$(uname)" = "Linux" ]; then
    sudo mkdir -p /usr/include/lua${LUA_VERSION}/include
    sudo mkdir -p /usr/include/lua${LUA_VERSION}/lib
    sudo ln -s /usr/include/lua${LUA_VERSION}/*.h /usr/include/lua${LUA_VERSION}/include/
    sudo ln -s /usr/lib/i386-linux-gnu/liblua${LUA_VERSION}.so /usr/include/lua${LUA_VERSION}/lib/liblua.so
fi

# Download a fresh version of vim & extract
wget ftp://ftp.vim.org/pub/vim/unix/vim-8.0.tar.bz2
tar jxf vim-8.0.tar.bz2

# Install vim
cd vim80

sudo make clean

if [ "$(uname)" = "Linux" ]; then
    sudo ./configure ${linux_args}
else
    if [ "$(uname)" = "Darwin" ]; then
        sudo ./configure ${darwin_args}
    else
        echo "Error: platform $(uname) not supported"
        return 1
    fi
fi

sudo make install
