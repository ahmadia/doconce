#!/bin/bash -x
set -x

function system {
  "$@"
  if [ $? -ne 0 ]; then
    echo "make.sh: unsuccessful command $@"
    echo "abort!"
    exit 1
  fi
}

rm -rf html_images reveal.js downloaded_figures latex_styles

# Note:  --examples_as_exercises is required to avoid abortion

# Make publish database
rm -rf papers.pub  venues.list # clean

publish import refs1.bib <<EOF
1
2
EOF
if [ $? -ne 0 ]; then echo "make.sh: abort"; exit 1; fi

publish import refs2.bib <<EOF
2
2
EOF
# Simulate that we get new data, which is best put
# in a new file
publish import refs3.bib <<EOF
1
2
y
1
EOF

ex="--examples_as_exercises"
#ex=

system doconce format html testdoc --wordpress  $ex --html_exercise_icon=question_blue_on_white1.png --html_exercise_icon_width=80 --figure_prefix="https://raw.github.com/hplgit/doconce/master/test/" --movie_prefix="https://raw.github.com/hplgit/doconce/master/test/" --html_links_in_new_window

cp testdoc.html testdoc_wordpress.html

system doconce format html testdoc --without_answers --without_solutions $ex -DSOMEVAR --html_exercise_icon=default
cp testdoc.html testdoc_no_solutions.html

system doconce format latex testdoc --without_answers --without_solutions $ex -DSOMEVAR --sections_down
cp testdoc.p.tex testdoc_no_solutions.p.tex

cp ../bundled/html_styles/style_vagrant/template_vagrant.html .
system doconce format html testdoc.do.txt $ex --html_style=vagrant --html_template=template_vagrant.html
cp testdoc.html testdoc_vagrant.html
# Test that a split of testdoc_vagrant.html becomes correct
doconce split_html testdoc_vagrant.html

system doconce format html testdoc.do.txt --pygments_html_linenos --html_style=solarized --pygments_html_style=emacs $ex --html_exercise_icon=exercise1.svg

system doconce remove_exercise_answers testdoc.html
system doconce html_colorbullets testdoc.html
system doconce split_html testdoc.html --nav_button=gray2

system doconce format html testdoc.do.txt --pygments_html_linenos --html_style=solarized --pygments_html_style=emacs $ex --html_output=demo_testdoc

system doconce format latex testdoc.do.txt $ex SOMEVAR=True --skip_inline_comments
system doconce format pdflatex testdoc.do.txt --device=paper $ex --latex_double_hyphen --latex_index_in_margin --latex_no_program_footnotelink --latex_title_layout=titlepage --latex_papersize=a4 --latex_line_numbers --latex_colored_table_rows=blue --latex_fancy_header --latex_section_headings=blue --latex_labels_in_margin --latex_double_spacing --latex_todonotes --latex_list_of_exercises=loe --latex_font=palatino
# --latex_paper=a4 triggers summary environment to be smaller paragraph
# within the text (fine for proposals or articles).

# Drop the table exercise toc since we want to test loe above
#system doconce latex_exercise_toc testdoc

# doconce replace does not work well with system bash func above without quotes
doconce replace 'vspace{1cm} % after toc' 'clearpage % after toc' testdoc.p.tex
thpack='\\usepackage{theorem}\n\\newtheorem{theorem}{Theorem}[section]'
doconce subst '% insert custom LaTeX commands\.\.\.' $thpack testdoc.p.tex

doconce subst '\\paragraph\{Theorem \d+\.\}' '' testdoc.p.tex
doconce replace '% begin theorem' '\begin{theorem}' testdoc.p.tex
doconce replace '% end theorem' '\end{theorem}' testdoc.p.tex
# because of --latex-double-hyphen:
doconce replace Newton--Cotes Newton-Cotes testdoc.p.tex
doconce replace --examples_as__exercises $ex testdoc.p.tex

system ptex2tex -DMINTED testdoc

