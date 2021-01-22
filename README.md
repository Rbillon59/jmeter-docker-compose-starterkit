# JMeter dockerized template repository

## How to use it

Be sure to have Docker up and ready on your host and docker-compose installed

Create a repository from this template
then clone it with :

```shell
git clone <REPO> 
```

1. Write your JMeter scenario and put in the *scenario* folder : You can open the JMeter GUI with :
```shell
sh apache-jmeter-5.2.1/bin/jmeter
```


2. Put the needed csv to the *data* folder (in JMeter just put the filename in the path) : Be sure your filename have a .csv suffix (in lowercase)
3. Run your scenario with

```shell
source .env && JMX=my-scenario.jmx sudo docker-compose -p jmeter up --scale jmeter-slave=${nbInjector} -d
```

- Sourcing the .env will give you the ability to use $nbInjector in the docker-compose command line.  
- Passing the JMX as param and not in the .env can give you flexibility to run the test of your choice by command line without editing the env file (optional) 
- The *-p jmeter* is mandatory to prefix the docker-compose created networks and containers to work together (Tips : For every docker-compose command, use -p jmeter)
- The scale command is used to create the necessary amount of slaves injectors


4. You can visualize your performance test on host:30000 with the grafana attached. (login: admin password: admin)
6. At the end of the test, JMeter will create a report in the *report* directory
5. When you are done you can do 
```shell
docker-compose -p jmeter down
``` 
to shutdown influxdb, grafana

Tips : 
- Your influxdb datas are persisted in the influx-grafana folder, so you can relaunch a test with your historical datas on it.  
- If you need to update your JVM configuration, you can update the environment variables in the docker compose file
- If you specified hosts / ports / protocol etc.. directly in jour jmx, the environment variable will ***NOT*** override them.
- You can run a multi injector test by changing your .env file with nbInjector=X with the number of injectors you will need  
- The number of threads defined in the .env file is ***Per Injectors***



## Options

Options can be set in the .env file or *docker-compose.yml* file directly

*JMX* required : Your jmx filename  
*XMX* optional : Set the java heap (default 1g)  
*XMS* optional : Set the java heap (default 1g)  
*host* optional : Set the default request hostname on which perform the test (default jsonplaceholder.typicode.com)  
*port* optional : Set the default request port on which perform the test (default 443)  
*protocol* optional : Set the default request protocol (default https)  
*threads* optional : Set the number of virtual users to create (default 10)  
*duration* optional : Set the duration of the test in seconds (default 600)  
*rampup* optional : Set the time needed to create the total threads number (dafault 60)  
*nbInjector* optional : Set the number of injectors needed to run the test (default 1)
*SLAVE=1* required on slave : As it's the same docker images for controller and slaves, it's used to distinguish both
