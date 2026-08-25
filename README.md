### container running Forms Builder 14.1.2.0 on linux host
This is about having a minimal container that will run Forms Builder 14.1.2.0. Guidelines that explains choices made in this implementation:

- process of obtaining the image use *docker as requirement not as factotum*. Make an easy transition to podman.
- Forms Builder is the final stage in this container. This means is not interesting to build an image organized in layers that will be further significantly enhanced.
- installation of Forms Builder use persistence with bind volume on host
- host should be a linux distribution. Compatibility lays mostly on *wayland* implementations and graphical display manager on host.

### requirements
- about 5GB host storage space
- Oracle account allowing download of binary files from [edelivery.oracle.com](https://edelivery.oracle.com)
- docker installed
- linux host

### the process:
- download files to build the base image from Oracle repository on [github](https://github.com/oracle/docker-images/tree/main/OracleJava/21)
- download binary installation package for Forms Builder from Oracle
- launch 2 unix script files.
- one command line in terminal on host


### result
You will be able to:
- launch Forms Builder, *open, edit and save an Oracle Forms files and libraries*
- connect to a database with username, password and connection string like myDb.myDomain.com:4321/pdb1
- *Forms Builder will show* on screen using windows on *host window system manager*

### about using on windows host
Documentation said it is possible. Windows OS host will require certain software installation and container will get a slightly different environment variables.
