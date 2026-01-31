FROM alpine

ENV BINUTILS_VERSION=binutils-2.19.1
ENV GCC_VERSION=gcc-4.4.0
ENV GMP_VERSION=gmp-4.1.4
ENV MPFR_VERSION=mpfr-2.4.2

ENV PREFIX=/opt/tms9900/$GCC_VERSION
ENV TARGET=tms9900
ENV ENABLE_LANGUAGES=c
ENV PATH=$PATH:$PREFIX/bin

RUN apk update
RUN apk add texinfo wget unzip gcc patch make bash



RUN bash 
RUN mkdir /tmp/downloads
WORKDIR /tmp/downloads 
RUN wget https://ftp.gnu.org/pub/gnu/binutils/$BINUTILS_VERSION.tar.bz2 
RUN wget https://ftp.gnu.org/pub/gnu/gcc/$GCC_VERSION/$GCC_VERSION.tar.bz2 
RUN wget https://ftp.gnu.org/gnu/gmp/$GMP_VERSION.tar.gz 
RUN wget https://ftp.gnu.org/gnu/mpfr/$MPFR_VERSION.tar.gz 

ADD files /tmp/patch

RUN mkdir /tmp/build

WORKDIR /tmp/build
RUN tar jxf ../downloads/$BINUTILS_VERSION.tar.bz2 
WORKDIR /tmp/build/$BINUTILS_VERSION
RUN patch -p1 </tmp/patch/binutils-2.19.1-tms9900-1.7.patch

WORKDIR /tmp/build
RUN tar jxf ../downloads/$GCC_VERSION.tar.bz2
WORKDIR /tmp/build/$GCC_VERSION
RUN patch -p1 </tmp/patch/gcc-4.4.0-tms9900-1.19.patch

WORKDIR /tmp/build

RUN tar zxf ../downloads/$MPFR_VERSION.tar.gz && mv $MPFR_VERSION /tmp/build/$GCC_VERSION/mpfr 
RUN tar zxf ../downloads/$GMP_VERSION.tar.gz && mv $GMP_VERSION /tmp/build/$GCC_VERSION/gmp 
RUN mkdir elf2ea5 && tar zxf /tmp/patch/elf2ea5.tar.gz -C elf2ea5 
RUN mkdir elf2cart && tar zxf /tmp/patch/elf2cart.tar.gz -C elf2cart 
#RUN unzip /tmp/patch/ea5split.zip \ 
#RUN rm -v /tmp/downloads/*
#RUN rm -v /tmp/patch/* 
RUN  mkdir /tmp/build/binutils-obj
WORKDIR /tmp/build/binutils-obj 

RUN apk add build-base
RUN apk add --no-cache gcc g++ make texinfo wget unzip patch musl-dev bison flex
ENV CFLAGS="-Wno-builtin-declaration-mismatch -Wno-implicit-function-declaration -std=gnu89 -fcommon -O2"
ENV CXXFLAGS="$CFLAGS"

RUN sed -i 's/@subsubsection/@subsection/g' /tmp/build/$BINUTILS_VERSION/bfd/doc/elf.texi

RUN ../$BINUTILS_VERSION/configure --prefix=$PREFIX --target=$TARGET --disable-build-warnings
RUN make 
RUN make install 

RUN mkdir /tmp/build/gcc-obj
WORKDIR /tmp/build/gcc-obj 
RUN ../$GCC_VERSION/configure --prefix=$PREFIX --target=$TARGET --enable-languages=$ENABLE_LANGUAGES --disable-libmudflap --disable-libssp --disable-libgomp --disable-libstdcxx-pch --disable-threads --disable-nls --disable-libquadmath --with-gnu-as --with-gnu-ld --without-headers 
RUN make MAKEINFO=true all-gcc all-target-libgcc 
RUN make MAKEINFO=true install 

WORKDIR /tmp/build/gcc-obj 
RUN make all-target-libgcc 
RUN make install-target-libgcc 
WORKDIR /tmp/build/elf2ea5
RUN ls && make && mv elf2ea5 $PREFIX/bin/ 
WORKDIR /tmp/build/elf2cart
RUN ls && make && mv elf2cart $PREFIX/bin/ 
#WORKDIR /tmp/build/ea5split
#RUN ls && make && mv ea5split $PREFIX/bin/ 
RUN rm -rf /tmp/build /tmp/downloads

WORKDIR /src