# test that pdflatex works
rm -f *.aux
system pdflatex -shell-escape testdoc
pdflatex -shell-escape testdoc
makeindex testdoc
bibtex testdoc
pdflatex -shell-escape testdoc
pdflatex -shell-escape testdoc

cp testdoc.tex testdoc.tex_ptex2tex
# testdoc.tex_ptex2tex corresponds to testdoc.pdf

system doconce ptex2tex testdoc sys=\begin{quote}\begin{Verbatim}@\end{Verbatim}\end{quote} pypro=ans:nt envir=minted > testdoc.tex_doconce_ptex2tex
echo "----------- end of doconce ptex2tex output ----------------" >> testdoc.tex_doconce_ptex2tex
cat testdoc.tex >> testdoc.tex_doconce_ptex2tex

system doconce format plain testdoc.do.txt $ex -DSOMEVAR=1 --tables2csv
system doconce format st testdoc.do.txt $ex
system doconce format sphinx testdoc.do.txt $ex
mv -f testdoc.rst testdoc.sphinx.rst

doconce format sphinx testdoc $ex
doconce split_rst testdoc
system doconce sphinx_dir author=HPL title='Just a test' dirname='sphinx-testdoc' version=0.1 theme=agni testdoc
cp automake_sphinx.py automake_sphinx_testdoc.py
system python automake_sphinx.py

system doconce format rst testdoc.do.txt $ex

system doconce format epytext testdoc.do.txt $ex
system doconce format pandoc testdoc.do.txt $ex
system doconce format mwiki testdoc.do.txt $ex
system doconce format cwiki testdoc.do.txt $ex
system doconce format ipynb testdoc.do.txt $ex

# Test mako variables too
system doconce format gwiki testdoc.do.txt --skip_inline_comments MYVAR1=3 MYVAR2='a string' $ex

# Test pandoc: from latex to markdown, from markdown to html
system doconce format latex testdoc.do.txt $ex --latex_title_layout=std
system doconce ptex2tex testdoc

#doconce subst -s 'And here is a system of equations with labels.+?\\section' '\\section' testdoc.tex
# pandoc cannot work well with \Verb, needs \verb
system doconce replace '\Verb!' '\verb!' testdoc.tex
# pandoc v 10 does not handle a couple of the URLs
doconce replace '%E2%80%93' '' testdoc.tex
doconce replace '+%26+' '' testdoc.tex

system pandoc -f latex -t markdown -o testdoc.md testdoc.tex
system pandoc -f markdown -t html -o testdoc_pnd_l2h.html --mathjax -s testdoc.md
pandoc -v >> testdoc_pnd_l2h.html

system doconce format pandoc testdoc.do.txt $ex
system pandoc -t html -o testdoc_pnd_d2h.html --mathjax -s testdoc.md
pandoc -v >> testdoc_pnd_d2h.html

# Test slides
# slides1: rough small test
# slides2: much of scientific_writing.do.txt
# slides3: equal to slides/demo.do.txt
system doconce format html slides1 --pygments_html_style=emacs --keep_pygments_html_bg
cp slides1.html slides1_1st.html  # before running slides_html

system doconce slides_html slides1 reveal --html_slide_type=beigesmall

cp slides1.html slides1_reveal.html
/bin/ls -R reveal.js >> slides1_reveal.html

system doconce format html slides1 --pygments_html_style=emacs --keep_pygments_html_bg
system doconce slides_html slides1 deck --html_slide_type=sandstone.firefox

cp slides1.html slides1_deck.html
/bin/ls -R deck.js >> slides1_deck.html

rm -f *.aux
system doconce format pdflatex slides1 --latex_title_layout=beamer
system doconce ptex2tex slides1
system doconce slides_beamer slides1 --beamer_slide_theme=blue_shadow --handout

system doconce format html slides2 --pygments_html_style=emacs
system doconce slides_html slides2 reveal --html_slide_type=beigesmall
cp slides2.html slides2_reveal.html

rm -f *.aux
system doconce format pdflatex slides2 --latex_title_layout=beamer
system doconce ptex2tex slides2 envir=minted
system doconce slides_beamer slides2

