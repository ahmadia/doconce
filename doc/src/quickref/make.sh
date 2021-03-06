#!/bin/bash -x

function system {
  "$@"
  if [ $? -ne 0 ]; then
    echo "make.sh: unsuccessful command $@"
    echo "abort!"
    exit 1
  fi
}

set -x
sh ./clean.sh

# Make latest bin/doconce doc
doconce > doconce_program.sh

system doconce format html quickref --pygments_html_style=none --no_preprocess

# latex (shpro because of @@@CODE copy, need minted style)
system doconce format latex quickref --no_preprocess --latex_font=helvetica
system doconce ptex2tex quickref envir=Verbatim
# cannot run ptex2tex since it always runs preprocess
system latex -shell-escape quickref.tex
latex -shell-escape quickref.tex
dvipdf quickref.dvi

# Sphinx
system doconce format sphinx quickref --no_preprocess
rm -rf sphinx-rootdir
system doconce sphinx_dir author='HPL' version=0.7 quickref
doconce replace 'doconce format sphinx %s' 'doconce format sphinx %s --no-preprocess' automake_sphinx.py
system python automake_sphinx.py
cp quickref.rst quickref.sphinx.rst  # save

# reStructuredText:
system doconce format rst quickref --no_preprocess
rst2xml.py quickref.rst > quickref.xml
rst2odt.py quickref.rst > quickref.odt
rst2html.py quickref.rst > quickref.rst.html
rst2latex.py quickref.rst > quickref.rst.tex
system latex quickref.rst.tex
latex quickref.rst.tex
dvipdf quickref.rst.dvi

# Other formats:
system doconce format plain quickref --no_preprocess
system doconce format gwiki quickref --no_preprocess
system doconce format mwiki quickref --no_preprocess
system doconce format cwiki quickref --no_preprocess
system doconce format st quickref --no_preprocess
system doconce format epytext quickref --no_preprocess
system doconce format pandoc quickref --no_preprocess

rm -rf demo
mkdir demo
cp -r quickref.do.txt quickref.html quickref.p.tex quickref.tex quickref.pdf quickref.rst quickref.xml quickref.rst.html quickref.rst.tex quickref.rst.pdf quickref.gwiki quickref.mwiki quickref.cwiki quickref.txt quickref.epytext quickref.st quickref.md sphinx-rootdir/_build/html demo

cd demo
cat > index.html <<EOF
<HTML><BODY>
<TITLE>Demo of Doconce formats</TITLE>
<H3>Doconce demo</H3>

Doconce is a minimum tagged markup language. The file
<a href="quickref.do.txt">quickref.do.txt</a> is the source of the
Doconce quickref, written in the Doconce format.
Running
<pre>
doconce format html quickref.do.txt
</pre>
produces the HTML file <a href="quickref.html">quickref.html</a>.
Going from Doconce to LaTeX is done by
<pre>
doconce format latex quickref.do.txt
</pre>
resulting in the file <a href="quickref.tex">quickref.tex</a>, which can
be compiled to a PDF file <a href="quickref.pdf">quickref.pdf</a>
by running <tt>latex</tt> and <tt>dvipdf</tt> the standard way.
<p>
The reStructuredText (reST) format is of particular interest:
<pre>
doconce format rst    quickref.do.txt  # standard reST
doconce format sphinx quickref.do.txt  # Sphinx extension of reST
</pre>
The reST file <a href="quickref.rst">quickref.rst</a> is a starting point
for conversion to many other formats: OpenOffice,
<a href="quickref.xml">XML</a>, <a href="quickref.rst.html">HTML</a>,
<a href="quickref.rst.tex">LaTeX</a>,
and from LaTeX to <a href="quickref.rst.pdf">PDF</a>.
The <a href="quickref.sphinx.rst">Sphinx</a> dialect of reST
can be translated to <a href="quickref.sphinx.pdf">PDF</a>
and <a href="html/index.html">HTML</a>.
<p>
Doconce can also be converted to
<a href="quickref.gwiki">Googlecode wiki</a>,
<a href="quickref.mwiki">MediaWiki</a>,
<a href="quickref.cwiki">Creole wiki</a>,
<a href="quickref.md">aPandoc</a>,
<a href="quickref.st">Structured Text</a>,
<a href="quickref.epytext">Epytext</a>,
and maybe the most important format of all:
<a href="quickref.txt">plain untagged ASCII text</a>.
</BODY>
</HTML>
EOF

echo
echo "Go to the demo directory and load index.html into a web browser."

cd ..
dest=../../pub/quickref
cp -r demo/html demo/quickref.pdf demo/quickref.html $dest
dest=../../../../doconce.wiki
cp -r demo/quickref.rst $dest
