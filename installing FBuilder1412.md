<div align="center"><h4 style="margin-bottom:3px">installing Forms Builder 14.1.2</h4><h4>-everything on the table; one line launching-</h4></div>

[TOC]



### 1. intro

This is about having a minimal container that will run Forms Builder 14.1.2.0.  A little general description, that will shape the final result :

- process of obtaining the image use docker as requirement not as factotum. Make an easy transit to podman.
- Forms Builder is a final product in this container.This means is not interesting to build an image organized in layers that will be further significantly enhanced.
- installation of Forms Builder use persistence with bind volume on host
- host should be a linux distribution. Compatibility lays mostly on wayland implementations and graphical display manager on host.

The process use an intermediary image and has 3 intermediary stages

````mermaid
flowchart LR
I0(ol9)-- build-->I1
I1(ol9+jdk21)--dnf install-->I2(Oracle required<br> packages)
I2--intermediary <br>image-->I3(container +<br>bind volume with<br>  installation package)
I3--silent installation-->
I4(container running <br>Forms Builder 14.1.2)
````

### 2. quick start and finish

Steps are elementary, easy to follow.  You need : Oracle account, 5GB storage space, docker installed. Proceed as follows: 

- have docker framework installed and running

- use script and `Dockerfile.ol9` at [Oracle on github](https://github.com/oracle/docker-images/tree/main/OracleJava/21)  and build image of oracle linux 9 with jdk21 using command line :

  ````shell 
  $ ./build.sh 9
  ````

  Result will be an image called `oracle/jdk:21-ol9`

- on the host machine create a folder that will host Foms Builder installation. You will need about 5GB available

- this is where you need an Oracle account that allowes you to download files from `edelivery.oracle.com`. Installation package for Forms Builder can be found if search for "Oracle Fusion Middleware 14c (14.1.2.0.0) Forms and Reports for Linux x86-64 for (Linux x86-64), 1.3 GB". 

- unzipp and place the resulting file  ( `fmw_14.1.2.0.0_fr_linux64.bin` ) in folder choosen to host installation

- in the same folder put the silent installation file `result.file` provided here.

- you need 3 script files: `complete_installation.sh`, `install_req_pkgs.sh`, `install_config_forms.sh`. Put them together, anywhere on the host with access to folder hosting Forms  installation.

- (optional) in script file `install_config_forms.sh` set value for `VOLUME_HOST_PATH` as absolute path to the chosen folder. It should start with "/", like : `/home/myUser/FormsBuilder1412`

- start the installation from a terminal window with `complete_installation.sh`

- window manager on the host  must give permissions:

  ````shell
  $ xhost + local:
  ````

- launch Forms Builder with 

  ````shell
  $ echo '/oracle/Oracle/Middleware/Oracle_Home/formsInst1/bin/frmbld.sh' | docker start -i FormsBuilder1412
  ````



### 3.**intermediary image ** = ol9+jdk21+user "oracle" + required packages

Initial image is  "`oracle linux 9`" with JDK 21  as described by [Dockerfile.ol9](https://github.com/oracle/docker-images/tree/main/OracleJava/21)  provided by Oracle on *github.com*. Installation script will first creat a `user:group` for Oracle software installation as "`oracle:oracle`". User "`oracle`" has no password.

The list of packages is that in table [Table 1-17 Minimum Requirements for the Linux Operating System](https://docs.oracle.com/en/middleware/fusion-middleware/14.1.2/sysrs/system-requirements-and-specifications.html#SYSRS-GUID-A077A2B4-5967-42E0-A063-0F7A0A2254FB )  as provided on *docs.oracle.com* . This make a long list in installation script :

````shell
$ dnf install binutils-2.35.2-42.0.1.el9.x86_64 \
	gcc-11.3.1-4.3.0.4.el9.x86_64 \
...
$ dnf upgrade; dnf clean all
````

This can be used for other projects that may deserve a fork. Result is kept in a new image:

````shell
$ docker commit -m "Oracle linux 9, JDK 21, oracle:oracle, required packages for Forms Builder 14.1.2.0" <ol9-pkgForms1412> local/ol9-jdk21:pkgforms1412
````



### 4. creating a functional container for Forms Builder 14.1.2.0

#### start container for installation of Forms Builder

These references `/var/run/docker.sock , /usr/bin/docker` are used only for saving the current state of container in a new image from inside the container. User `root` is required to install  and update container operating system.  Commands are all included in a script file injected in the running container.

````shell
$docker run -i --rm -v /var/run/docker.sock:/var/run/docker.sock \
  -v /usr/bin/docker:/usr/bin/docker:ro --user root:root --workdir /home/oracle --name "$CONTAINER_PHASE1" --hostname "$CONTAINER_PHASE1" "$IMAGE" < "$INSTALL_REQ_PKG"
````

No volume installed, no layer in intermediary image.



#### installing  and configuration

Intermediary image is now used to start a container that will finally host Forms Builder 14.1.2.0 . 

Information can be found in [documentation at oracle](https://docs.oracle.com/en/middleware/developer-tools/forms/14.1.2/install-fnr/installing-and-configuring-form-builder-standalone.html#GUID-D1509110-88E4-4487-B7DE-CF633267C808)  , with installation binary package from  *edelivery.oracle.com*  if you look for  "*Oracle Fusion Middleware 14c (14.1.2.0.0) Forms and Reports for Linux x86-64 for (Linux x86-64), 1.3 GB*". This requires a valid Oracle account that  allowes you these operations. 



The download file is called `V1045121-01.zip` and you should unzipped it to get  `fmw_14.1.2.0.0_fr_linux64.bin` which is the binary installation package. This  `bin` file should be put in the same directory corresponding to the bind volume mounted in container.

In installation script `complete_installation.sh` the absolute path of this host directory should be put  in variable `VOLUME_HOST_PATH`. The script will test it's value and ask for a valid value for it.



To simplify  things,  the central inventory location file `oraInst.loc` will be created in the same bind volume and is pointed by variable `CENTRAL_INV` in `install_config_forms.sh` script file.

Installation is `silent` and is followed by configuration . Script end with a message indicating final result : command that can launch Forms Builder.



### 5. result

There is a container that can start in a single command Forms Builder 14.1.2.0 and will use host window manager. It will practically appear as a native host application. It will not require any other software installed in host.

It can be used to open, edit and save Oracle Forms files stored in host bind volume.

Artifacts created are:

- intermediary image  `local/ol9-jdk21:pkgforms1412`. This is disposable
- container `FormsBuilder1412`

Forms Builder 14.1.2.0 can be launched from host with : 

````shell
$ echo '/oracle/Oracle/Middleware/Oracle_Home/formsInst1/bin/frmbld.sh' | docker start -i FormsBuilder1412
````

Exiting Forms Builder will also stop the container.



### 6. further work

If you want to make aditional modifications  that requires persisting certain settings in container, you  should probably save the Forms Builder running container into a new image, or include them in any of the script provided.



