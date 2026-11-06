#!/bin/bash
PASSWORD=Masaru!1

#export CC=/usr/bin/gcc-12 CXX=/usr/bin/gcc-12
#export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu/

export CC=/usr/bin/gcc CXX=/usr/bin/gcc
export LD_LIBRARY_PATH=/usr/lib/

make extraclean
./autogen.sh
#./configure CFLAGS="-O3 -pipe -mtune=native -march=native -fomit-frame-pointer" --with-native-compilation=aot --with-pgtk
export CFLAGS="-O2 -pipe -march=native -mtune=native -fno-omit-frame-pointer -fno-plt -flto=auto"
export LDFLAGS="-Wl,-O2 -Wl,-z,now -Wl,-z,relro -Wl,--sort-common -Wl,--as-needed -Wl,-z,pack-relative-relocs -flto=auto -O2"
./configure  \
  --without-x \
  --with-pgtk \
  --with-toolkit-scroll-bars \
  --with-cairo \
  --without-xft \
  --with-harfbuzz \
  --without-libotf \
  --with-gnutls \
  --without-xdbe \
  --without-xim \
  --without-gpm \
  --disable-gc-mark-trace \
  --with-gsettings \
  --with-modules \
  --with-threads \
  --with-libgmp \
  --with-xml2 \
  --with-tree-sitter \
  --with-zlib \
  --without-included-regex \
  --with-native-compilation=aot \
  --with-file-notification=inotify \
  --without-small-ja-dic \
  --without-compress-install 1> configure.log 2> configureerr.log
  
# ./configure CFLAGS="-O3 -pipe -mtune=native -march=native -fomit-frame-pointer" --with-native-compilation=aot --with-mailutils --with-xml2 --without-pop --with-pgtk --without-x --with-tree-sitter --with-rsvg --without-xaw3d --without-selinux --with-gnutls --without-gconf --without-xwidgets --without-toolkit-scroll-bars --without-xaw3d --without-gsettings --with-json --with-harfbuzz --with-imagemagick --with-jpeg --with-png --with-tiff --with-wide-int --with-xft --with-modules --without-ns 1> configure.log 2> configureerr.log
#--without-rsvg --without-x-toolkit=gtk3
#--with-xwidgets  (if need browse webkit . not eww )
make bootstrap NATIVE_FULL_AOT=1
echo $PASSWORD | sudo -S make install > /dev/null 2>&1

