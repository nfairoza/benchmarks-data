Developer's corner: Information on SPECjbb2015 building
------------------------------------------------------------------------------------------------------------------------

For experimental purposes, one may want to update the SPECjbb2015 benchmark code,
so the SPECjbb2015 benchmark kit contains the benchmark sources which may be used for producing SPECjbb2015 benchmark
binaries.

NOTE: Updated benchmark binaries CANNOT be used for submitting SPECjbb2015 benchmark results.

Please follow the steps below to build the SPECjbb2015 benchmark.

1) Install and configure maven tool version 3.0 or higher (maven-3.0.4 has proved to work without problems).

   Add maven bin/ directory to the PATH and set JAVA_HOME environment variable.

   Maven may need to download additional data from network for building the benchmark,
   so the proxy settings in the <maven_home>/conf/settings.xml may need to be updated if you are using a proxy.

2) Unzip the benchmark sources:

	unzip <SPECjbb2015>/src.zip

   You will see additional src/ directory and build file pom.xml have appeared in the project.

x) Unzip and install bespoke Grizzly framework artifact

   unzip -q lib/grizzly-framework-*.jar -d tmp-grizzly-framework/
   mvn install:install-file -DgroupId=org.glassfish.grizzly -DartifactId=grizzly-framework -Dpackaging=jar -Dversion=2.3.19_p1_internal -Dfile=lib/grizzly-framework-2.3.19_p1_internal.jar -DpomFile=tmp-grizzly-framework/META-INF/maven/org.glassfish.grizzly/grizzly-framework/pom.xml

3) Prepare desired update

4) Run build command from <SPECjbb2015>/ project directory as follows:

	mvn install

   This command will build the binary to target/SPECjbb2015-<version> and run some unit tests.

   To skip testing phase during the build please use the following command:

        mvn install -DskipTests=true

   Please note that the first build may take considerable time
   (10 minutes or more depending of the network speed), because maven tries
   to download data required for building from the internet to the maven local repository
   (<user_home_dir>/.m2/repository by default). Further builds should complete within 5 minutes.

   The amount of data downloaded to the maven local repository by the build command is about 40 MB.

   To avoid downloading any additonal data from the internet you may try to request the archived maven repository data from SPEC.
   If you have the maven-repo archive, unpack it to the project directory and use the following command for building:

        mvn install -Dmaven.repo.local=<maven-repo>

   To rebuild the SPECjbb2015 benchmark use the following command which cleans up the old binaries:

	mvn clean install

5) Launch the SPECjbb2015 benchmark from target/SPECjbb2015-<version>/.

   As the build result target/SPECjbb2015-<version>/ directory is created,
   it contains the fully built project with the specjbb2015.jar. The updated the SPECjbb2015 benchmark
   should be launched from there.

   Note that top-level specjbb2015.jar provided with the kit or
   any other data outside the target/ directory is never updated by the build.

   You may also use the built kit archive:
   target/SPECjbb2015-<version>/specjbb2015-<version>.tar.gz or target/SPECjbb2015-<version>/specjbb2015-<version>.zip.

   Note that when you try to launch the updated benchmark, the kit validation fails and the benchmark execution stops.
   Please pass the -ikv argument to the specjbb2015.jar to skip the kit validation process and proceed with the run:

        java -jar specjbb2015.jar -m <mode> -ikv

   This command will launch the benchmark but the run will be still INVALID,
   updated binaries CANNOT be used for submitting SPECjbb2015 benchmark results.

------------------------------------------------------------------------------------------------------------------------
Product and service names mentioned herein may be the trademarks of
their respective owners.

Copyright 2007-2018 Standard Performance Evaluation Corporation (SPEC)
All rights reserved.
