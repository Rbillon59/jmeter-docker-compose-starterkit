# JMeter dockerized template repository

## JMeter version

The JMeter image used is the <https://hub.docker.com/r/rbillon59/jmeter-k8s-base>
Each tag of that Docker image is a JMeter version

To use a specific version, just change the JMETER_VERSION env var in the `docker-compose.yaml` file

```yaml
  jmeter-master:
    build: &common-build
      context: .
      args:
        - JMETER_VERSION=5.4.1
```

These images are based on openjdk 16 and are compatible for x86_64 and arm64 architectures

## How to use it

Be sure to have Docker up and ready on your host and docker-compose installed

Create a repository from this template
then clone it with :

```shell
git clone <REPO> 
```

### Prerequisites

#### File structure

- You need to put your JMeter project folder inside the `scenario` folder, **inside a folder named after the JMX (without the extension)**. See example tree below
- Put your CSV file inside the `data` folder, child of `scenario`
- Put your JMeter modules (include controlers) inside the `modules` folder, child of `scenario`
- Set the scenario variables in the project's folder `.env` file. These variables will be exported and usable inside your scenario as Jmeter properties `${__P()}` (see scenario/my-scenario/my-scenario.jmx example)
- In the `.env` file at the repo root. Just set the name of the JMeter project to run. Like `JMX_FOLDER=my-scenario`

> `data`and `modules` are in the `scenario` folder and not below inside the `<project>` folder because, in some cases, you can have multiple JMeter projects that are sharing the JMeter modules (that's the goal of using modules after all).

Below a visual representation of the file structure

```bash
+-- .env
+-- scenario
|   +-- data
|   +-- modules
|   +-- my-scenario
|       +-- my-scenario.jmx
|       +-- .env
```

#### In JMeter

In JMeter just put the filename in the path of your `CSV Data Set Config` : Be sure your filename have a .csv suffix (in lowercase)

Do the same for the `Include Controller`, just use the filename without any path (with the extension)

### Runtime

To launch your test in a one liner fashion :

```shell
source scenario/my-scenario/.env && sudo docker-compose -p jmeter up --scale jmeter-slave=${nbInjector} -d
```

- Sourcing the `.env` will give you the ability to use $nbInjector in the docker-compose command line. (optionnal)
- The *-p jmeter* is mandatory to prefix the docker-compose created networks and containers to work together (Tips : **For every docker-compose command, use -p jmeter**)
- The scale command is used to create the necessary amount of slaves injectors

> :warning: Use the `-p jmeter` option for every docker-compose command

You can visualize your performance test on host:30000 with the grafana attached. (login: admin password: admin)

At the end of the test, JMeter will create a report in the `report/your-scenario` directory

When you are done you can do

```shell
docker-compose -p jmeter down
```

to shutdown influxdb, grafana as well

Tips :

- Your influxdb data are persisted in the influx-grafana folder, so you can relaunch a test with your historical data on it.  
- If you need to update your JVM configuration, you can update the environment variables in the docker compose file
- If you specified hosts / ports / protocol etc.. directly in jour jmx, the environment variable will ***NOT*** override them.
- You can run a multi injector test by changing your .env file with nbInjector=X with the number of injectors you will need  
- The number of threads defined in the .env file is ***Per Injectors***

## Options

Options can be set in the **.env file of your project**

`XMX` optional : Set the java heap (default 1g)  
`XMS` optional : Set the java heap (default 1g)  
`host` optional : Set the default request hostname on which perform the test (default jsonplaceholder.typicode.com)  
`port` optional : Set the default request port on which perform the test (default 443)  
`protocol` optional : Set the default request protocol (default https)  
`threads` optional : Set the number of virtual users to create (default 10)  
`duration` optional : Set the duration of the test in seconds (default 600)  
`rampup` optional : Set the time needed to create the total threads number (dafault 60)  
`nbInjector` optional : Set the number of injectors needed to run the test (default 1)
