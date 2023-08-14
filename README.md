# JMeter dockerized template repository

## JMeter version

The JMeter image used is the <https://hub.docker.com/r/rbillon59/jmeter-k8s-base>
Each tag of that Docker image is a JMeter version

to use a specific version, just change the tag in the docker-compose file. like

```yaml
    image: rbillon59/jmeter-k8s-base:5.4.1
```

These images are based on openjdk 16 and are compatible for x86 and arm64 architectures

## How to use it

Be sure to have Docker up and ready on your host and docker-compose installed

Create a repository from this template
then clone it with :

```shell
git clone <REPO> 
```

1. Put the needed csv to the *data* folder (in JMeter just put the filename in the path) : Be sure your filename have a .csv suffix (in lowercase)
2. Run your scenario with

```shell
source .env && JMX=my-scenario.jmx sudo docker-compose -p jmeter up --scale jmeter-slave=${nbInjector} -d
```

- Sourcing the .env will give you the ability to use $nbInjector in the docker-compose command line.  
- Passing the JMX as param and not in the .env can give you flexibility to run the test of your choice by command line without editing the env file (optional) 
- The *-p jmeter* is mandatory to prefix the docker-compose created networks and containers to work together (Tips : For every docker-compose command, use -p jmeter)
- The scale command is used to create the necessary amount of slaves injectors

> :warning: Use the `-p jmeter` option for every docker-compose command

3. You can visualize your performance test on host:30000 with the grafana attached. (login: admin password: admin)

At the end of the test, JMeter will create a report in the *report* directory

When you are done you can do

```shell
docker-compose -p jmeter down
```

to shutdown influxdb, grafana as well

Tips :

- Your influxdb datas are persisted in the influx-grafana folder, so you can relaunch a test with your historical datas on it.  
- If you need to update your JVM configuration, you can update the environment variables in the docker compose file
- If you specified hosts / ports / protocol etc.. directly in jour jmx, the environment variable will ***NOT*** override them.
- You can run a multi injector test by changing your .env file with nbInjector=X with the number of injectors you will need  
- The number of threads defined in the .env file is ***Per Injectors***

## Options

Options can be set in the .env file or *docker-compose.yml* file directly

`JMX` required : Your jmx filename  
`XMX` optional : Set the java heap (default 1g)  
`XMS` optional : Set the java heap (default 1g)  
`host` optional : Set the default request hostname on which perform the test (default jsonplaceholder.typicode.com)  
`port` optional : Set the default request port on which perform the test (default 443)  
`protocol` optional : Set the default request protocol (default https)  
`threads` optional : Set the number of virtual users to create (default 10)  
`duration` optional : Set the duration of the test in seconds (default 600)  
`rampup` optional : Set the time needed to create the total threads number (dafault 60)  
`nbInjector` optional : Set the number of injectors needed to run the test (default 1)
`SLAVE=1` required on slave : As it's the same docker images for controller and slaves, it's used to distinguish both
