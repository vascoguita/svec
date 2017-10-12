MANUAL=svec-device

all: doc man

doc: html

html:
	rst2html $(MANUAL).rst > $(MANUAL).html

man:
	$ rst2man --syntax-highlight=none $(MANUAL).rst > $(MANUAL).man

clean:
	rm -f *.html *.man
