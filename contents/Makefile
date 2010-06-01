HTTP_PORT = 8888
CLEAN_LIST = `find . -name '*.html'`
SCM_FILES = `find . -name '*.scm'`
HTML_FILES = `find . -name '*.scm' | sed 's/\.scm$$/.html/'`

all: 
	@make -s $(HTML_FILES)
%.html: %.scm
	echo "./index.cgi /$(subst index.html,,$@) > ./$@" && ./index.cgi /$(subst index.html,,$@) > ./$@
clean: %tmp-clean
	rm -f $(CLEAN_LIST)
%tmp-clean:
	rm -rf %tmp/*
%tmp:
	mkdir %tmp

%tmp/lighttp-conf: %tmp
	@echo "{ HTTP_PORT => $(HTTP_PORT) }" > $@.pl
http-conf:
	@lighttpd -f ./%config/lighttpd.conf -p
http-stop:
	@[ -e %tmp/lighttpd.pid ] && kill `cat %tmp/lighttpd.pid`; return 0
	@make -s %tmp-clean
http-start: http-stop %tmp/lighttp-conf
	@lighttpd -f ./%config/lighttpd.conf -D &
