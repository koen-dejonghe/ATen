#!/bin/bash

function build_aten_lib() {
  if [ ! -d build ] 
  then
    mkdir build
    cd build
    cmake .. -DCMAKE_INSTALL_PREFIX=../target -DNO_CUDA=true
    make install
    cd ..
  else
    echo "build directory exists, skipping ATen build..."
  fi
}

function build_jni_lib() {
  echo "preprocessing header files"
  cd target
  cp -R include include-swig
  cd include
  for f in $(find . -name \*.h); do
      cat $f \
      | sed -E "s|<TH(.*)>|\"TH\1\"|g" \
      | grep -v "#include <.*>" \
      | grep -v "#include \"cu.*\.h\"" \
      | grep -v "TH_NO_RETURN" \
      | sed -e "s|__thalign__([0-9])||g" \
      > ../include-swig/$f
  done
  cd ..

  cp ../jni-builder/torch-cpu.h include-swig
  cd include-swig
  cc -P -E -I TH -I THNN -I THS torch-cpu.h > torch-cpu-preprocessed.h

  echo "swigging"
  cd ..
  mkdir -p java/src/main/java/torch/cpu
  cp ../jni-builder/torch-cpu.i .
  swig -java -package torch.cpu -outdir java/src/main/java/torch/cpu torch-cpu.i

  echo "compiling swig wrapper"
  cc -c torch-cpu_wrap.c \
    -I $JAVA_HOME/include \
    -I $JAVA_HOME/include/darwin \
    -I include/TH \
    -I include/THNN \
    -I include/THS

  echo "building dynamic library"
  # does not work, but see https://docs.oracle.com/javase/9/troubleshoot/handle-signals-and-exceptions.htm#JSTGD356
  # cc -dynamiclib -undefined suppress -flat_namespace torch-cpu_wrap.o -o /Library/Java/JavaVirtualMachines/jdk1.8.0_144.jdk/Contents/Home/jre/lib/libjsig.dylib -o lib/libjnitorchcpu.dylib
  cc -dynamiclib -undefined suppress -flat_namespace torch-cpu_wrap.o -o lib/libjnitorchcpu.dylib

  cd ..
}

function package {
  cp jni-builder/build.sbt target
  cd target
  sbt torch/publishLocal
}

build_aten_lib
build_jni_lib
package

