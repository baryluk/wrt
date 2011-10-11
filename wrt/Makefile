.PHONY: all
all: main

#DMD=dmd
DMD=dmd2
#DMD=gdmd

#DMDFLAGS=-w -O -inline -release -profile
DMDFLAGS=-w -inline -release -O

#DMDFLAGS=-w -release -profile
#DMDFLAGS=-w -release -O -profile
#DMDFLAGS=-w -O -inline -profile
#DMDFLAGS=-w -release -inline
#DMDFLAGS=-w -release -O
#DMDFLAGS=-w -release -inline -g -gc
#DMDFLAGS=-w -debug -g -version=TraceAllExceptions -version=haveSegfaultTrace
#DMDFLAGS=-w -debug -g -gc
#DMDFLAGS=-w -debug -g -gc -profile -cov
#DMDFLAGS=-w -debug -g -gc -cov

AFILES=accelstructs/*.d base/*.d models/*.d objects/*.d textures/*.d *.d external/freeimage.d target/*.d scenes/*.d
# external/flectioned.d # not working in D2
#AFILES+=external/disabled/*.d
AFILES+=-I. -I..
#LIBS=-L-lfreeimage

#DERELICT=/usr/include/d/derelict/sdl/*.d /usr/include/d/derelict/util/*.d
DERELICT=-I~/d/include/d
DERELICT:=$(DERELICT) -L-ldl -L-lDerelictSDL -L-lDerelictUtil

FILES=$(shell ls -1 ${AFILES})

main: $(FILES)
	$(DMD) $(DMDFLAGS) -od./obj/ -ofmain $(FILES) $(LIBS) $(DERELICT)

# -I/usr/include/d

.PHONY: clean
clean:
	rm -f main *.o
