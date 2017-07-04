## ========================================
## Commands for both workshop and lesson websites.

# Settings
MAKEFILES=Makefile $(wildcard *.mk)
JEKYLL=jekyll
PARSER=bin/markdown_ast.rb
DST=_site

# Controls
.PHONY : commands clean files
.NOTPARALLEL:
all : commands

## commands         : show all commands.
commands :
	@grep -h -E '^##' ${MAKEFILES} | sed -e 's/## //g'

## serve-rmd        : run a local server, updating Rmd file automatically
serve-rmd: lesson-md lesson-watchrmd serve

## serve            : run a local server.
serve : lesson-md slides
	${JEKYLL} serve

## site             : build files but do not run a server.
site : lesson-md
	${JEKYLL} build

# repo-check        : check repository settings.
repo-check :
	@bin/repo_check.py -s .

## clean            : clean up junk files.
clean :
	@rm -rf ${DST}
	@rm -rf .sass-cache
	@rm -rf bin/__pycache__
	@find . -name .DS_Store -exec rm {} \;
	@find . -name '*~' -exec rm {} \;
	@find . -name '*.pyc' -exec rm {} \;

## clean-rmd        : clean intermediate R files (that need to be committed to the repo).
clear-rmd :
	@rm -rf ${RMD_DST}
	@rm -rf fig/rmd-*

## ----------------------------------------
## Commands specific to workshop websites.

.PHONY : workshop-check

## workshop-check   : check workshop homepage.
workshop-check :
	@bin/workshop_check.py .

## ----------------------------------------
## Commands specific to lesson websites.

.PHONY : lesson-check lesson-md lesson-files lesson-fixme lesson-watchrmd

# RMarkdown files
RMD_SRC = $(wildcard _episodes_rmd/??-*.Rmd)
RMD_DST = $(patsubst _episodes_rmd/%.Rmd,_episodes/%.md,$(RMD_SRC))

# RMarkdown slides
SLIDE_SRC = $(wildcard _slides_rmd/*.Rmd)
SLIDE_DST = $(patsubst _slides_rmd/%.Rmd,_slides/%.html,$(SLIDE_SRC))

# Lesson source files in the order they appear in the navigation menu.
MARKDOWN_SRC = \
  index.md \
  CONDUCT.md \
  setup.md \
  $(wildcard _episodes/*.md) \
  reference.md \
  $(wildcard _extras/*.md) \
  LICENSE.md

# Generated lesson files in the order they appear in the navigation menu.
HTML_DST = \
  ${DST}/index.html \
  ${DST}/conduct/index.html \
  ${DST}/setup/index.html \
  $(patsubst _episodes/%.md,${DST}/%/index.html,$(wildcard _episodes/*.md)) \
  ${DST}/reference/index.html \
  $(patsubst _extras/%.md,${DST}/%/index.html,$(wildcard _extras/*.md)) \
  ${DST}/license/index.html

## lesson-md        : convert Rmarkdown files to markdown
lesson-md : ${RMD_DST}

lesson-watchrmd:
	@bin/watchRmd.sh &	

_episodes/%.md: _episodes_rmd/%.Rmd
	@bin/knit_lessons.sh $< $@ 

## lesson-check     : validate lesson Markdown.
lesson-check :
	@bin/lesson_check.py -s . -p ${PARSER} -r _includes/links.md

## lesson-check-all : validate lesson Markdown, checking line lengths and trailing whitespace.
lesson-check-all :
	@bin/lesson_check.py -s . -p ${PARSER} -l -w

## lesson-figures   : re-generate inclusion displaying all figures.
lesson-figures :
	@bin/extract_figures.py -p ${PARSER} ${MARKDOWN_SRC} > _includes/all_figures.html

## unittest         : run unit tests on checking tools.
unittest :
	python bin/test_lesson_check.py

## lesson-files     : show expected names of generated files for debugging.
lesson-files :
	@echo 'RMD_SRC:' ${RMD_SRC}
	@echo 'RMD_DST:' ${RMD_DST}
	@echo 'MARKDOWN_SRC:' ${MARKDOWN_SRC}
	@echo 'HTML_DST:' ${HTML_DST}
	@echo 'SLIDE_SRC:'${SLIDE_SRC}
	@echo 'SLIDE_DST:'${SLIDE_DST}

## lesson-fixme     : show FIXME markers embedded in source files.
lesson-fixme :
	@fgrep -i -n FIXME ${MARKDOWN_SRC} || true

.PHONY : slides

## slides		 : Generate html slides from Rmd slide decks
slides: ${SLIDE_DST}

_slides/%.html:	_slides_rmd/%.Rmd
	@Rscript -e "rmarkdown::render('$<', output_dir='$(dir $@)')"
	

#-------------------------------------------------------------------------------
# Include extra commands if available.
#-------------------------------------------------------------------------------

-include commands.mk
