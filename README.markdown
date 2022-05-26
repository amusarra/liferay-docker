# Docker Image Build Project

This project is used to build Liferay Docker images for both Community Edition 
and DXP. Liferay Commerce Docker images are also built through this project.

The respective official Docker Hub repositories are:

1. [Official images for Liferay DXP releases](https://hub.docker.com/r/liferay/dxp)
2. [Official images for Liferay Portal releases](https://hub.docker.com/r/liferay/portal)
3. [Official images for Liferay Commerce Enterprise releases](https://hub.docker.com/r/liferay/commerce-enterprise)
4. [Official images for Liferay Commerce releases](https://hub.docker.com/r/liferay/commerce)

The project was born to build Liferay images based exclusively on the Tomcat bundle.

This fork, born from the [Liferay Docker](https://github.com/liferay/liferay-docker) repository, 
adds the ability to build Liferay local Docker images based on JBoss EAP.

For more info about this project, you can read this article
[How to create Docker images Liferay DXP + Red Hat JBoss EAP](https://techblog.smc.it/en/2020-10-21/come-creare-immagini-docker-liferay-dxp-jboss-eap)

For more information about Liferay Docker images I recommend reading the 
documentation [Starting with a Docker Image](https://learn.liferay.com/dxp/latest/en/getting-started/starting-with-a-docker-image.html)

## 1. Requirements
So that you can successfully complete the image creation Docker, a number of
software requirements must be met for the machine dedicated to the build operation.
The software requirements to be met are the following.

1. Unix/Linux/macOS Operating System. Alternatively, a Bash shell (version 3.x) is sufficient.
2. Docker Engine 18.x or 19.x.
3. Git 2.x (optional).
4. JDK 1.8 0 11.

As for Docker, you can install Docker Desktop on your own workstation, available
for both Microsoft operating systems and Apple operating systems. I recommend
installing the stable version avoiding the edge version, the latter useful for
experimenting with the latest features.

If you have already installed Docker, check the version on your system using the
`docker version` command making sure the version is in range indicated by the
requirements. An example of the command output is shown below. In this case the
version is 19.03.13, therefore in line with what is requested.

## 2. How to build local Docker images
Using the build_local_image.sh command, you can build your own local Liferay 
Docker images. By default, the images are created using the Liferay Tomcat bundle.

The command has the following usage forms:

```bash
Usage: ./build_local_image.sh path-to-bundle image-name version [push] [application server]

Example:
	 1. Build docker image from Liferay Tomcat Bundle
		 ./build_local_image.sh ../bundles/master portal-snapshot demo-cbe09fb0
	 2. Build docker image from Liferay Tomcat Bundle with push the image
		 ./build_local_image.sh ../bundles/master portal-snapshot demo-cbe09fb0 push
	 3. Build docker image Liferay with JBoss EAP Bundle without push the image
		 ./build_local_image.sh ../../bundles/ portal-snapshot liferay72-dxp-dev no-push jboss-eap
	 4. Build docker image Liferay with JBoss EAP Bundle with push the image
		 ./build_local_image.sh ../../bundles/ portal-snapshot liferay72-dxp-dev push jboss-eap
```

The first two commands build the Docker image starting from the Liferay Tomcat 
bundle, in particular, the second command also pushes to the Docker repository.

The last two commands instead build the Docker image using JBoss EAP as 
application server, in particular, the second command also pushes the image to 
the Docker repository.

### 2.1 How to build a Liferay local Docker image based on JBoss EAP
Before running the build image command, the following requirements must be met.
The image creation process refers to the documentation [Installing on JBoss EAP](https://learn.liferay.com/dxp/latest/en/installation-and-upgrades/installing-liferay/installing-liferay-on-an-application-server/installing-on-jboss-eap.html).

Installing on JBoss EAP requires deploying dependencies, modifying scripts, 
modifying config xml files, and deploying the DXP WAR file. 

Liferay DXP requires Java JDK 8 or 11. See the compatibility matrix for further 
information.

Download these files from the Liferay Help Center (subscription) or from 
Liferay Community Downloads and RedHat Customer Portal

1. DXP WAR file
2. Dependencies ZIP file
3. OSGi Dependencies ZIP file
4. JBoss EAP ZIP file

**Attention!** As of Liferay version 7.4, the *Dependencies ZIP file* is no longer 
needed and is therefore no longer available for download.

Note that Liferay Home is the folder containing the JBoss server folder. 
After installing and deploying DXP, the Liferay Home folder contains the 
JBoss server folder as well as data, deploy, logs, and osgi folders. 
$JBOSS_HOME refers to the JBoss server folder.

Once the four files have been downloaded, you can proceed with the image build.
The files needed to build the Liferay DXP 7.2 image on JBoss EAP 7.2 GA are 
shown below.

```bash
jboss-eap-7.2.0.zip
liferay-dxp-dependencies-7.2.10.3-sp3-202009100727.zip
liferay-dxp-osgi-7.2.10.3-sp3-202009100727.zip
liferay-dxp-7.2.10.3-sp3-202009100727.war
```

In the case of the build of the base image of Liferay 7.4 DXP Update 25 with 
JBoss EAP 7.4 (with patch number 4), the necessary files are those indicated 
below. 

In this software release, you can create the image with JBoss EAP 7.4 only 
with Liferay 7.4. In case you want to install Liferay 7.3 with JBoss EAP 7.4, 
you need to add the modules directory structure to the JBoss EAP 7.4 template 
configuration.

```bash
jboss-eap-7.4.0.zip
jboss-eap-7.4.4-patch.zip
liferay-dxp-7.4.13.u25-20220517155936227.war
liferay-dxp-osgi-7.4.13.u25-20220517155936227.zip
```

It is not necessary that the downloaded files are necessarily present in the 
project, the path must be indicated as an argument of the build command.
**It is important not to rename the file names.**

At this point you can proceed with the build of the image using the command below.
In this case the downloaded bundles are inside the `../../bundles/` directory 
and the resulting image will have the name `amusarra:liferay72-dxp-dev`. 

The image will not be published on the Docker repository (`no-push` param). 

The `jboss-eap` parameter indicates to create the Liferay Docker image with JBoss EAP.

```bash
./build_local_image.sh ../../bundles/ amusarra liferay72-dxp-dev no-push jboss-eap
```

The basic JBoss EAP configuration is governed by configuration files located 
within the following directory. For each version of JBoss there is a dedicated directory.

```bash
template
└── jboss-eap
   ├── 7.2.0
   │   ├── bin
   │   │   └── standalone.conf
   │   ├── modules
   │   │   └── com
   │   │       └── liferay
   │   │           └── portal
   │   │               └── main
   │   │                   ├── module.xml
   │   │                   └── ojdbc8.jar
   │   └── standalone
   │       └── configuration
   │           └── standalone.xml
   ├── 7.3.0
   │   ├── bin
   │   │   └── standalone.conf
   │   ├── modules
   │   │   └── com
   │   │       └── liferay
   │   │           └── portal
   │   │               └── main
   │   │                   ├── module.xml
   │   │                   └── ojdbc8.jar
   │   └── standalone
   │       └── configuration
   │           └── standalone.xml
   └── 7.4.0
       ├── bin
       │   └── standalone.conf
       └── standalone
           └── configuration
               └── standalone.xml
```

It is possible to act on the basic configuration of JBoss EAP at the build level, 
thus modifying the configuration templates, or better still, by acting on the 
image configuration, as documented by Liferay itself.

Once the build process is finished, you should see the new image. 
The `docker images` command displays the newly created image.

```bash
REPOSITORY                 TAG                              IMAGE ID            CREATED             SIZE
amusarra                   liferay72-dxp-dev                dc47e5d30128        6 hours ago         1.89GB
amusarra                   liferay72-dxp-dev-202009291154   dc47e5d30128        6 hours ago         1.89GB
amusarra				   liferay74-dxp-jboss-eap-74		32b2f5fac0f6        54 minutes ago      1.7GB
```

To launch the new image, just run the following command. As indicated in the 
Liferay documentation, in this command I have also indicated the volume, 
this allows you to deploy and act on the configuration of Liferay and JBoss.


```bash
docker run -d -it --name liferay72jboss -p 8080:8080 -p 11311:11311 -v $(pwd):/etc/liferay/mount -P amusarra:liferay72-dxp-dev
```
