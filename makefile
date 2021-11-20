# vim: noexpandtab: tabstop=4:

FLIBS=3rdparty/flibs-0.9/flibs/src
SQLITELIB=3rdparty/fortran-sqlite3/src
SQLATLNTS=sql_atlnts/src

FORTRAN=gfortran
FORTRANFLAGS=-ldl -lfcgi -lsqlite3 -pthread -Wl,-rpath -Wl,/usr/lib

CGIOBJECTS = \
	cgi_protocol.o \
	fcgi_protocol.o \
	sqlite.o
SQLOBJECTS = sqlite.o
SQLATLNTSOBJECTS = sql_atlnts.o

all: api

api: api.f90 $(CGIOBJECTS) $(SQLOBJECTS) $(SQLATLNTSOBJECTS)
	$(FORTRAN) -o $@ $^ $(FORTRANFLAGS) 

sql_atlnts.o: $(SQLATLNTS)/sql_atlnts.f90 $(SQLOBJECTS)
	$(FORTRAN) -c $< 

sqlite.o: $(SQLITELIB)/sqlite.f90
	$(FORTRAN) -c $<

cgi_protocol.o: $(FLIBS)/cgi/cgi_protocol.f90
	$(FORTRAN) -c $<

fcgi_protocol.o: $(FLIBS)/cgi/fcgi_protocol.f90
	$(FORTRAN) -c $<

clean:
	rm -f -v api *.o *.mod *.db

.PHONY: clean
