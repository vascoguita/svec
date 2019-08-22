MANUAL=svec-device

all: img doc

doc: html man

html:
	rst2html $(MANUAL).rst > $(MANUAL).html

man:
	rst2man --syntax-highlight=none $(MANUAL).rst > $(MANUAL).man

img: svec-logo.png

svec-logo.png: svec-logo.svg
	inkscape -f $< -e  $@

clean:
	rm -f *.html *.man *.png