system doconce format html slides3 --pygments_html_style=emacs SLIDE_TYPE=reveal SLIDE_THEME=beigesmall
system doconce slides_html slides3 reveal --html_slide_type=beigesmall
cp slides3.html slides3_reveal.html

rm -f *.aux
theme=red3
system doconce format pdflatex slides3 SLIDE_TYPE=beamer SLIDE_THEME=$theme --latex_title_layout=beamer
system doconce ptex2tex slides3 envir=minted
system doconce slides_beamer slides3 --beamer_slide_theme=$theme

system doconce format html slides1 --pygments_html_style=emacs
system doconce slides_html slides1 all

# Test grab
system doconce grab --from- '={5} Subsection 1' --to 'subroutine@' _testdoc.do.txt > testdoc.tmp
doconce grab --from 'Compute a Probability' --to- 'drawing uniformly' _testdoc.do.txt >> testdoc.tmp
doconce grab --from- '\*\s+\$.+normally' _testdoc.do.txt >> testdoc.tmp

# Test html templates
system doconce format html html_template --html_template=template1.html --pygments_html_style=none
cp html_template.html html_template1.html

system doconce format html html_template --html_template=template_inf1100.html  --pygments_html_style=emacs

# Test author special case and generalized references
system doconce format html author1
system doconce format latex author1
system doconce format sphinx author1
system doconce format plain author1

# Test math
rm -f *.aux
name=math_test
doconce format pdflatex $name
doconce ptex2tex $name
pdflatex $name
system doconce format html $name
cp $name.html ${name}_html.html
doconce format sphinx $name
doconce sphinx_dir dirname=sphinx-rootdir-math $name
cp automake_sphinx.py automake_sphinx_math_test.py
python automake_sphinx.py
doconce format pandoc $name
# Do not use pandoc directly because it does not support MathJax sufficiently well
doconce md2html $name.md
cp $name.html ${name}_pandoc.html
doconce format pandoc $name
doconce md2latex $name

# Test admonitions

# LaTeX admon styles
admon_tps="colors1 mdfbox paragraph graybox2 yellowicon grayicon colors2"
for admon_tp in $admon_tps; do
if [ $admon_tp = 'mdfbox' ]; then
   color="--latex_admon_color=gray!6"
elif [ $admon_tp = 'grayicon' ]; then
   color="--latex_admon_color=gray!20"
else
   color=
fi
system doconce format pdflatex admon --latex_admon=$admon_tp $color
doconce ptex2tex admon envir=minted
cp admon.tex admon_${admon_tp}.tex
system pdflatex -shell-escape admon_${admon_tp}
echo "admon=$admon_tp"
if [ -d latex_figs ]; then
    echo "latex_figs:"
    /bin/ls latex_figs
else
    echo "no latex_figs directory for this admon type"
fi
rm -rf latex_figs
done

# Test different code envirs inside admons
doconce format pdflatex admon --latex_admon=mdfbox --latex_admon_color=1,1,1 --latex_admon_envir_map=2
doconce ptex2tex admon pycod2=minted pypro2=minted pycod=Verbatim pypro=Verbatim
cp admon.tex admon_double_envirs.tex
rm -rf latex_figs

# Test HTML admon styles
system doconce format html admon --html_admon=lyx --html_style=blueish2
cp admon.html admon_lyx.html

system doconce format html admon --html_admon=paragraph --html_style=blueish2
cp admon.html admon_paragraph.html

system doconce format html admon --html_admon=colors
cp admon.html admon_colors.html

system doconce format html admon --html_admon=gray --html_style=blueish2 --html_admon_shadow --html_box_shadow
cp admon.html admon_gray.html

system doconce format html admon --html_admon=yellow --html_admon_shadow --html_box_shadow
cp admon.html admon_yellow.html

system doconce format html admon --html_admon=apricot --html_style=solarized
cp admon.html admon_apricot.html

system doconce format html admon --html_style=vagrant --pygments_html_style=default --html_template=template_vagrant.html
cp admon.html admon_vagrant.html

