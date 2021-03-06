# Python project Makefile

.SUFFIXES :
.PRECIOUS :
.PHONY : FORCE
.DELETE_ON_ERROR:

SHELL:=/bin/bash -o pipefail
SELF:=$(firstword $(MAKEFILE_LIST))


############################################################################
#= BASIC USAGE
default: help

#=> help -- display this help message
help: config
	@sbin/extract-makefile-documentation "${SELF}"

config:
	@echo CONFIGURATION
	@echo "  UTA_DB_URL=${UTA_DB_URL}"


############################################################################
#= SETUP, INSTALLATION, PACKAGING

#=> docs -- make sphinx docs
docs: setup build_sphinx

#=> build_sphinx
# sphinx docs needs to be able to import packages
build_sphinx: develop

#=> setup, develop -- install requirements for testing or development
setup: develop
develop: %:
	[ -f requirements.txt ] && pip install --upgrade -r requirements.txt
	python setup.py $*

#=> bdist, bdist_egg, sdist, upload_docs, etc
bdist bdist_egg build build_sphinx install sdist: %:
	python setup.py $@

#=> upload
upload: upload_pypi

#=> upload_all: upload_pypi, upload_invitae, and upload_docs
upload_all: upload_pypi upload_docs;

#=> upload_*: upload to named pypi service (requires config in ~/.pypirc)
upload_%:
	python setup.py bdist_egg sdist upload -r $*


############################################################################
#= TESTING
# see test configuration in setup.cfg

host-info:
	(PS4="\n>>"; set -x; /bin/uname -a; ./sbin/cpu-info; /usr/bin/free) 2>&1 | sed -e 's/^/## /'

#=> test -- run all tests (except those tagged "extra")
test: host-info
	python setup.py nosetests -A '(not tags) or ("extra" not in tags)'

#=> test-* -- run tests with specified tag
test-%: host-info
	python setup.py nosetests -a 'tags=$*'

#=> ci-test -- per-commit test target for CI
ci-test: test

#=> ci-test-ve -- test in virtualenv
ci-test-ve: ve
	source ve/bin/activate; \
	make ci-test



############################################################################
#= UTILITY TARGETS

#=> changelog
doc/source/changelog.rst: CHANGELOG
	./sbin/clog-txt-to-rst <$< >$@

#=> lint -- run lint, flake, etc
# TBD


#=> ve -- create a *local* virtualenv (not typically needed)
VE_DIR:=ve
VE_MAJOR:=1
VE_MINOR:=10
VE_PY_DIR:=virtualenv-${VE_MAJOR}.${VE_MINOR}
VE_PY:=${VE_PY_DIR}/virtualenv.py
${VE_PY}:
	curl -sO  https://pypi.python.org/packages/source/v/virtualenv/virtualenv-${VE_MAJOR}.${VE_MINOR}.tar.gz
	tar -xvzf virtualenv-${VE_MAJOR}.${VE_MINOR}.tar.gz
	rm -f virtualenv-${VE_MAJOR}.${VE_MINOR}.tar.gz
${VE_DIR}: ${VE_PY} 
	${SYSTEM_PYTHON} $< ${VE_DIR} 2>&1 | tee "$@.err"
	/bin/mv "$@.err" "$@"


############################################################################
#= CLEANUP
.PHONY: clean cleaner cleanest pristine
#=> clean: clean up editor backups, etc.
clean:
	find . -name \*~ -print0 | xargs -0r /bin/rm
#=> cleaner: above, and remove generated files
cleaner: clean
	find . \( -name \*.pyc -o -name \*.so \) -print0 | xargs -0r /bin/rm -f
	/bin/rm -fr build bdist cover dist sdist
	/bin/rm -f uta_align/align/algorithms.c uta_align/align/cigar_utils.c
#	-make -C doc clean
#=> cleanest: above, and remove the virtualenv, .orig, and .bak files
cleanest: cleaner
	find . \( -name \*.orig -o -name \*.bak -o -name \*.rej \) -print0 | xargs -0r /bin/rm -v
	find . -name __pycache__ -print0 | xargs -0r /bin/rm -fr
	/bin/rm -fr venv
	/bin/rm -fr distribute-* *.egg *.egg-info *.tar.gz nosetests.xml cover
#=> pristine: above, and delete anything unknown to mercurial
pristine: cleanest
	if [ -d .hg ]; then hg st -inu0 | xargs -0r /bin/rm -fv; fi

## <LICENSE>
## Copyright 2014 uta-align Contributors (https://bitbucket.org/biocommons/uta-align)
## 
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
## 
##     http://www.apache.org/licenses/LICENSE-2.0
## 
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
## </LICENSE>

