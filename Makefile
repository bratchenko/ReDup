help:
	@echo "clean - remove all build, test, coverage and Python artifacts"
	@echo "build - builds lambda function zip files"
	@echo "lint - check style with flake8"
	@echo "test - run tests"

clean:
	rm -rf libs-callback/
	rm -f callback-output.zip
	rm -f welcome-output.zip

build: callback-output.zip welcome-output.zip


# Our target is the libs dir, which has a requirements file as a prerequisite
# $@    refers to target: "libs/"

libs-callback: lambda-callback/requirements.txt
	@[ -d $@ ] || mkdir $@
	pip install -r $< --ignore-requires-python -t $@

# Our target is the zip file, which has libs as a prerequisite

callback-output.zip: libs-callback ## Output all code to zip file
	chmod -R 775  lambda-callback
	zip -r $@ lambda-callback/*.py
	cd $< &&  zip -rm ../$@ *
	# zip all python source code into output.zip
	# zip libraries installed in the libs dir into output.zip
	# We `cd` into the directory since zip will always keep the relative
	# paths, and lambda requires the library dependencies at the root.
	# Each line of a make command is run as a separate invocation of
	# the shell, which is why we need to combine the cd and zip command here.
	# We use the -rm flag so it removes the libraries after zipping,
	# since we don't need these.
	# We also copy only ".py" Files to reduce the size of lambda deployment.

welcome-output.zip:
	chmod -R 775 lambda-welcome
	zip -R $@ lambda-welcome/*.py

lint:
	flake8 lambda-callback
	flake8 lambda-welcome

test: test-callback test-welcome

test-callback: lambda-callback
	cd $< &&  pip install -r requirements-test.txt --user
	pytest $<


test-welcome: lambda-welcome
	cd $< &&  pip install -r requirements-test.txt --user
	pytest $<