system doconce format html admon --html_style=bootstrap --pygments_html_style=default --html_admon=bootstrap_alert
cp admon.html admon_bootstrap_alert.html
doconce split_html admon_bootstrap_alert.html

system doconce format html admon --html_style=bootswatch --pygments_html_style=default --html_admon=bootstrap_panel
cp admon.html admon_bootswatch_panel.html

system doconce sphinx_dir dirname=tmp_admon admon
system python automake_sphinx.py
rm -rf admon_sphinx
cp -r tmp_admon/_build/html admon_sphinx

system doconce format mwiki admon
cp admon.mwiki admon_mwiki.mwiki

system doconce format plain admon
cp admon.txt admon_paragraph.txt

cp -fr admon_*.html admon_*.pdf admon_*.*wiki admon_*.txt ._admon_*.html admon_sphinx admon_demo/
cd admon_demo
doconce replace '../doc/src/manual/fig/wave1D' '../../doc/src/manual/fig/wave1D' *.html .*.html
rm -rf *~
cd ..


#google-chrome admon_*.html
#for pdf in admon_*.pdf; do evince $pdf; done

if [ -d latex_figs ]; then
    echo "BUG: latex_figs was made by some non-latex format..."
fi

# Test Bootstrap HTML styles
system doconce format html test_boots --html_style=bootswatch_journal --pygments_html_style=default --html_admon=bootstrap_panel --html_code_style=inherit
doconce split_html test_boots.html

# Test GitHub-extended Markdown
system doconce format pandoc github_md.do.txt --github_md

# Test Markdown input
doconce format html markdown_input.do.txt --markdown --md2do_output=mdinput2do.do.txt

# Test movie handling
name=movies
system doconce format html $name --html_output=movies_3choices
cp movies_3choices.html movie_demo
system doconce format html $name --no_mp4_webm_ogg_alternatives
cp movies.html movie_demo

rm -f $name.aux
system doconce format pdflatex $name --latex_movie=media9
system doconce ptex2tex $name
system pdflatex $name
pdflatex $name
cp $name.pdf movie_demo/${name}_media9.pdf
cp $name.tex ${name}_media9.tex

system doconce format pdflatex $name --latex_movie=media9 --latex_external_movie_viewer
system doconce ptex2tex $name
system pdflatex $name
cp $name.pdf movie_demo/${name}_media9_extviewer.pdf

# multimedia (beamer \movie command) does not work well
#rm $name.aux

rm -f $name.aux
system doconce format pdflatex $name
system doconce ptex2tex $name
system pdflatex $name
cp $name.pdf movie_demo

system doconce format plain movies

cd Springer_T2
bash -x make.sh
cd ..

# Status movies: everything works in html and sphinx, only href works
# in latex, media9 is unreliable

# Test encoding: guess and change
system doconce guess_encoding encoding1.do.txt > tmp_encodings.txt
cp encoding1.do.txt tmp1.do.txt
system doconce change_encoding utf-8 latin1 tmp1.do.txt
system doconce guess_encoding tmp1.do.txt >> tmp_encodings.txt
system doconce change_encoding latin1 utf-8 tmp1.do.txt
system doconce guess_encoding tmp1.do.txt >> tmp_encodings.txt
system doconce guess_encoding encoding2.do.txt >> tmp_encodings.txt
cp encoding1.do.txt tmp2.do.txt
system doconce change_encoding utf-8 latin1 tmp2.do.txt
doconce guess_encoding tmp2.do.txt >> tmp_encodings.txt

# Handle encoding problems (and test debug output too)
# Plain ASCII with Norwegian chars printed as is (and utf8 package mode)
doconce format latex encoding3 --debug
cp encoding3.p.tex encoding3.p.tex-ascii
# Plain ASCII text with Norwegian chars coded as &#...;
doconce format html encoding3 --pygments_html_style=off --debug
cp encoding3.html encoding3.html-ascii
cat _doconce_debugging.log >> encoding3.html-ascii

# Plain ASCII with verbatim blocks with Norwegian chars
doconce format latex encoding3 -DPREPROCESS  # preprocess handles utf-8
cp encoding3.p.tex encoding3.p.tex-ascii-verb
doconce format html encoding3 -DPREPROCESS  # html fails with utf-8 in !bc
# Unicode with Norwegian chars in plain text and verbatim blocks
doconce format html encoding3 -DPREPROCESS  --encoding=utf-8  --pygments_html_style=none --debug # Keeps Norwegian chars since output is in utf-8
cp encoding3.html encoding3.html-ascii-verb
cat _doconce_debugging.log >> encoding3.html-ascii-verb

doconce format latex encoding3 -DMAKO  # mako fails due to Norwegian chars
# Unicode with Norwegian chars in plain text and verbatim blocks
doconce format latex encoding3 -DMAKO  --encoding=utf-8  # utf-8 and unicode
cp encoding3.p.tex encoding3.p.tex-utf8
doconce format html encoding3 -DMAKO  --encoding=utf-8  --pygments_html_style=off --debug
cp encoding3.html encoding3.html-utf8
cat _doconce_debugging.log >> encoding3.html-utf8

# Test mako problems
system doconce format html mako_test1 --pygments_html_style=off  # mako variable only, no % lines
system doconce format html mako_test2 --pygments_html_style=off  # % lines inside code, but need for mako
system doconce format html mako_test3 --pygments_html_style=off  # % lines inside code
cp mako_test3.html mako_test3b.html
system doconce format html mako_test3 --pygments_html_style=none # no problem message
system doconce format html mako_test4 --pygments_html_style=no  # works fine, lines start with %%

system doconce csv2table testtable.csv > testtable.do.txt

# Test doconce ref_external command
sh -x genref.sh

# Test error detection (note: the sequence of the error tests is
# crucial: an error must occur, then corrected before the next
# one will occur!)
cp failures.do.txt tmp2.do.txt
doconce format plain tmp2.do.txt
doconce replace '`myfile.py` file' '`myfile.py`' tmp2.do.txt
doconce format plain tmp2
doconce subst 'failure\}\n\n!bc' 'failure}\n\nHello\n!bc' tmp2.do.txt
doconce format sphinx tmp2.do.txt
doconce replace '!bsubex' '' tmp2.do.txt
doconce format sphinx tmp2.do.txt
doconce replace '# Comment before list' '' tmp2.do.txt
doconce format sphinx tmp2
doconce replace '\idx' 'idx' tmp2.do.txt
doconce replace '\cite' 'cite' tmp2.do.txt
doconce format rst tmp2
doconce subst -s '__Paragraph before.+!bc' '!bc' tmp2.do.txt
doconce format rst tmp2
doconce replace '\label' 'label' tmp2.do.txt
doconce replace 'wave1D width' 'wave1D,  width' tmp2.do.txt
doconce format sphinx tmp2
doconce replace 'doc/manual' 'doc/src/manual' tmp2.do.txt
doconce format sphinx tmp2
doconce replace '../lib/doconce/doconce.py' '_static/doconce.py' tmp2.do.txt
doconce replace 'two_media99' 'two_media' tmp2.do.txt
doconce format html tmp2
doconce replace '|--l---|---l---|' '|--l-------l---|' tmp2.do.txt
doconce format html tmp2
doconce replace '99x9.ogg' '.ogg' tmp2.do.txt
doconce format html tmp2
doconce subst -s -m '^!bsol.+?!esol' ''  tmp2.do.txt
doconce format sphinx tmp2
doconce subst -s -m '^!bhint.+?!ehint' ''  tmp2.do.txt
doconce format sphinx tmp2
doconce format pdflatex tmp2 --device=paper
# Remedy: drop paper and rewrite, just run electronic
doconce format pdflatex tmp2
#doconce replace '# Comment before math is ok' '' tmp2.do.txt
echo
echo "When we reach this point in the script,"
echo "it is clearly a successful run of all tests!"
