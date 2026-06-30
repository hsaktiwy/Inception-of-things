# 42-project:Inception of Thing  (DevOp, K8s, K3s, Vagrant, gitlab, helm, argocd)
---

# Vagrant: Portable and Reproducible Virtual Machine Management

## What is Vagrant?

**Vagrant** is an open-source tool used to **create, configure, and manage virtual machine environments through code**.

Instead of manually creating virtual machines using a graphical interface, Vagrant allows developers and system administrators to describe an entire virtual machine in a configuration file called a **Vagrantfile**, written in the **Ruby Domain-Specific Language (DSL)**.

The main goal of Vagrant is to make development and testing environments **portable, reproducible, and easy to share**.

For example, instead of sending instructions like:

> * Create an Ubuntu VM.
> * Allocate 2 GB RAM.
> * Add two CPUs.
> * Configure a private network.
> * Install Nginx.

You simply share the Vagrant project, and anyone can recreate the exact same environment with:

```bash
vagrant up
```

---

# Role of Vagrant

Vagrant automates the lifecycle of virtual machines by:

* creating virtual machines,
* configuring hardware resources,
* configuring networking,
* sharing folders between the host and guest,
* provisioning software automatically,
* starting, stopping, suspending, and destroying virtual machines.

It eliminates the need for repetitive manual configuration and ensures that every developer or tester works with an identical environment.

---

# How Vagrant Works

Vagrant acts as an abstraction layer between the user and a virtualization provider.

```text
          Vagrantfile
               │
               ▼
          Vagrant CLI
               │
               ▼
      Virtualization Provider
     (VirtualBox, VMware, Hyper-V)
               │
               ▼
        Virtual Machine
               │
               ▼
      Operating System
```

The workflow is straightforward:

1. The user writes a **Vagrantfile**.
2. Vagrant reads the configuration.
3. Vagrant communicates with the virtualization provider.
4. The provider creates the virtual machine.
5. Vagrant applies the configured settings.
6. Optional provisioning scripts install software automatically.

---

# Core Components

## 1. Vagrantfile

The **Vagrantfile** is the heart of every Vagrant project.

It describes:

* operating system image
* CPU allocation
* memory allocation
* networking
* shared folders
* provisioning scripts

Unlike Kubernetes, which commonly uses YAML manifests, **Vagrant uses a Ruby-based configuration file**.

---

## 2. Box

A **Box** is a preconfigured virtual machine image.

Examples include:

* Ubuntu 22.04
* Debian 12
* Rocky Linux
* AlmaLinux
* Windows Server

Rather than installing an operating system from scratch, Vagrant downloads a Box and uses it as the base image.

Example:

```ruby
config.vm.box = "ubuntu/jammy64"
```

---

## 3. Provider

The provider is the virtualization software responsible for running the virtual machine.

Common providers include:

* VirtualBox
* VMware
* Hyper-V
* Parallels
* Libvirt (KVM)

Vagrant itself does **not** create virtual machines—it instructs the selected provider to do so.

---

## 4. Provisioner

Provisioners automatically configure the virtual machine after it boots.

Common provisioners include:

* Shell scripts
* Ansible
* Chef
* Puppet
* Salt

For example, a shell provisioner can install software automatically:

```ruby
config.vm.provision "shell", inline: <<-SHELL
  apt update
  apt install -y nginx
SHELL
```

---

# Minimal Vagrantfile Example

A minimal Vagrant configuration looks like this:

```ruby
Vagrant.configure("2") do |config|

  config.vm.box = "ubuntu/jammy64"

end
```

This tells Vagrant to:

* download the Ubuntu 22.04 box (if necessary),
* create a virtual machine,
* boot the virtual machine.

---

# Slightly More Complete Example

```ruby
Vagrant.configure("2") do |config|

  config.vm.box = "ubuntu/jammy64"

  config.vm.hostname = "dev-machine"

  config.vm.network "private_network",
    ip: "192.168.56.10"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 2048
    vb.cpus = 2
  end

end
```

This configuration specifies:

* Ubuntu 22.04 as the operating system,
* a hostname of `dev-machine`,
* a private IP address,
* 2 GB of RAM,
* 2 virtual CPUs.

---

# Common Vagrant Commands

### Initialize a project

```bash
vagrant init ubuntu/jammy64
```

Creates a new `Vagrantfile`.

---

### Create and start the virtual machine

```bash
vagrant up
```

If necessary, Vagrant:

* downloads the Box,
* creates the VM,
* boots the VM,
* executes provisioning.

---

### Connect via SSH

```bash
vagrant ssh
```

Logs into the guest machine.

---

### Stop the VM

```bash
vagrant halt
```

Performs a graceful shutdown.

---

### Suspend the VM

```bash
vagrant suspend
```

Pauses the virtual machine while preserving its current state.

---

### Restart the VM

```bash
vagrant reload
```

Restarts the virtual machine and reapplies configuration changes if needed.

---

### Re-run provisioning

```bash
vagrant provision
```

Executes the configured provisioning scripts again without recreating the VM.

---

### Destroy the VM

```bash
vagrant destroy
```

Deletes the virtual machine while leaving the project files, including the `Vagrantfile`, intact.

---

# Why Use Vagrant?

Vagrant provides several key advantages:

* **Infrastructure as Code (IaC):** The virtual machine configuration is stored as code in a `Vagrantfile`, making it version-controlled and easy to share.
* **Reproducibility:** Every team member can create an identical development or testing environment.
* **Automation:** VM creation, networking, and software installation are automated.
* **Portability:** The same Vagrant project can run on different host operating systems, provided a supported virtualization provider is available.
* **Consistency:** It helps eliminate "it works on my machine" problems by ensuring everyone uses the same environment.

---

# Typical Workflow

A typical Vagrant workflow is:

```text
Write Vagrantfile
        │
        ▼
vagrant up
        │
        ▼
Download Box (if needed)
        │
        ▼
Create Virtual Machine
        │
        ▼
Configure CPU, Memory, and Network
        │
        ▼
Run Provisioning Scripts
        │
        ▼
Development Environment Ready
```

---

# Summary

Vagrant is a tool for managing virtual machines through code. It uses a **Ruby-based `Vagrantfile`** to define virtual machine characteristics such as the operating system, hardware resources, networking, shared folders, and provisioning steps. By working with virtualization providers like VirtualBox, VMware, Hyper-V, or Libvirt, Vagrant automates the creation and management of reproducible development and testing environments. This Infrastructure-as-Code approach allows teams to share a single configuration file and recreate identical virtual machines with simple commands like `vagrant up`, improving consistency, portability, and automation across different systems.

# The Kubernetes (k8s)
---

Before we define **Kubernetes**, we need to understand the problem it was created to solve. Kubernetes is not the first technology for running applications—it is the latest step in the evolution of how we use computing resources.

The journey looks like this:

```text
Physical Machines
        │
        ▼
Virtual Machines
        │
        ▼
Containers
        │
        ▼
Container Orchestration
        │
        ▼
Kubernetes
```

Each stage solved problems from the previous one, but also introduced new challenges.

---

## 1. The Era of Physical Machines

In the early days of computing, applications ran directly on **physical servers** (bare-metal machines).

```text
+--------------------------------------+
| Physical Server                       |
|                                      |
|   Operating System                   |
|      ├── Web Server                  |
|      ├── Database                    |
|      └── Application                 |
+--------------------------------------+
```

A company might buy one server for its website, another for its database, and another for email services.

### Problems

This approach had several limitations:


    A Pod abstracts one or more containers into a single deployable application unit.

This hierarchy is the foundation of Kubernetes. Everything else—Deployments, ReplicaSets, Services, Ingress, and tools like Argo CD—exists to create, manage, expose, or update Pods running on Nodes within a Cluster. Once you understand these three abstractions, the rest of Kubernetes becomes much easier to learn because every higher-level object builds upon them.
* **Poor resource utilization:** A server with 32 CPU cores might only use 10–15% of its capacity.
* **High cost:** Every application often required dedicated hardware.
* **Scaling was slow:** Expanding capacity meant purchasing, installing, and configuring new servers.
* **Single point of failure:** If the physical server failed, every application on it stopped working.

The industry needed a way to use hardware more efficiently.

---

## 2. The Era of Virtual Machines

The solution was **virtualization**.

A **hypervisor** (such as VMware ESXi, Hyper-V, or KVM) allows multiple **Virtual Machines (VMs)** to run on the same physical server.

```text
+--------------------------------------+
| Physical Server                      |
|                                      |
| Hypervisor                           |
|   ├── VM 1 (Linux)                   |
|   ├── VM 2 (Windows)                 |
|   ├── VM 3 (Ubuntu)                  |
|   └── VM 4 (CentOS)                  |
+--------------------------------------+
```

Each VM contains:

* Its own operating system
* Its own kernel
* Its own libraries
* Its own applications

### Advantages

Virtual machines solved many problems:

* Better hardware utilization
* Isolation between applications
* Easier backups and migrations
* Ability to run different operating systems on the same hardware

### New Problems

Although VMs improved efficiency, they introduced their own drawbacks.

Every VM includes an entire operating system.

```text
VM
├── Guest Operating System
├── Libraries
├── Runtime
└── Application
```

As a result:

* VMs are relatively large (often several gigabytes).
* Boot times can take minutes.
* Running many VMs consumes significant CPU and memory.
* Managing hundreds or thousands of VMs becomes complex.

The industry needed something lighter.

---

## 3. The Era of Containers

Containers package an application together with its dependencies, but **share the host operating system's kernel** instead of running a complete guest operating system.

```text
+-------------------------------------------+
| Host Operating System                     |
|                                           |
| Container Runtime                         |
|   ├── Container A                         |
|   ├── Container B                         |
|   └── Container C                         |
+-------------------------------------------+
```

Unlike a virtual machine, a container contains only:

* The application
* Its libraries
* Its runtime
* Configuration

It **does not include an entire operating system**.

### Advantages

Containers are:

* Lightweight
* Fast to start (often in seconds or less)
* Portable across environments
* Efficient in CPU and memory usage
* Easy to package and distribute

This led to the rise of technologies such as **Docker**, which made creating and sharing containers simple.

### The New Problem

Containers solved packaging and portability, but introduced a new operational challenge.

Imagine running:

* 10 containers → manageable
* 100 containers → difficult
* 10,000 containers → nearly impossible manually

Questions quickly arise:

* Which server should run each container?
* What happens if a container crashes?
* How do containers communicate?
* How do you update an application without downtime?
* How do you scale from 3 to 300 instances automatically?

Managing containers individually does not scale.

The industry needed a **container orchestrator**.

---

## 4. Before Kubernetes: Container Orchestrators

Several orchestration platforms emerged to automate container management.

Some of the most influential were:

* **Docker Swarm** — Docker's native orchestration solution, designed to be simple and tightly integrated with Docker.
* **Apache Mesos** — A distributed cluster manager capable of running many types of workloads, not just containers.
* **HashiCorp Nomad** — A lightweight scheduler that can orchestrate containers and other workloads.
* **Google Borg** *(internal)* — Google's proprietary system that inspired many modern orchestration concepts.

Among these, **Google Borg** had the greatest influence. Google had been running billions of containers across its global infrastructure for years, and the experience gained from Borg shaped the design of Kubernetes.

---

## 5. The Birth of Kubernetes

Google recognized that the broader industry faced the same problems it had already solved internally with Borg.

In 2014, Google released **Kubernetes** as an open-source container orchestration platform. The project was later donated to the Cloud Native Computing Foundation (CNCF), where it has become the de facto standard for orchestrating containers.

---

## What is Kubernetes?

**Kubernetes** is an **open-source container orchestration platform** that automates the deployment, scaling, networking, monitoring, and lifecycle management of containerized applications.

Rather than manually managing individual containers, you describe the **desired state** of your applications, and Kubernetes continuously works to make the actual state match that desired state.

In simple terms:

> **Containers package applications. Kubernetes manages those containers at scale.**

---

## What Problems Does Kubernetes Solve?

Kubernetes automates many operational tasks, including:

* **Scheduling:** Chooses the most suitable machine for each application.
* **Self-healing:** Replaces failed containers automatically.
* **Scaling:** Increases or decreases the number of application instances based on demand.
* **Load balancing:** Distributes incoming traffic across healthy application instances.
* **Rolling updates:** Deploys new versions gradually with minimal or no downtime.
* **Rollback:** Returns to a previous version if a deployment fails.
* **Service discovery:** Allows applications to find and communicate with each other without hardcoded IP addresses.
* **Storage orchestration:** Attaches and manages persistent storage for stateful applications.
* **Configuration and secrets management:** Separates configuration and sensitive data from application code.

---

## The Evolution of Application Deployment

The progression of application deployment can be summarized as:

```text
Physical Machine
    │
    ▼
One Application per Server
    │
    ▼
Virtual Machines
(Multiple OS instances on one server)
    │
    ▼
Containers
(Multiple isolated applications sharing one OS)
    │
    ▼
Container Orchestration
(Automated management of large numbers of containers)
    │
    ▼
Kubernetes
(The industry-standard platform for container orchestration)
```

This evolution reflects a continuous effort to improve **resource utilization, scalability, portability, resilience, and operational automation**. Kubernetes is the culmination of that journey, providing a unified platform for running modern containerized applications reliably across on-premises data centers, public clouds, and hybrid environments.

# Kubernetes hierarchical building block (Cluster->nodes->pods->container)

I think the biggest mistake most Kubernetes tutorials make is that they immediately start talking about Pods, Deployments, and Services without first introducing the **three fundamental abstractions** of Kubernetes:

> **Cluster → Node → Pod**

Everything else (Deployments, ReplicaSets, Services, Ingress, Argo CD...) exists to manage or interact with these three building blocks.

---

## The Three Levels of Abstraction in Kubernetes

One of Kubernetes' greatest strengths is that it hides the complexity of the underlying infrastructure by introducing multiple layers of abstraction.

Instead of worrying about **which server** an application should run on, Kubernetes allows you to think at progressively higher levels.

These abstractions form a simple hierarchy:

```text
Cluster
   │
   ├── Node
   │      │
   │      ├── Pod
   │      │      │
   │      │      └── Container(s)
```

Each layer has a single responsibility:

| Level   | Represents                    | Manages    |
| ------- | ----------------------------- | ---------- |
| Cluster | The entire computing platform | Nodes      |
| Node    | A single machine              | Pods       |
| Pod     | A single application instance | Containers |

Think of it like a city:

```text
City
   │
   ├── Buildings
   │      │
   │      ├── Apartments
   │      │      │
   │      │      └── People
```

Mapping this analogy to Kubernetes:

```text
City           → Cluster
Building       → Node
Apartment      → Pod
People         → Containers
```

You never place people directly into a city.

People live inside apartments.

Apartments exist inside buildings.

Buildings belong to the city.

Kubernetes follows the exact same hierarchy.

---

## 1. The Cluster

The **Cluster** is the highest level of abstraction in Kubernetes.

It represents the **entire Kubernetes environment**, combining all computing resources into a single logical platform.

A cluster consists of:

* one or more **Control Plane** machines
* one or more **Worker Nodes**
* networking
* storage
* Kubernetes components

From the user's perspective, all these machines appear as **one large computer**.

Instead of asking:

> Which server should run my application?

You simply tell Kubernetes:

> Run my application somewhere in the cluster.

The cluster decides where.

---

### Why Clusters Exist

Imagine you own five servers.

```text
Server A
Server B
Server C
Server D
Server E
```

Without Kubernetes, you must manually decide:

* Which server has enough CPU?
* Which server has enough RAM?
* Which server is overloaded?
* Which server has failed?

Kubernetes groups them together.

```text
                Kubernetes Cluster

      +-----------------------------------+
      |                                   |
      |   Node A                          |
      |   Node B                          |
      |   Node C                          |
      |   Node D                          |
      |   Node E                          |
      |                                   |
      +-----------------------------------+
```

Now Kubernetes makes those decisions for you.

The cluster acts as **one giant pool of resources** instead of many independent machines.

---

### What Lives Inside a Cluster?

A Kubernetes cluster contains two major parts.

```text
Cluster

├── Control Plane
│      ├── API Server
│      ├── Scheduler
│      ├── Controller Manager
│      └── etcd
│
└── Worker Nodes
       ├── Node 1
       ├── Node 2
       └── Node 3
```

The Control Plane makes decisions.

Worker Nodes execute them.

---

## 2. Nodes

If the cluster is the entire city,

a **Node** is one building inside that city.

A Node is a **physical server or virtual machine** that provides computing resources.

Those resources include:

* CPU
* Memory
* Storage
* Network connectivity

Every application ultimately runs on a Node.

---

### What Lives Inside a Node?

Every Worker Node contains several Kubernetes components.

```text
Worker Node

├── kubelet
├── kube-proxy
├── Container Runtime
└── Pods
```

Each has a different responsibility.

**kubelet**

The node agent.

Receives instructions from the Control Plane.

Creates and monitors Pods.

---

**Container Runtime**

Actually starts containers.

Examples

* containerd
* CRI-O

---

**kube-proxy**

Handles networking.

Routes traffic to Pods.

---

**Pods**

The workloads running on that machine.

---

### Nodes Are Resources

Think of Nodes as workers in a factory.

Each worker has:

```text
8 CPUs

32 GB RAM

500 GB Storage
```

When Kubernetes needs to run a Pod,

it asks:

> Which worker has enough resources?

The Scheduler chooses the most appropriate Node.

---

## 3. Pods

Pods are the **smallest deployable unit** in Kubernetes.

You never deploy containers directly.

You deploy Pods.

A Pod is a **logical wrapper** around one or more containers that must run together.

```text
Pod

├── Application Container
└── Sidecar Container
```

Most Pods contain one container.

Some contain multiple tightly coupled containers.

---

### Why Pods Exist

This is the question every beginner asks.

> Why not just run containers?

Because Kubernetes manages **applications**, not individual containers.

Containers often need to share:

* networking
* storage
* lifecycle
* hostname

A Pod provides those shared resources.

Containers inside the same Pod:

* share the same IP address
* communicate using `localhost`
* share mounted volumes
* start and stop together

The Pod becomes the unit that Kubernetes schedules, monitors, and replaces.

---

### Pods Are Disposable

One of the most important ideas in Kubernetes is that Pods are **ephemeral**.

They are designed to be created, destroyed, and recreated.

If a Pod crashes:

```text
Old Pod
    │
    X
    │
ReplicaSet
    │
    ▼
New Pod
```

Kubernetes does **not repair** the old Pod.

It creates a brand-new replacement that matches the desired state.

This immutable approach makes systems more predictable and easier to recover.

---

## Putting It All Together

The relationship between these abstractions can be visualized like this:

```text
Kubernetes Cluster
│
├── Node A
│      ├── Pod
│      │      └── Container
│      │
│      ├── Pod
│      │      └── Container
│      │
│      └── Pod
│             ├── App Container
│             └── Sidecar Container
│
├── Node B
│      ├── Pod
│      └── Pod
│
└── Node C
       ├── Pod
       └── Pod
```

Each abstraction has a clear responsibility:

* The **Cluster** abstracts a collection of machines into a single computing platform.
* A **Node** abstracts a physical or virtual machine that provides compute resources to the cluster.
* A **Pod** abstracts one or more containers into a single deployable application unit.

This hierarchy is the foundation of Kubernetes. Everything else—**Deployments**, **ReplicaSets**, **Services**, **Ingress**, and tools like **Argo CD**—exists to create, manage, expose, or update Pods running on Nodes within a Cluster. Once you understand these three abstractions, the rest of Kubernetes becomes much easier to learn because every higher-level object builds upon them.

# Kubernet component walkthrough Summary
Kubernetes is a large system made up of many components that work together. A useful way to understand it is to divide it into three groups:

1. **Control Plane** (the brain)
2. **Worker Nodes** (where applications run)
3. **Objects and Controllers** (how Kubernetes manages applications)

---

## 1. Kubernetes Architecture

```text
                     User / DevOps Engineer
                              │
                   kubectl / API / ArgoCD
                              │
                              ▼
                   +-----------------------+
                   |      API Server       |
                   +-----------------------+
                      │      │        │
          ------------       │        ------------
         ▼                   ▼                   ▼
   Scheduler          Controller Manager       etcd
         │
         ▼
    Worker Nodes
         │
 ┌──────────────────────────────────────┐
 │ kubelet                              │
 │ kube-proxy                           │
 │ Container Runtime                    │
 │ Pods                                 │
 └──────────────────────────────────────┘
```

---

## 2. Control Plane Components

The **Control Plane** manages the entire cluster.

Think of it as the operating system for your cluster.

---

### API Server

The API Server is the **front door** of Kubernetes.

Everything communicates through it.

Examples:

* kubectl
* Argo CD
* Helm
* Dashboard
* Scheduler
* Controllers

Nobody talks directly to etcd.

Everything goes through the API Server.

Example:

```bash
kubectl apply -f deployment.yaml
```

The API Server

* validates the YAML
* authenticates the user
* authorizes the request
* stores it in etcd

---

Responsibilities

* Authentication
* Authorization
* Validation
* REST API
* Admission Controllers
* Resource management

---

Example

```
kubectl create deployment nginx
```

↓

API Server receives request

↓

stores Deployment

↓

returns success

---

### etcd

etcd is the database of Kubernetes.

It stores everything.

Examples:

* Deployments
* Pods
* Secrets
* ConfigMaps
* Services
* Nodes
* ReplicaSets

If etcd is lost...

the cluster loses its state.

---

Think of it as

```
Kubernetes Memory
```

---

Example

```
Deployment
```

is stored as JSON inside etcd.

---

### Scheduler

The Scheduler decides

> Which node should run this Pod?

It does NOT create Pods.

It only chooses a worker node.

---

Example

Cluster

```
Node1
Node2
Node3
```

A Pod is created.

Scheduler checks

* CPU
* RAM
* Labels
* Taints
* Affinity
* Node health

Then chooses

```
Node2
```

---

Responsibilities

* Resource calculation
* Affinity
* Anti-affinity
* Taints
* Tolerations
* Topology constraints

---

### Controller Manager

This is one of the most important components.

Controllers constantly compare

Desired State

vs

Actual State

If different

They fix it.

---

Example

Desired

```
3 Pods
```

Actual

```
2 Pods
```

Controller creates

```
1 new Pod
```

---

Controllers run continuously.

---

Some important controllers

---

ReplicaSet Controller

Maintains

```
Desired Pods
```

Example

```
replicas: 5
```

Only 4 running

↓

creates another Pod.

---

Deployment Controller

Manages Deployments.

Creates

ReplicaSets

Handles

* Rolling updates
* Rollbacks

---

Node Controller

Checks node health.

If node dies

Pods are recreated elsewhere.

---

Job Controller

Runs batch jobs.

Stops after completion.

---

CronJob Controller

Runs Jobs periodically.

Example

```
Every midnight
```

---

Namespace Controller

Creates

Deletes namespaces.

---

Service Account Controller

Creates service accounts.

---

Endpoint Controller

Maintains Service endpoints.

---

Garbage Collector

Deletes unused objects.

---

## 3. Worker Node Components

Each machine that runs applications is called a Worker Node.

---

### kubelet

The kubelet is the node agent.

It communicates with the API Server.

Responsibilities

* Creates Pods
* Watches Pod specs
* Reports health
* Restarts containers
* Mounts volumes

Example

API says

```
Run nginx
```

kubelet starts nginx.

---

### Container Runtime

Actually runs containers.

Examples

* containerd
* CRI-O

Previously

Docker

was used directly.

Today Kubernetes uses CRI runtimes.

Responsibilities

* Pull images
* Start containers
* Stop containers
* Delete containers

---

### kube-proxy

Handles networking.

Creates routing rules.

Makes Services work.

Example

```
Service

↓

10 Pods

↓

Traffic distributed
```

kube-proxy performs the routing.

---

## 4. Kubernetes Objects

These are stored in etcd.

---

### Pod

Smallest deployable unit.

Usually contains

1 container

Sometimes multiple containers.

Example

```
Pod

├── nginx
└── sidecar
```

---

### ReplicaSet

Maintains

Number of Pods.

Example

```
Desired = 5

Running = 4

↓

Create 1
```

---

### Deployment

Most common object.

Manages

ReplicaSets.

Supports

* Rollouts
* Rollbacks
* Updates

---

Example

```
Deployment

↓

ReplicaSet

↓

Pods
```

---

### StatefulSet

For stateful applications.

Examples

* MySQL
* PostgreSQL
* MongoDB

Provides

Stable

* names
* storage
* identity

---

### DaemonSet

Runs one Pod

on every node.

Example

```
Node1 → Fluentd

Node2 → Fluentd

Node3 → Fluentd
```

Good for

* Monitoring
* Logging

---

### Job

Runs once.

Example

```
Backup database
```

---

### CronJob

Runs on schedule.

Example

```
Every day at 1 AM
```

---

### Service

Provides stable networking.

Pods change.

Service IP stays constant.

Types

* ClusterIP
* NodePort
* LoadBalancer
* ExternalName

---

### Ingress

HTTP routing.

Example

```
example.com → frontend

api.example.com → backend
```

---

### ConfigMap

Stores configuration.

Example

```
DATABASE_HOST=db
```

---

### Secret

Stores sensitive data.

Example

```
Password

API Key

TLS Certificate
```

---

### PersistentVolume (PV)

Physical storage.

Example

```
100 GB Disk
```

---

### PersistentVolumeClaim (PVC)

Request for storage.

Example

```
Need 20 GB
```

PVC gets matched to a PV.

---

## 5. Networking Components

```
Internet

↓

Ingress

↓

Service

↓

Pods
```

Every Pod has

its own IP.

Services provide

stable access.

---

## 6. Rollout Example

Suppose

```
Deployment

replicas = 3

image = nginx:v1
```

Developer changes

```
image = nginx:v2
```

Flow

```
kubectl apply

↓

API Server

↓

etcd

↓

Deployment Controller

↓

New ReplicaSet

↓

Scheduler

↓

Node

↓

kubelet

↓

containerd

↓

Pods Running
```

---

## 7. End-to-End Request Flow

The following sequence shows what happens when you deploy an application:

```text
Developer
   │
   ▼
kubectl apply deployment.yaml
   │
   ▼
API Server
   │
   ▼
etcd (stores desired state)
   │
   ▼
Deployment Controller
   │
   ▼
Creates ReplicaSet
   │
   ▼
ReplicaSet Controller
   │
   ▼
Creates Pod objects
   │
   ▼
Scheduler
   │
   ▼
Assigns Pods to Nodes
   │
   ▼
kubelet
   │
   ▼
Container Runtime
   │
   ▼
Containers Start
   │
   ▼
kube-proxy configures networking
   │
   ▼
Service exposes Pods
   │
   ▼
Ingress or LoadBalancer receives external traffic
```

This flow illustrates the collaboration between the main Kubernetes components: the API Server records the desired state, controllers reconcile that state, the Scheduler selects nodes, kubelet launches containers through the container runtime, and networking components make the application reachable.

---

# Kubernetes Objects: Defining the Desired State

Up to this point, we've learned that Kubernetes is a **container orchestration platform** whose primary goal is to keep applications running reliably.

But Kubernetes cannot read your mind.

It has no way of knowing:

* Which application you want to run.
* How many copies should exist.
* Which container image to use.
* Which ports should be exposed.
* How much CPU and memory the application needs.
* How the application should communicate with other applications.

You must describe your application to Kubernetes.

That description is called the **Desired State**.

Kubernetes stores this desired state and continuously compares it with the **Actual State** of the cluster.

Whenever they differ, Kubernetes works to make reality match your description.

```text
Desired State
       │
       ▼
 Kubernetes
(Reconciliation Loop)
       ▲
       │
Actual State
```

The mechanism used to describe this desired state is the **Kubernetes Object**.

---

## What is a Kubernetes Object?

A **Kubernetes Object** is a persistent record that describes part of the desired state of the cluster.

In other words,

> A Kubernetes Object is a declaration that tells Kubernetes **what should exist**, **how it should behave**, and **how it should be managed**.

Objects are stored permanently inside **etcd**, the cluster's database.

Every component in Kubernetes works by creating, reading, updating, or deleting these objects.

For example:

* A Deployment object describes how an application should be deployed.
* A Service object describes how clients should reach that application.
* A ConfigMap object describes configuration values.
* A Secret object describes sensitive information.

Everything in Kubernetes is represented as an object.

---

## Kubernetes is an Object-Oriented System

One way to think about Kubernetes is that it manages **objects**, not containers.

When you write a YAML file, you are **not running commands**.

You are creating objects.

For example,

this command

```bash
kubectl apply -f deployment.yaml
```

does **not** directly start a container.

Instead it creates a **Deployment Object**.

That Deployment Object then creates a ReplicaSet.

The ReplicaSet creates Pod Objects.

The Scheduler assigns those Pods to Nodes.

The kubelet finally creates the containers.

```text
deployment.yaml
        │
        ▼
Deployment Object
        │
        ▼
ReplicaSet Object
        │
        ▼
Pod Objects
        │
        ▼
Running Containers
```

Everything begins with an object.

---

## The Kubernetes YAML Manifest

Kubernetes objects are usually described using **YAML**.

A YAML file that defines one or more Kubernetes objects is called a **Manifest**.

Think of it as a blueprint.

Just as an architect draws a blueprint before constructing a building,

a DevOps engineer writes a manifest before Kubernetes creates resources.

Example:

```yaml
apiVersion: apps/v1
kind: Deployment

metadata:
  name: nginx

spec:
  replicas: 3

  selector:
    matchLabels:
      app: nginx

  template:
    metadata:
      labels:
        app: nginx

    spec:
      containers:
      - name: nginx
        image: nginx:latest
```

This file does **not** contain commands.

It contains a description of reality.

---

## Anatomy of a Kubernetes Object

Every Kubernetes object follows nearly the same structure.

```yaml
apiVersion:
kind:
metadata:
spec:
status:
```

Think of it as a universal template used by every Kubernetes resource.

---

### apiVersion

The **apiVersion** tells Kubernetes **which version of the API understands this object**.

Example

```yaml
apiVersion: apps/v1
```

Different objects belong to different API groups.

Examples:

```yaml
apps/v1
batch/v1
networking.k8s.io/v1
v1
```

This allows Kubernetes to evolve while maintaining backward compatibility.

---

### kind

The **kind** identifies the type of object being created.

Examples

```yaml
kind: Pod
```

```yaml
kind: Deployment
```

```yaml
kind: Service
```

```yaml
kind: ConfigMap
```

```yaml
kind: Secret
```

This tells the API Server which controller should manage the object.

---

### metadata

Every Kubernetes object contains metadata.

Metadata describes the object itself rather than the application.

Example

```yaml
metadata:

  name: frontend

  namespace: production

  labels:

    app: frontend

    version: v2
```

Metadata commonly contains:

* name
* namespace
* labels
* annotations
* owner references
* unique identifiers

Think of metadata as the object's identity card.

---

### spec (Specification)

The **spec** is the heart of every Kubernetes object.

It defines the **Desired State**.

Everything Kubernetes should create is described here.

Example

```yaml
spec:

  replicas: 3

  containers:

  - image: nginx
```

For a Deployment,

the spec might define:

* number of replicas
* update strategy
* Pod template
* resource limits

For a Service,

the spec defines:

* ports
* selector
* service type

Every object has a different spec,

because every object has a different purpose.

Think of the spec as the **requirements document** for that object.

---

### status

Unlike the **spec**, which is written by the user,

the **status** is written by Kubernetes.

Status describes the **Actual State** of the object.

Example

```yaml
status:

  availableReplicas: 3

  readyReplicas: 3

  updatedReplicas: 3
```

You generally **do not edit** the status field.

Controllers continuously update it.

---

## The Spec–Status Relationship

This is one of the most important concepts in Kubernetes.

Think of them as two sides of the same object.

```text
                Kubernetes Object

        +-------------------------+

        Specification (spec)

        "What I Want"

        -------------------------

        Status

        "What Currently Exists"

        +-------------------------+
```

Example:

You write

```yaml
spec:

  replicas: 5
```

The Deployment Controller creates Pods.

Eventually,

status becomes

```yaml
status:

  replicas: 5

  availableReplicas: 5
```

If one Pod crashes,

the status changes

```yaml
availableReplicas: 4
```

The controller notices the difference.

```text
Desired = 5

Actual = 4
```

It immediately creates another Pod.

Eventually,

status returns to

```text
Available = 5
```

This continuous comparison is called the **Reconciliation Loop**.

---

## Desired State vs Actual State

Almost everything Kubernetes does can be summarized by this simple equation:

```text
Your YAML
      │
      ▼
Specification (Desired State)
      │
      ▼
Controllers
      │
      ▼
Actual Cluster
      │
      ▼
Status
```

If

```text
Spec == Status
```

nothing happens.

If

```text
Spec ≠ Status
```

controllers begin reconciling the difference until reality matches the specification.

---

## Kubernetes Objects Are Building Blocks

Each object has a single responsibility, and more complex behavior emerges by combining them.

| Object                          | Purpose                                            | Creates / Manages         |
| ------------------------------- | -------------------------------------------------- | ------------------------- |
| **Pod**                         | Runs one or more containers                        | Containers                |
| **ReplicaSet**                  | Maintains the desired number of Pods               | Pods                      |
| **Deployment**                  | Manages ReplicaSets and application updates        | ReplicaSets               |
| **Service**                     | Provides stable networking and load balancing      | Network access to Pods    |
| **ConfigMap**                   | Stores non-sensitive configuration                 | Configuration data        |
| **Secret**                      | Stores sensitive information                       | Credentials, keys, tokens |
| **PersistentVolumeClaim (PVC)** | Requests persistent storage                        | PersistentVolumes         |
| **Ingress**                     | Routes external HTTP/HTTPS traffic                 | Services                  |
| **Job**                         | Runs a task to completion                          | Pods                      |
| **CronJob**                     | Runs Jobs on a schedule                            | Jobs                      |
| **DaemonSet**                   | Ensures one Pod runs on every Node                 | Pods                      |
| **StatefulSet**                 | Manages stateful applications with stable identity | Pods                      |

Notice that each object has **one well-defined responsibility**. Kubernetes follows the Unix philosophy of building complex systems from small, specialized components.

---

## The Big Picture

Everything you've learned so far fits into a single workflow:

```text
Developer writes YAML Manifest
            │
            ▼
kubectl apply
            │
            ▼
API Server validates the manifest
            │
            ▼
Kubernetes Object is created
            │
            ▼
Object is stored in etcd
            │
            ▼
Controllers observe the object
            │
            ▼
Controllers create or update other objects
            │
            ▼
Scheduler assigns Pods to Nodes
            │
            ▼
kubelet starts containers
            │
            ▼
Status is updated
            │
            ▼
Reconciliation Loop keeps the actual state aligned
with the desired state defined in the object's spec
```

This is the mental model that makes Kubernetes much easier to understand:

* **YAML manifests** are the language you use to describe your intentions.
* **Kubernetes Objects** are the persistent records of those intentions inside the cluster.
* The **`spec`** expresses the desired state you want.
* The **`status`** reflects the current state Kubernetes has achieved.
* **Controllers** continuously work to eliminate any difference between the two. Once you understand this model, every Kubernetes resource—from a simple Pod to a complex StatefulSet—follows the same fundamental pattern.

# Gitlab
## Definition
GitLab is a web-based platform for version control, software development, and DevOps. It helps developers and teams manage source code, collaborate on projects, automate testing, and deploy applications.

Key features include:

Git repository hosting for storing and managing code.
Collaboration tools such as merge requests, code reviews, and issue tracking.
CI/CD (Continuous Integration/Continuous Deployment) pipelines to automatically build, test, and deploy software.
Project management features like milestones, boards, and epics.
Security and compliance tools, including vulnerability scanning and code quality checks.

GitLab is available as both a cloud-hosted service and a self-managed installation, making it suitable for individual developers, startups, and large enterprises.

In short, GitLab is an all-in-one DevOps platform that enables teams to plan, develop, test, secure, and deploy software using Git-based version control.
## Gitlab >=< Github
**GitLab** and **GitHub** are both platforms for hosting Git repositories and collaborating on software development, but they have different strengths.

| Feature               | GitLab                         | GitHub                                             |
| --------------------- | ------------------------------ | -------------------------------------------------- |
| Primary focus         | Complete DevOps platform       | Git repository hosting and developer collaboration |
| Version control       | Uses Git                       | Uses Git                                           |
| CI/CD                 | Built-in, integrated CI/CD     | Available through GitHub Actions                   |
| Code review           | Merge Requests                 | Pull Requests                                      |
| Project management    | Built-in boards, issues, epics | Issues, Projects, Discussions                      |
| Hosting               | Cloud and self-managed         | Cloud and self-managed (GitHub Enterprise)         |
| Open-source community | Large                          | Largest open-source community                      |

### GitLab

* Designed as an **all-in-one DevOps platform**.
* Includes built-in tools for planning, coding, testing, security scanning, and deployment.
* Often chosen by organizations that want a single platform covering the entire software development lifecycle.

### GitHub

* The **most popular platform for open-source projects**.
* Known for its large developer community and collaboration features.
* Integrates with many third-party tools and offers automation through GitHub Actions.

### Main difference

* **GitLab** emphasizes an integrated **DevOps workflow**, with many capabilities built into one platform.
* **GitHub** emphasizes **code hosting and collaboration**, with a strong ecosystem and extensive community support.

### Which should you use?

* Choose **GitLab** if you want an integrated platform with built-in CI/CD, security, and deployment features.
* Choose **GitHub** if you're contributing to open-source projects, want access to the largest developer community, or prefer its collaboration experience.

Both platforms use **Git**, so the version control concepts (repositories, branches, commits, merges) are the same. The main differences are in the features and workflows they provide around Git.
## Argo CD
Argo CD is an **open-source Continuous Delivery (CD) tool for Kubernetes** that automates application deployment using GitOps principles.

## Definition

Argo CD continuously monitors a Git repository and ensures that the applications running in a Kubernetes cluster match the configuration stored in Git. If there is a difference, Argo CD can automatically synchronize the cluster to the desired state.

## How Argo CD works

1. Developers update Kubernetes manifests or Helm charts in a Git repository.
2. The changes are committed and pushed to Git.
3. Argo CD detects the changes.
4. Argo CD deploys the updated configuration to the Kubernetes cluster.
5. It continuously monitors the cluster and reports whether it is **Synced** (matches Git) or **Out of Sync** (drift detected).

## Key features

* **GitOps-based deployments** (Git is the single source of truth)
* **Automatic or manual synchronization**
* **Rollback** to previous application versions
* **Application health monitoring**
* **Support for Helm, Kustomize, and plain YAML**
* **Web UI, CLI, and REST API**
* **Multi-cluster management**

## Example workflow

```
Developer
     │
     ▼
Git Repository
     │
     ▼
Argo CD
     │
     ▼
Kubernetes Cluster
```

## Argo CD vs GitLab CI/CD

| Feature                   | Argo CD                           | GitLab CI/CD                         |
| ------------------------- | --------------------------------- | ------------------------------------ |
| Purpose                   | Deploy applications to Kubernetes | Build, test, and deploy applications |
| Deployment model          | GitOps                            | Pipeline-based                       |
| Source of truth           | Git repository                    | CI/CD pipeline configuration         |
| Best for                  | Kubernetes deployments            | End-to-end DevOps automation         |
| Continuous reconciliation | Yes                               | No                                   |

## How they work together

A common production workflow is:

```
Developer
      │
      ▼
GitLab Repository
      │
      ▼
GitLab CI Pipeline
(Build → Test → Create Docker Image)
      │
      ▼
Container Registry
      │
      ▼
Update Kubernetes manifests in Git
      │
      ▼
Argo CD
      │
      ▼
Kubernetes Cluster
```

In this setup:

* **GitLab CI** builds and tests the application, creates a container image, and updates the Kubernetes deployment manifests.
* **Argo CD** detects the manifest changes in Git and deploys them to the Kubernetes cluster automatically.

This combination is widely used because it separates **CI (building and testing software)** from **CD (deploying to Kubernetes)** while using Git as the authoritative source for deployment configuration.
# Relationship between Argo CD and Kubernet rollout, rollback
The relationship is that **Argo CD does not replace Kubernetes rollouts and rollbacks—it manages and triggers them.** Kubernetes performs the actual deployment, while Argo CD ensures the cluster matches the desired state stored in Git.

Here's how they fit together:

```text
Git Repository
      │
      ▼
Argo CD
      │
      ▼
Kubernetes API
      │
      ▼
Deployment
      │
      ▼
ReplicaSets
      │
      ▼
Pods
```

## Rollout

A **rollout** is the process of deploying a new version of an application.

Suppose your Deployment changes from:

```yaml
image: myapp:v1
```

to

```yaml
image: myapp:v2
```

**What happens?**

1. You commit the change to Git.
2. Argo CD detects the new commit.
3. Argo CD applies the updated Deployment to Kubernetes.
4. Kubernetes starts a **rolling update**:

   * Creates new Pods with `v2`.
   * Waits until they're healthy.
   * Gradually removes the old `v1` Pods.
5. Users experience little or no downtime.

The rollout itself is performed by **Kubernetes**, not Argo CD.

---

## Rollback

A **rollback** returns the application to a previous version.

There are two common ways to do this.

### Option 1: GitOps rollback (recommended with Argo CD)

You revert the Git commit:

```text
image: myapp:v2
        ↓
image: myapp:v1
```

Then:

1. Push the reverted commit.
2. Argo CD detects the change.
3. Argo CD applies it.
4. Kubernetes rolls back by performing another rolling update back to `v1`.

This is the preferred approach because **Git remains the source of truth**.

---

### Option 2: Kubernetes rollback

You can run:

```bash
kubectl rollout undo deployment myapp
```

Kubernetes immediately rolls back to the previous ReplicaSet.

However, if Git still says the desired version is `v2`, Argo CD will notice the cluster no longer matches Git and will change it back to `v2` during the next synchronization (or immediately if auto-sync is enabled).

That's why this method is generally not recommended in a GitOps workflow unless you also update Git.

---

## Why GitOps prefers Git rollbacks

With GitOps:

```text
Git = Source of Truth
```

Everything running in the cluster should match what's in Git.

If someone changes the cluster manually:

```bash
kubectl edit deployment
kubectl rollout undo
```

Argo CD sees:

```text
Git          Cluster
v2     ≠      v1
```

and synchronizes the cluster back to `v2` unless Git is updated.

---

## Summary of responsibilities

| Component                        | Responsibility                                                              |
| -------------------------------- | --------------------------------------------------------------------------- |
| Argo CD                          | Watches Git and applies changes to the cluster                              |
| Kubernetes Deployment            | Defines the desired application state                                       |
| Kubernetes Deployment Controller | Performs rolling updates and manages ReplicaSets                            |
| ReplicaSet                       | Keeps the correct number of Pods running for a specific application version |
| Pods                             | Run the application containers                                              |

In short:

* **Argo CD decides *what* version should be running** (based on Git).
* **Kubernetes decides *how* to get there** (using rollouts, ReplicaSets, health checks, and rollbacks).
This is probably the **hardest topic in Kubernetes**, and unfortunately, it's also the one that most tutorials explain poorly.

The biggest mistake is that they start by saying:

> "A Service exposes Pods."

That doesn't answer **why** Services exist, **how** packets actually move, or **who** performs the routing.

If I were writing a Kubernetes handbook, I would teach networking by **building the network layer by layer**, exactly like the networking stack itself.

---

# Kubernetes Networking

One of Kubernetes' greatest achievements is that it makes a cluster of many independent machines behave like **one giant computer**.

Imagine you have three physical machines.

```text
Node A
Node B
Node C
```

Each machine has its own:

* CPU
* RAM
* Disk
* Network Interface (NIC)
* IP Address

Normally these machines know nothing about the applications running on one another.

Yet Kubernetes allows a Pod running on **Node A** to communicate directly with a Pod running on **Node C** without NAT, port forwarding, or manual routing.

How?

To answer that question we must first understand the **Kubernetes Networking Model**.

---

## The Kubernetes Networking Model

Kubernetes is built on four fundamental networking rules.

Every networking feature—Services, Ingress, DNS, LoadBalancers—exists because of these rules.

---

### Rule 1

**Every Pod gets its own unique IP address.**

Not every container.

Every **Pod**.

```text
Node A

Pod A
10.244.1.5

Pod B
10.244.1.6
```

Pods never share IP addresses.

This is different from Docker.

Docker:

```text
Host

↓

Bridge Network

↓

Containers
```

Containers often communicate through NAT.

Kubernetes intentionally avoids that.

---

### Rule 2

Pods can communicate directly with every other Pod.

Regardless of the Node.

```text
Node A

Pod A

↓

↓

↓

Node C

Pod X
```

No NAT.

No manual routing.

Just IP networking.

---

### Rule 3

Agents running on Nodes can communicate with every Pod.

This allows components like kubelet to monitor and manage Pods.

---

### Rule 4

Applications should not know where Pods are located.

Applications communicate using Services and DNS rather than Pod IPs.

This makes Pods replaceable.

---

## Building the Kubernetes Network

Let's build the network step by step.

---

## Step 1 — The Node Network

Imagine two machines.

```text
192.168.1.10
```

```text
192.168.1.20
```

These are ordinary Linux machines.

Nothing special.

They can already communicate.

```text
Machine A
        │
 Ethernet
        │
Machine B
```

Kubernetes doesn't replace this network.

It builds on top of it.

---

## Step 2 — Pod Network

Now Kubernetes creates Pods.

```text
Node A

Pod
10.244.1.5
```

```text
Node B

Pod
10.244.2.8
```

Notice something interesting.

The Pod IPs are completely different from the Node IPs.

Node

```text
192.168.x.x
```

Pod

```text
10.244.x.x
```

Where did these IPs come from?

---

## The CNI

The **Container Network Interface (CNI)** creates the Pod network.

Examples include:

* Flannel
* Calico
* Cilium
* Weave Net

Think of the CNI as the **network engineer** of Kubernetes.

It is responsible for:

* assigning Pod IP addresses
* creating virtual interfaces
* configuring routing tables
* connecting Pods across Nodes

Without a CNI, Pods cannot communicate beyond their own Node.

---

## Inside One Node

Suppose Node A has two Pods.

```text
Node

├── Pod A
│      10.244.1.2
│
└── Pod B
       10.244.1.3
```

Linux creates a virtual Ethernet pair (veth pair) for each Pod.

```text
Pod

↓

veth

↓

Linux Bridge

↓

Node Network Interface
```

The bridge behaves like a virtual Ethernet switch.

Packets move through the bridge exactly as they would through a physical switch.

---

## Between Nodes

Now imagine:

```text
Node A

Pod
10.244.1.5
```

wants to communicate with

```text
Node B

Pod
10.244.2.9
```

The packet follows this path:

```text
Pod

↓

veth

↓

Linux Bridge

↓

Node NIC

↓

Physical Network

↓

Node B NIC

↓

Linux Bridge

↓

veth

↓

Destination Pod
```

The CNI configures the routing rules that make this possible.

---

## Pod-to-Pod Communication

This is the simplest communication model.

Every Pod has an IP.

Applications simply connect using that IP.

```text
Frontend Pod

↓

Backend Pod
```

This is ordinary TCP/IP networking.

No Kubernetes magic is involved once the network has been established.

---

## The Problem

Pods are temporary.

Suppose

```text
Backend Pod

10.244.2.9
```

crashes.

The ReplicaSet creates a new Pod.

```text
Backend Pod

10.244.5.11
```

The IP changed.

Every application using

```text
10.244.2.9
```

is now broken.

Hardcoding Pod IPs is impossible.

We need another abstraction.

---

## Services

A **Service** provides a **stable network identity** for a changing group of Pods.

Instead of applications connecting to Pods,

they connect to a Service.

```text
Frontend

↓

Backend Service

↓

Pod A

Pod B

Pod C
```

Pods may come and go.

The Service remains.

---

## How Services Work

A Service does **not** run as a process.

It is not a proxy application.

A Service is simply a Kubernetes object describing:

* a virtual IP
* a set of Pods
* routing rules

Example:

```yaml
selector:
  app: backend

ports:
- port: 80
```

The selector tells Kubernetes

> "Find every Pod labeled `app=backend`."

---

## Endpoints

The Service continuously watches the cluster.

Whenever Pods appear or disappear,

the Endpoint list changes.

Example

```text
Service

↓

Current Endpoints

10.244.1.2

10.244.2.8

10.244.3.9
```

When Pod 2 dies,

```text
10.244.2.8
```

is removed automatically.

The application never notices.

---

## kube-proxy

Who performs the routing?

Not the Service.

The answer is **kube-proxy**.

Every Node runs kube-proxy.

Its job is to watch the API Server.

Whenever a Service changes,

kube-proxy updates Linux networking rules using **iptables**, **IPVS**, or **nftables** (depending on the configured mode and Linux distribution).

Imagine a Service:

```text
10.96.0.15
```

Packets arrive.

kube-proxy rewrites them.

```text
10.96.0.15

↓

10.244.1.7
```

Applications think they contacted the Service.

The packet actually reaches a Pod.

---

## ClusterIP

This is the default Service type.

The Service only exists inside the cluster.

```text
Client Pod

↓

ClusterIP

↓

Backend Pods
```

External users cannot access it.

---

## NodePort

Suppose outside users need access.

NodePort opens the same port on every Node.

```text
Internet

↓

Node IP:30080

↓

Service

↓

Pods
```

Any Node can receive traffic.

---

## LoadBalancer

In cloud environments,

the cloud provider creates an external load balancer.

```text
Internet

↓

Cloud Load Balancer

↓

Service

↓

Pods
```

This is usually what production applications use.

---

## DNS

Remember,

applications should never know Pod IPs.

Kubernetes includes CoreDNS.

Every Service automatically gets a DNS name.

Example

```text
database.default.svc.cluster.local
```

Applications simply connect to

```text
database
```

CoreDNS resolves the Service IP.

---

## Ingress

Imagine you have

```text
frontend

backend

api

grafana
```

Without Ingress,

each application needs its own LoadBalancer.

Very expensive.

Ingress solves this.

```text
Internet

↓

Ingress Controller

↓

frontend.example.com

↓

Frontend Service

────────────────────

api.example.com

↓

API Service

────────────────────

grafana.example.com

↓

Grafana Service
```

Ingress acts like an HTTP reverse proxy.

It routes requests based on:

* hostname
* URL path
* protocol
* TLS certificates

---

## What Is an Ingress?

An **Ingress** is **not** the software that forwards traffic.

This distinction is critical.

The **Ingress resource** is just a Kubernetes object containing routing rules.

For example:

```yaml
host: api.example.com

↓

Service: api-service
```

Those rules are stored in the API Server like any other Kubernetes object.

---

## The Ingress Controller

Something must actually enforce those rules.

That's the job of an **Ingress Controller**.

Common controllers include:

* NGINX Ingress Controller
* Traefik (the default in K3s)
* HAProxy Ingress
* Kong
* Envoy Gateway

The Ingress Controller watches the API Server for Ingress objects, translates their rules into its own configuration, and acts as the reverse proxy that receives external HTTP/HTTPS traffic.

Without an Ingress Controller, creating an Ingress resource has no effect.

---

## The Complete Networking Journey

Let's follow a request from a user's browser to an application Pod.

```text
Browser
   │
   ▼
Internet
   │
   ▼
Load Balancer (or NodePort)
   │
   ▼
Ingress Controller
   │
   ▼
Ingress Rules
   │
   ▼
Service (ClusterIP)
   │
   ▼
kube-proxy selects a backend Pod
   │
   ▼
Pod
```

If the selected Pod later crashes, Kubernetes creates a replacement with a different IP. The Service updates its list of endpoints, kube-proxy updates its routing rules, and future requests are transparently sent to the new Pod. Neither the client nor the application needs to know that anything changed.
[Kubernets Ingress Controllers](https://dev.to/godofgeeks/kubernetes-ingress-controllers-nginx-traefik-5ce1)

---
## The Networking Layers

One of the clearest ways to understand Kubernetes networking is to think of it as **four layers**, each solving a different problem:

| Layer                      | Purpose                                                                     | Main Component                                      |
| -------------------------- | --------------------------------------------------------------------------- | --------------------------------------------------- |
| **Infrastructure Network** | Connects Nodes to each other                                                | Physical network, cloud VPC, or data center network |
| **Pod Network**            | Gives every Pod a unique IP and enables Pod-to-Pod communication            | CNI plugin (Flannel, Calico, Cilium, etc.)          |
| **Service Network**        | Provides stable virtual IPs, service discovery, and load balancing for Pods | Service, EndpointSlice, kube-proxy, CoreDNS         |
| **Ingress Layer**          | Exposes HTTP/HTTPS applications to users outside the cluster                | Ingress resource + Ingress Controller               |

This layered model is the key mental framework. Once you understand **which layer solves which networking problem**, concepts like Services, DNS, Ingress, and Pod communication stop feeling like unrelated features and instead become parts of a single, coherent networking architecture.
---

# K3s

**K3s** is a **lightweight, fully compliant Kubernetes distribution** designed to make Kubernetes easier to install, operate, and run on resource-constrained environments.

It packages all the essential Kubernetes components into a single binary, reducing complexity and resource consumption while remaining compatible with standard Kubernetes APIs and tools (such as `kubectl` and Helm).

**Key characteristics:**

* Lightweight Kubernetes distribution
* Single-binary installation
* Certified Kubernetes-compatible
* Lower CPU and memory requirements
* Suitable for production, edge computing, IoT, home labs, and small to medium-sized clusters

In simple terms:

> **K3s is Kubernetes, but optimized to be smaller, simpler, and easier to manage.**

---

# K3d

**K3d** is a tool that **runs K3s clusters inside Docker containers**.

Instead of installing K3s directly on a virtual machine or physical server, K3d creates Docker containers that act as Kubernetes nodes (control plane and workers). This makes it possible to create, start, stop, and delete Kubernetes clusters in seconds.

**Key characteristics:**

* Runs K3s inside Docker
* Designed primarily for local development and testing
* Creates disposable Kubernetes clusters quickly
* Supports multiple clusters on the same machine
* Requires Docker to be installed

In simple terms:

> **K3d is not a Kubernetes distribution—it is a tool for running K3s inside Docker containers.**

---

### The Relationship Between K3s and K3d

A common source of confusion is the relationship between these two tools:

```
Kubernetes
      │
      ▼
    K3s
(Lightweight Kubernetes)
      │
      ▼
    K3d
(Runs K3s inside Docker)
```

* **Kubernetes** is the original container orchestration platform.
* **K3s** is a lightweight implementation of Kubernetes.
* **K3d** is a wrapper that launches **K3s clusters inside Docker containers**.

So, **K3d depends on K3s**, while **K3s does not depend on K3d**. You can install and run K3s directly on a Linux machine without using K3d at all.

## How K3s is lighter than Kubernetes

K3s is **not a different orchestration system**—it's still Kubernetes. The reason it's lighter is that it **removes, combines, or replaces some Kubernetes components** while keeping the Kubernetes API and behavior largely the same

A standard Kubernetes cluster consists of several control plane components running as separate processes:

| Standard Kubernetes      | Purpose                                         | K3s                                             |
| ------------------------ | ----------------------------------------------- | ----------------------------------------------- |
| API Server               | Exposes the Kubernetes API                      | ✅ Kept                                          |
| Scheduler                | Assigns Pods to Nodes                           | ✅ Kept                                          |
| Controller Manager       | Runs controllers (Deployment, ReplicaSet, etc.) | ✅ Kept                                          |
| etcd                     | Stores cluster state                            | 🔄 Optional (SQLite by default, etcd supported) |
| kubelet                  | Runs on each node                               | ✅ Kept                                          |
| kube-proxy               | Networking                                      | ✅ Kept (optional depending on configuration)    |
| Container Runtime        | Runs containers                                 | 🔄 Uses containerd by default                   |
| Cloud Controller Manager | Cloud integration                               | ❌ Removed by default (install only if needed)   |

### 1. Single binary

In standard Kubernetes, you typically install and configure several binaries:

* `kube-apiserver`
* `kube-scheduler`
* `kube-controller-manager`
* `kubelet`
* `kube-proxy`
* `etcd`

K3s packages most of these into **one executable**:

```text
k3s
 ├── API Server
 ├── Scheduler
 ├── Controller Manager
 ├── kubelet
 ├── kube-proxy
 └── containerd
```

This greatly simplifies installation and management.

---

### 2. SQLite instead of etcd (by default)

One of the biggest differences is the datastore.

**Standard Kubernetes**

```text
API Server
      │
      ▼
    etcd
```

* etcd is a distributed key-value database.
* Very reliable and scalable.
* Requires additional setup and maintenance.

**K3s**

```text
API Server
      │
      ▼
    SQLite
```

SQLite is:

* embedded
* lightweight
* requires no separate server
* ideal for a single-server cluster

For high availability, K3s can also use:

* etcd
* MySQL
* PostgreSQL

So K3s is **not limited to SQLite**.

---

### 3. Built-in container runtime

Standard Kubernetes requires you to install a container runtime, such as:

* containerd
* CRI-O

K3s includes **containerd** by default, so you don't need to install it separately.

---

### 4. Removed legacy components

K3s removes components that are no longer necessary or commonly used, including:

* Dockershim (deprecated in Kubernetes)
* Legacy cloud provider code
* Alpha and deprecated features
* Some in-tree storage drivers

Removing unused code reduces the binary size and memory footprint.

---

### 5. Built-in networking add-ons

Instead of asking you to install networking components separately, K3s comes with sensible defaults:

* **Flannel** for pod networking (default CNI)
* **CoreDNS** for service discovery
* **Traefik** as an ingress controller (can be disabled)
* **Local Path Provisioner** for dynamic local storage
* **ServiceLB** for simple load balancing

In a standard Kubernetes installation, many of these are installed separately.

---

## What stays exactly the same?

Most Kubernetes concepts and APIs are unchanged.

You still have:

* Pods
* Deployments
* Services
* ReplicaSets
* DaemonSets
* StatefulSets
* Jobs
* CronJobs
* ConfigMaps
* Secrets
* PersistentVolumes
* PersistentVolumeClaims
* Namespaces
* RBAC
* Ingress
* Helm
* kubectl

Because K3s is Kubernetes-compatible, your knowledge transfers directly.

---

## Does K3s support YAML manifests?

**Yes. Absolutely.**

A Deployment manifest that works on Kubernetes also works on K3s.

Example:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
```

Deploy it the same way:

```bash
kubectl apply -f deployment.yaml
```

You also use the same commands:

```bash
kubectl get pods
kubectl describe pod nginx
kubectl logs nginx
kubectl delete deployment nginx
```

The Kubernetes API is the same.

---

## What changes from a user's perspective?

Very little. Most differences are operational rather than functional.

| Feature        | Kubernetes            | K3s                              |
| -------------- | --------------------- | -------------------------------- |
| YAML manifests | ✅ Yes                 | ✅ Yes                            |
| `kubectl`      | ✅ Yes                 | ✅ Yes                            |
| Helm           | ✅ Yes                 | ✅ Yes                            |
| Pods           | ✅ Yes                 | ✅ Yes                            |
| Deployments    | ✅ Yes                 | ✅ Yes                            |
| Services       | ✅ Yes                 | ✅ Yes                            |
| Ingress        | Requires installation | Traefik included by default      |
| Networking     | Install a CNI         | Flannel included by default      |
| Storage        | Install a provisioner | Local Path Provisioner included  |
| Database       | etcd                  | SQLite by default, etcd optional |

### In summary

K3s is **not a simplified version of Kubernetes from a user's point of view**. It is a **lightweight packaging and distribution** of Kubernetes. It stays lightweight by:

* Bundling core components into a single binary.
* Using **SQLite** as the default datastore instead of a separate **etcd** server (while still supporting etcd for HA).
* Including **containerd** and common add-ons out of the box.
* Removing legacy, cloud-specific, and deprecated components.
* Keeping full compatibility with standard Kubernetes APIs, tools, and YAML manifests.

As a result, applications and manifests written for Kubernetes generally run on K3s without modification, making it an excellent choice for development, edge computing, and many production workloads.

# K3d

### Definition

**K3d** is a lightweight tool that creates and manages **K3s Kubernetes clusters running inside Docker containers**.

Unlike K3s, which installs Kubernetes directly on a Linux host, K3d uses Docker containers to simulate Kubernetes nodes. Each Kubernetes node (server or agent) is simply a Docker container running K3s.

In other words:

* **Kubernetes** manages containers on machines.
* **K3s** is a lightweight Kubernetes distribution.
* **K3d** is a tool that runs one or more K3s clusters inside Docker.

The architecture looks like this:

```text
+---------------------------------------+
| Host Machine                          |
|                                       |
|  Docker Engine                        |
|  ┌─────────────────────────────────┐  |
|  │ K3s Server Container            │  |
|  │ (Control Plane)                 │  |
|  └─────────────────────────────────┘  |
|                                       |
|  ┌─────────────────────────────────┐  |
|  │ K3s Agent Container             │  |
|  └─────────────────────────────────┘  |
|                                       |
|  ┌─────────────────────────────────┐  |
|  │ K3s Agent Container             │  |
|  └─────────────────────────────────┘  |
+---------------------------------------+
```

---

# Role of K3d

K3d's primary role is to **simplify the creation, management, and deletion of Kubernetes clusters for local development, testing, and CI/CD**.

Instead of installing Kubernetes on virtual machines or physical servers, K3d creates an isolated Kubernetes cluster with a single command.

For example:

```bash
k3d cluster create mycluster
```

Within a few seconds, you have:

* a Kubernetes control plane
* worker nodes
* networking
* storage
* a working kubeconfig

without manually configuring anything.

---

# Key Features

## 1. Runs Kubernetes inside Docker

Each Kubernetes node is simply a Docker container.

For example:

```
Docker
│
├── k3d-mycluster-server-0
├── k3d-mycluster-agent-0
└── k3d-mycluster-agent-1
```

This makes clusters:

* lightweight
* isolated
* easy to delete
* reproducible

---

## 2. Fast Cluster Creation

Creating a cluster typically takes only a few seconds.

```bash
k3d cluster create dev
```

Deleting it is equally simple:

```bash
k3d cluster delete dev
```

No virtual machines are required.

---

## 3. Multiple Clusters

You can run several Kubernetes clusters simultaneously.

Example:

```
dev-cluster
test-cluster
production-simulation
```

Each has its own:

* nodes
* networking
* kubeconfig context

---

## 4. Automatic kubeconfig Management

K3d automatically updates your kubeconfig.

Immediately after creating a cluster:

```bash
kubectl get nodes
```

works without additional configuration.

---

## 5. Port Mapping

You can expose Kubernetes services directly through Docker.

Example:

```bash
k3d cluster create demo \
  --port "8080:80@loadbalancer"
```

Requests to

```
localhost:8080
```

are forwarded to the Kubernetes Ingress or LoadBalancer service.

---

## 6. Local Docker Image Support

One common challenge with local Kubernetes clusters is using locally built Docker images.

K3d provides commands to import images directly into the cluster.

Example:

```bash
docker build -t myapp:v1 .
k3d image import myapp:v1
```

This avoids pushing images to a remote registry during development.

---

## 7. Built-in Load Balancer

K3d automatically creates a load balancer container.

```
Host
 │
 ▼
Load Balancer
 │
 ├── Server
 ├── Agent
 └── Agent
```

This allows Kubernetes Services of type `LoadBalancer` to work in a local environment.

---

## 8. CI/CD Friendly

Because clusters start quickly, K3d is commonly used in automated pipelines to:

* run integration tests
* validate Helm charts
* execute end-to-end tests
* test Kubernetes manifests

After testing, the cluster can simply be deleted.

---

# YAML Support

K3d **does not introduce a new application manifest format**.

It runs a standard K3s cluster, so **all regular Kubernetes YAML manifests are supported without modification**.

For example, these work exactly as they do on any Kubernetes cluster:

* Pods
* Deployments
* Services
* ConfigMaps
* Secrets
* Ingresses
* StatefulSets
* DaemonSets
* Jobs
* CronJobs
* PersistentVolumeClaims

Example:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: nginx
        image: nginx
```

Deploy it normally:

```bash
kubectl apply -f deployment.yaml
```

No changes are required because K3d runs a Kubernetes-compatible K3s cluster.

---

# K3d Configuration Files

While application manifests remain standard Kubernetes YAML, **K3d adds its own configuration file format** to describe the cluster itself.

Instead of passing many command-line options, you can define the cluster declaratively in a YAML file.

Example:

```yaml
apiVersion: k3d.io/v1alpha5
kind: Simple
metadata:
  name: demo

servers: 1
agents: 2

ports:
  - port: 8080:80
    nodeFilters:
      - loadbalancer

volumes:
  - volume: /tmp/data:/data
    nodeFilters:
      - all
```

Create the cluster with:

```bash
k3d cluster create --config k3d-config.yaml
```

This YAML config is **not a Kubernetes manifest**. It describes how **K3d should create the cluster**, including:

* the number of server and agent nodes,
* port mappings,
* volume mounts,
* Docker networks,
* registry configuration,
* environment variables, and
* other cluster-level settings.

---

# K3s Architecture

A K3s cluster is composed of two types of nodes:

```text
                K3s Cluster
                     │
        ┌────────────┴────────────┐
        │                         │
        ▼                         ▼
   Server Node(s)           Agent Node(s)
(Control Plane)             (Workers)
```

The **Server** hosts the Kubernetes control plane and manages the cluster, while **Agents** execute application workloads.

---

# Components Running on a Server (Control Plane)

A K3s server includes all control plane services.

```text
K3s Server
│
├── Kubernetes API Server
├── Scheduler
├── Controller Manager
├── Cloud Controller Manager (optional)
├── Datastore (SQLite / etcd / PostgreSQL / MySQL)
├── kubelet
├── kube-proxy
├── containerd
├── CoreDNS
├── Flannel (default)
├── Local Path Provisioner
├── ServiceLB
└── Traefik (optional)
```

### Responsibilities

| Component          | Purpose                                    |
| ------------------ | ------------------------------------------ |
| API Server         | Receives all Kubernetes API requests.      |
| Scheduler          | Assigns Pods to worker nodes.              |
| Controller Manager | Maintains the desired cluster state.       |
| Datastore          | Stores cluster configuration and metadata. |
| kubelet            | Manages Pods on the server node itself.    |
| kube-proxy         | Implements Kubernetes Service networking.  |
| containerd         | Executes containers.                       |

---

# Components Running on an Agent (Worker)

Agents execute application workloads.

```text
K3s Agent
│
├── kubelet
├── kube-proxy
└── containerd
```

Workers do **not** run:

* API Server
* Scheduler
* Controller Manager
* Datastore

Instead, they communicate with the control plane to receive Pod assignments and report their status.

---

# Node Roles

## Single-Node Cluster

One server performs both control plane and workload execution.

```text
+------------------------+
| K3s Server             |
|------------------------|
| API Server             |
| Scheduler              |
| Controller Manager     |
| kubelet                |
| containerd             |
| User Pods              |
+------------------------+
```

Installation:

```bash
curl -sfL https://get.k3s.io | sh -
```

Suitable for:

* Development
* Home labs
* Edge devices
* Small production deployments

---

## Server + Agent Cluster

A common production architecture separates management from workloads.

```text
           +---------------------+
           | Server              |
           |---------------------|
           | API Server          |
           | Scheduler           |
           | Controller Manager  |
           +----------+----------+
                      │
         ┌────────────┴────────────┐
         │                         │
+-------------------+     +-------------------+
| Agent 1           |     | Agent 2           |
| kubelet           |     | kubelet           |
| containerd        |     | containerd        |
| Application Pods  |     | Application Pods  |
+-------------------+     +-------------------+
```

---

## High Availability Cluster

Production environments typically deploy multiple server nodes.

```text
         +-----------+
         | LoadBalancer |
         +------+------+
                |
      -------------------------
      |          |            |
+-----------+ +-----------+ +-----------+
| Server 1  | | Server 2  | | Server 3  |
+-----------+ +-----------+ +-----------+
        |
    Shared Datastore
        |
----------------------------
|            |             |
Agent1      Agent2       Agent3
```

This design prevents a single control plane failure from making the cluster unavailable.

---

# Installation Options

## 1. Default Installation

```bash
curl -sfL https://get.k3s.io | sh -
```

Installs:

* SQLite
* Flannel
* CoreDNS
* Traefik
* ServiceLB
* Local Path Provisioner

---

## 2. Server Only

```bash
curl -sfL https://get.k3s.io | \
INSTALL_K3S_EXEC="server" sh -
```

Creates a control plane node.

---

## 3. Agent

```bash
curl -sfL https://get.k3s.io | \
K3S_URL=https://192.168.1.10:6443 \
K3S_TOKEN=<NODE_TOKEN> \
sh -
```

Connects an agent to an existing server.

---

# Finding the Join Token

On the server:

```bash
sudo cat /var/lib/rancher/k3s/server/node-token
```

Example:

```text
K10f3a3b91c34....
```

Agents use this token during registration.

---

# Communication Between Different Virtual Machines

Assume two VMs:

| Machine | IP            | Role   |
| ------- | ------------- | ------ |
| VM1     | 192.168.56.10 | Server |
| VM2     | 192.168.56.20 | Agent  |

## Step 1 — Install the Server

On VM1:

```bash
curl -sfL https://get.k3s.io | sh -
```

Verify:

```bash
kubectl get nodes
```

---

## Step 2 — Obtain the Token

```bash
sudo cat /var/lib/rancher/k3s/server/node-token
```

---

## Step 3 — Install the Agent

On VM2:

```bash
curl -sfL https://get.k3s.io | \
K3S_URL=https://192.168.56.10:6443 \
K3S_TOKEN=<TOKEN> \
sh -
```

---

## Step 4 — Verify

On the server:

```bash
kubectl get nodes
```

Example output:

```text
NAME      STATUS   ROLES                  VERSION
server    Ready    control-plane,master   v1.xx
agent-1   Ready    <none>                 v1.xx
```

The agent establishes a secure TLS connection to the API server using the shared node token, registers itself, and begins receiving workloads.

---

# Networking Options

K3s supports several Container Network Interface (CNI) plugins.

## Default: Flannel

Installed automatically.

```bash
--flannel-backend=vxlan
```

Available backends include:

* `vxlan` (default)
* `host-gw`
* `wireguard-native`
* `ipsec` (deprecated in recent releases)

---

## Disable Flannel

```bash
--flannel-backend=none
```

You can then install another CNI.

---

## Use Calico

Disable Flannel:

```bash
--flannel-backend=none
```

Then install Calico.

Advantages:

* Network Policies
* BGP routing
* Better scalability

---

## Use Cilium

Disable Flannel:

```bash
--flannel-backend=none
```

Install Cilium.

Advantages:

* eBPF networking
* High performance
* Advanced observability
* Network Policies

---

# Disabling Default Components

K3s allows optional components to be disabled during installation.

Disable Traefik:

```bash
--disable traefik
```

Disable ServiceLB:

```bash
--disable servicelb
```

Disable Local Storage Provisioner:

```bash
--disable local-storage
```

Disable CoreDNS:

```bash
--disable coredns
```

Disable the embedded cloud controller:

```bash
--disable-cloud-controller
```

Multiple components can be disabled together:

```bash
curl -sfL https://get.k3s.io | \
INSTALL_K3S_EXEC="server \
--disable traefik \
--disable servicelb \
--disable local-storage" \
sh -
```

---

# Replacing Default Components

One of K3s's strengths is that many bundled components can be replaced with alternatives better suited to your environment.

| Default Component      | Common Replacement           | Reason                                          |
| ---------------------- | ---------------------------- | ----------------------------------------------- |
| SQLite                 | etcd                         | High availability and distributed datastore     |
| Flannel                | Calico or Cilium             | Advanced networking and network policies        |
| Traefik                | NGINX Ingress or HAProxy     | Existing ingress standards or advanced routing  |
| ServiceLB              | MetalLB                      | Bare-metal load balancing with IP address pools |
| Local Path Provisioner | Longhorn, OpenEBS, Ceph RBD  | Persistent, replicated storage                  |
| CoreDNS                | External DNS solution (rare) | Specialized DNS requirements                    |

For example, a production cluster might disable Traefik and ServiceLB, then install **NGINX Ingress** and **MetalLB** to provide enterprise-grade ingress and load-balancing capabilities.

---

# Datastore Options

K3s supports several datastore backends:

| Datastore           | Typical Use Case                 |
| ------------------- | -------------------------------- |
| SQLite (default)    | Single-server clusters           |
| Embedded etcd       | High-availability K3s clusters   |
| External PostgreSQL | Existing database infrastructure |
| External MySQL      | Existing database infrastructure |

SQLite is recommended only for single-server deployments. For multi-server high availability, embedded etcd is the recommended option.

---

# Summary

K3s retains the core architecture of Kubernetes while simplifying installation and reducing resource requirements. A **server node** hosts the control plane components—API Server, Scheduler, Controller Manager, and the datastore—while **agent nodes** run only the services required to execute workloads, such as `kubelet`, `kube-proxy`, and `containerd`. Agents running on separate physical or virtual machines join the cluster by connecting to the server's API endpoint (`K3S_URL`) and authenticating with the shared node token (`K3S_TOKEN`).

K3s also offers significant flexibility through installation flags, allowing administrators to disable bundled components such as Traefik, Flannel, CoreDNS, ServiceLB, and the Local Path Provisioner, and replace them with alternatives like Cilium, Calico, NGINX Ingress, MetalLB, or Longhorn. This modularity enables deployments ranging from lightweight single-node development environments to highly available production clusters with customized networking, storage, and ingress solutions.

# What K3d Changes Compared to K3s

K3d does **not modify Kubernetes itself**. Instead, it changes **how K3s is deployed and managed**:

| Feature                        | K3s                        | K3d                               |
| ------------------------------ | -------------------------- | --------------------------------- |
| Runs directly on Linux         | ✔                          | ✘                                 |
| Runs inside Docker             | ✘                          | ✔                                 |
| Standard Kubernetes YAML       | ✔                          | ✔                                 |
| K3d cluster configuration YAML | ✘                          | ✔                                 |
| Fast create/delete             | Good                       | Excellent                         |
| Multiple local clusters        | Manual setup               | Built-in                          |
| Local Docker image import      | Manual                     | Built-in commands                 |
| Automatic load balancer        | Depends on setup           | Included                          |
| Best use case                  | Production, edge, home lab | Local development, testing, CI/CD |

### Summary

K3d is **not another Kubernetes distribution**. It is a **management layer for K3s** that leverages Docker to make local Kubernetes clusters easy to create, configure, and destroy. It preserves full compatibility with Kubernetes application manifests while adding its own YAML-based cluster configuration format to simplify cluster provisioning and integration with Docker-based development workflows.

# K8S,K3S YAMAL FORMAT
Here is the explanation of every single drop of this YAML.

```
# ==========================================
# APP 2: 3 Replicas (Per the subject)
# ==========================================
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app2-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: app2
  template:
    metadata:
      labels:
        app: app2
    spec:
      containers:
      - name: web
        image: nginx:alpine
        command: ["/bin/sh", "-c", "echo 'app2' > /usr/share/nginx/html/index.html && nginx -g 'daemon off;'"]
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: app2-svc
spec:
  selector:
    app: app2
  ports:
    - port: 80
      targetPort: 80
```

---

### Part 1: The Blueprint Header

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app2-deployment
```

* **`apiVersion`:** Think of this as the schema or vocabulary version. Kubernetes is constantly evolving. Some features are in alpha, some in beta, and some are stable. 
    * *What it does:* It tells the Kubernetes API Server exactly which set of rules to use to validate your YAML. 
    * *Values:* `v1` (for core things like Pods and Services), `apps/v1` (for Deployments), `networking.k8s.io/v1` (for Ingresses).
* **`kind`:** * *What it is:* What *thing* are we building? 
    * *Is it necessary?* 100% mandatory. Without it, K8s has no idea if this text is a database volume, a network route, or an application.
    * *Options:* `Pod`, `Service`, `Deployment`, `Ingress`, `Secret`, `ConfigMap`, etc.
* **`metadata` and `name`:** * *What it is:* The ID badge for this specific object. 
    * *Where you see it:* When you type `kubectl get deployments`, this is the name that appears in the list.
    * *Crucial?* Yes. If you apply this file again, K8s looks for an existing Deployment named `app2-deployment` and updates it. If you change the name, it creates a brand new, separate Deployment.

---

### Part 2: The `spec` (The Desired State)

```yaml
spec:
  replicas: 3
```

* **The Mystery of `spec`:** "Spec" stands for Specification. This is the most important concept in Kubernetes. Kubernetes works on **Declarative State**. You do not write scripts saying "start a pod, then start another." Instead, in the `spec`, you declare: *"I want the reality of the cluster to look exactly like this."* * **Its role in the Lifecycle:** A background loop inside Kubernetes constantly compares reality to your `spec`. If your `spec` says `replicas: 3`, but reality only has 2 running pods (because one crashed), K8s automatically creates a new one to make reality match the `spec`. 

---

### Part 3: The Selector and Template (The Most Critical Link)

```yaml
  selector:
    matchLabels:
      app: app2
  template:
    metadata:
      labels:
        app: app2
```

This is where people mess up most often. The `selector` and the `template` labels are a two-part system that manage the Pod lifecycle.

* **`template` (The Cookie Cutter):**
    * *What it is:* Everything under `template` is the blueprint for the *actual Pods*. When the Deployment needs to make a new Pod, it stamps one out using this exact configuration (using the Nginx image you specified).
    * *The Labels:* As it stamps out the Pod, it sticks a sticky note on it that says `app: app2`.
* **`selector` (The Radar / Search Filter):**
    * *What it is:* Deployments don't actually manage Pods directly; they manage them by searching for sticky notes. The `selector` tells the Deployment: *"Constantly scan the cluster. Count how many Pods have the sticky note `app: app2`."*
    * *Lifecycle Effects:* * **Updates:** When you change the image in the template to a new version, the Deployment creates new pods with new sticky notes, waits for them to be healthy, and then deletes the old pods with the old sticky notes.
        * **What if they don't match?** If your template label is `app: foo` but your selector is `app: bar`, the Deployment will stamp out a pod labeled "foo". It will then scan for "bar" pods, see zero, and stamp out another "foo" pod. It will do this endlessly, crashing your cluster, because the radar can't see the cookies it just cut. **They must match perfectly.**

---

### Part 4: The Service (The Internal Router)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: app2-svc
spec:
  selector:
    app: app2
  ports:
    - port: 80
      targetPort: 80
```

* **Why we need this:** Pods are mortal. They die, get deleted, and get replaced by the Deployment. Every time a new Pod is born, it gets a **random, brand-new IP address**.
* **The Problem:** The Ingress (your main router receiving traffic from the outside world) cannot keep track of a constantly shifting list of random Pod IP addresses. 
* **The Solution (The Service):** A Service gets a permanent, static IP address and a permanent DNS name inside the cluster. 
* **How it works with Ingress:**
    1. The Ingress receives a request for `app2.com`.
    2. The Ingress has a static rule: "Send `app2.com` traffic to `app2-svc`".
    3. The Service (`app2-svc`) uses its own `selector: app: app2` to constantly watch for living, healthy Pods with that sticky note. 
    4. The Service acts as an internal load balancer. It takes the traffic from the Ingress and silently forwards it to one of your 3 healthy replica Pods.

**Is it crucial?** Absolutely. Without the Service, the Ingress is pointing at a brick wall. The Service is the bridge between the static routing world of the Ingress and the chaotic, dynamic world of ephemeral Pods.

---

# Helm: The Package Manager for Kubernetes

## What is Helm?

**Helm** is the **package manager for Kubernetes**, similar to how:

* **APT** manages packages on Debian/Ubuntu.
* **YUM/DNF** manages packages on Red Hat-based systems.
* **npm** manages JavaScript packages.
* **pip** manages Python packages.

Instead of installing software directly on an operating system, Helm installs and manages **applications on a Kubernetes cluster**.

A Helm package is called a **Chart**.

---

## Why is Helm Called a Package Manager?

Deploying a Kubernetes application manually often requires creating many YAML files.

For example, deploying GitLab manually may require:

* Deployment
* StatefulSet
* Service
* ConfigMap
* Secret
* PersistentVolumeClaim
* Ingress
* ServiceAccount
* Role
* RoleBinding
* HorizontalPodAutoscaler

Instead of managing dozens (or even hundreds) of YAML manifests individually, Helm bundles all of them into **one reusable package** called a **Chart**.

Without Helm:

```text
deployment.yaml
service.yaml
secret.yaml
configmap.yaml
ingress.yaml
persistentvolumeclaim.yaml
role.yaml
rolebinding.yaml
...
```

With Helm:

```text
gitlab-chart/
```

This is why Helm is considered Kubernetes' package manager: it packages, installs, upgrades, and removes complete applications.

---

# How Helm Works

Helm follows a simple workflow:

```text
          Helm Repository
                 │
                 ▼
            Download Chart
                 │
                 ▼
      Apply values.yaml Configuration
                 │
                 ▼
      Render Kubernetes YAML Manifests
                 │
                 ▼
kubectl sends manifests to Kubernetes API
                 │
                 ▼
      Kubernetes Creates Resources
```

The important point is that **Helm does not replace Kubernetes**.

Instead, Helm **generates standard Kubernetes manifests** from templates and sends them to the Kubernetes API server.

Once installed, Kubernetes manages the application as usual.

---

# What is a Helm Chart?

A **Chart** is a reusable package containing everything required to deploy an application on Kubernetes.

A typical chart has the following structure:

```text
gitlab-chart/
│
├── Chart.yaml
├── values.yaml
├── templates/
│     ├── deployment.yaml
│     ├── service.yaml
│     ├── ingress.yaml
│     ├── configmap.yaml
│     ├── secret.yaml
│     └── pvc.yaml
│
└── charts/
```

Each file has a specific purpose:

| File          | Purpose                                                                  |
| ------------- | ------------------------------------------------------------------------ |
| `Chart.yaml`  | Metadata about the chart (name, version, dependencies).                  |
| `values.yaml` | Default configuration values that users can customize.                   |
| `templates/`  | Parameterized Kubernetes manifests that Helm renders into standard YAML. |
| `charts/`     | Dependency charts required by the application.                           |

---

# The Concept of Templates

One of Helm's most powerful features is templating.

Instead of hardcoding values, templates use variables.

For example:

```yaml
apiVersion: apps/v1
kind: Deployment

metadata:
  name: {{ .Values.app.name }}

spec:
  replicas: {{ .Values.replicas }}
```

The corresponding `values.yaml` might contain:

```yaml
app:
  name: myapp

replicas: 3
```

During installation, Helm replaces the variables:

```yaml
metadata:
  name: myapp

spec:
  replicas: 3
```

The generated manifest is then submitted to Kubernetes.

This allows the same chart to be reused across different environments simply by changing the values file.

---

# Why Helm is Ideal for GitLab

GitLab is a complex application composed of many interconnected services.

A complete GitLab deployment may include:

* Webservice
* Sidekiq
* Gitaly
* PostgreSQL
* Redis
* Registry
* GitLab Runner
* Prometheus
* Grafana
* GitLab Pages
* Cert-Manager
* NGINX Ingress
* Mailroom
* SpamCheck
* AI Gateway

Instead of writing hundreds of Kubernetes manifests manually, GitLab provides a **Helm Chart** that automatically deploys all required resources.

Administrators can enable or disable features through `values.yaml`.

For example:

```yaml
registry:
  enabled: false

gitlab-pages:
  enabled: false

grafana:
  enabled: false

prometheus:
  install: false
```

Helm renders only the resources for the enabled components, making it easy to tailor GitLab to a specific use case, such as a lightweight GitOps repository server.

---

# Basic Helm Commands

### Add a Helm repository

```bash
helm repo add gitlab https://charts.gitlab.io
```

Registers the GitLab chart repository with Helm.

---

### Update repositories

```bash
helm repo update
```

Downloads the latest chart metadata from configured repositories.

---

### Search for a chart

```bash
helm search repo gitlab
```

Lists available GitLab charts.

---

### Install a chart

```bash
helm install gitlab gitlab/gitlab
```

Creates a new Helm **release** named `gitlab` using the GitLab chart.

---

### Install with a custom configuration

```bash
helm install gitlab gitlab/gitlab \
    --values values.yaml
```

Uses your customized `values.yaml` to configure the installation.

---

### Upgrade an existing installation

```bash
helm upgrade gitlab gitlab/gitlab \
    --values values.yaml
```

Applies configuration changes while preserving the existing release.

---

### List installed releases

```bash
helm list
```

Displays all Helm-managed applications in the current namespace.

---

### Show release status

```bash
helm status gitlab
```

Displays information about the deployed GitLab release.

---

### Uninstall a release

```bash
helm uninstall gitlab
```

Removes all Kubernetes resources created by that Helm release.

---

# Helm Release

When you install a chart, Helm creates a **Release**.

A **Chart** is the application package.

A **Release** is a running instance of that package inside your Kubernetes cluster.

For example:

```text
Chart
  GitLab Chart
        │
        ├──────────────┐
        ▼              ▼
 Release: gitlab-dev   Release: gitlab-prod
```

The same chart can be installed multiple times with different configurations.

For example:

```bash
helm install gitlab-dev gitlab/gitlab \
    --values dev-values.yaml

helm install gitlab-prod gitlab/gitlab \
    --values prod-values.yaml
```

Although both releases use the same chart, each has its own configuration, Kubernetes resources, and lifecycle.

---

# Summary

Helm simplifies Kubernetes application deployment by packaging related resources into reusable **Charts**. A chart contains parameterized templates and default configuration values, allowing administrators to customize deployments through a `values.yaml` file without editing Kubernetes manifests directly. During installation, Helm combines the chart templates with the provided values, generates standard Kubernetes YAML manifests, and submits them to the Kubernetes API. This approach makes deploying complex applications like GitLab significantly easier, enabling features to be enabled, disabled, or reconfigured through a single configuration file while Helm manages installation, upgrades, rollbacks, and removal.

# GitLab Self-Managed: Architecture and Feature Customization with Helm

## What is GitLab Self-Managed?
###### using the bonus gitlab helm conf as minimalist gitlab conf installation example.
GitLab Self-Managed (also called **GitLab Self-Hosted**) is a version of GitLab that organizations deploy on their own infrastructure instead of using GitLab.com. It provides complete control over data, security policies, integrations, and resource allocation.

Unlike the hosted GitLab service, a self-managed deployment allows administrators to:

* manage the underlying infrastructure,
* customize installed components,
* integrate with internal authentication systems,
* disable unnecessary services,
* optimize resource consumption,
* scale individual services independently.

When deployed on Kubernetes, GitLab is installed using the **GitLab Helm Chart**, which packages the application into a collection of Kubernetes resources managed by Helm.

---

# Helm as the GitLab Package Manager

GitLab's Kubernetes deployment is based on **Helm**, the package manager for Kubernetes.

Helm provides:

* versioned application packages (Charts),
* dependency management,
* configuration through `values.yaml`,
* easy upgrades and rollbacks,
* selective component installation.

Instead of editing Kubernetes manifests manually, administrators customize GitLab by overriding values in the `values.yaml` configuration file.

Example:

```yaml
registry:
  enabled: false

gitlab-pages:
  enabled: false

grafana:
  enabled: false
```

Helm then renders only the resources needed for the enabled features.

This modular architecture allows GitLab to be deployed in environments ranging from small development clusters to large enterprise installations.

---
          Helm Repository
                 │
                 ▼
            Download Chart
                 │
                 ▼
      Apply values.yaml Configuration
                 │
                 ▼
      Render Kubernetes YAML Manifests
                 │
                 ▼
kubectl sends manifests to Kubernetes API
                 │
                 ▼
      Kubernetes Creates Resources

The important point is that Helm does not replace Kubernetes.

Instead, Helm generates standard Kubernetes manifests from templates and sends them to the Kubernetes API server.
# GitLab's Modular Architecture

A full GitLab installation consists of many independent services.

```
                    GitLab
                       │
 ┌─────────────────────┼─────────────────────┐
 │                     │                     │
Web UI             Git Storage         Background Jobs
(Webservice)         (Gitaly)            (Sidekiq)
 │                     │                     │
 ├──────────────┬──────┴──────────────┐
 │              │                     │
Redis       PostgreSQL           GitLab Shell
 │
 ├──────────── Optional Components ─────────────┐
 │                                              │
Container Registry      Pages      Prometheus
Grafana                 Runner     Mailroom
AI Gateway              SpamCheck  KAS
```

One advantage of the Helm chart is that many of these services are optional. If your use case does not require them, they can be disabled to reduce the deployment's complexity and resource usage.

---

# Building a Minimal GitLab

Your configuration demonstrates a **minimal GitLab deployment** intended solely for source code management and merge request workflows.

The deployment retains only the components required for:

* Git repository hosting,
* authentication,
* repository browsing,
* merge requests,
* commits,
* pushes and pulls.

Everything else is removed.

This significantly reduces memory consumption and the number of running pods.

---

# Components Kept

Your configuration preserves the core services that GitLab requires to function.

## Webservice

```yaml
gitlab:
  webservice:
```

The Webservice provides:

* GitLab web interface
* REST API
* authentication
* project management
* merge requests
* repository browser

Without it, users cannot interact with GitLab.

---

## Gitaly

```yaml
gitlab:
  gitaly:
```

Gitaly is responsible for all Git operations.

It manages:

* cloning
* pushing
* fetching
* repository storage
* Git object access

Every Git operation passes through Gitaly.

---

## Sidekiq

```yaml
gitlab:
  sidekiq:
```

Sidekiq processes background jobs such as:

* repository indexing
* email queues
* merge request processing
* notifications
* internal maintenance tasks

GitLab depends on Sidekiq even if most advanced features are disabled.

---

## GitLab Shell

```yaml
gitlab:
  gitlab-shell:
```

GitLab Shell handles:

* SSH authentication
* Git over SSH
* user authorization

Without it, SSH cloning and pushing would not work.

---

## PostgreSQL

```yaml
global:
  psql:
```

Stores:

* users
* projects
* permissions
* merge requests
* issues
* metadata

Git repositories themselves are **not** stored in PostgreSQL.

---

## Redis

```yaml
global:
  redis:
```

Redis is used for:

* caching
* session storage
* Sidekiq queues
* temporary data

GitLab expects Redis to be available.

---

# Components Disabled

Your configuration disables nearly every optional subsystem.

## Container Registry

```yaml
registry:
  enabled: false
```

Removes Docker image hosting.

Suitable when another registry (such as Harbor or Docker Hub) is used.

---

## GitLab Runner

```yaml
gitlab-runner:
  install: false
```

Disables built-in CI/CD runners.

Pipelines will not execute unless external runners are registered.

Since your deployment is only used as a Git repository watched by Argo CD, this is appropriate.

---

## GitLab Pages

```yaml
gitlab-pages:
  enabled: false
```

Removes static website hosting.

---

## Prometheus

```yaml
prometheus:
  install: false
```

Disables integrated monitoring.

Useful when monitoring is handled externally.

---

## Grafana

```yaml
grafana:
  enabled: false
```

Removes the monitoring dashboard.

---

## AI Gateway

```yaml
ai-gateway:
  enabled: false
```

Disables GitLab Duo AI features.

---

## Mailroom

```yaml
mailroom:
  enabled: false
```

Disables inbound email processing.

---

## SpamCheck

```yaml
spamcheck:
  enabled: false
```

Disables spam detection services.

---

## Git Large File Storage (LFS)

```yaml
lfs:
  enabled: false
```

Removes Git LFS support.

Repositories must contain only standard Git objects.

---

## Package Registry

```yaml
packages:
  enabled: false
```

Disables hosting of packages such as:

* Maven
* npm
* NuGet
* PyPI

---

## Uploads

```yaml
uploads:
  enabled: false
```

Disables general file uploads.

---

## Artifacts

```yaml
artifacts:
  enabled: false
```

Removes CI/CD artifact storage.

---

# Why This Configuration Works

Your deployment was designed for a GitOps workflow.

The architecture can be summarized as follows:

```
Developer
     │
     ▼
Git Push
     │
     ▼
GitLab
     │
Repository Update
     │
     ▼
Argo CD
     │
Detects Commit
     │
     ▼
Synchronizes Kubernetes Cluster
```

In this workflow:

* GitLab acts only as the Git server and collaboration platform.
* Argo CD continuously watches the repository for changes.
* Every commit to the repository triggers Argo CD to reconcile the Kubernetes cluster with the desired state stored in Git.

Because GitLab is **not responsible for building, testing, packaging, or deploying applications**, there is no need for many of its optional features, such as the integrated CI/CD runners, package registry, container registry, or monitoring stack. Disabling these components reduces resource consumption while preserving the essential Git functionality required for GitOps.

---

# Benefits of This Minimal Deployment

Compared to a default GitLab installation, this configuration provides several advantages:

* **Lower resource usage:** Fewer pods and services consume less CPU and memory.
* **Simpler operations:** There are fewer components to configure, monitor, and troubleshoot.
* **Reduced attack surface:** Unused services are not exposed, improving security.
* **Faster deployment:** Helm installs fewer resources, reducing startup time.
* **Purpose-built for GitOps:** The deployment focuses on repository management and code review while delegating deployment automation to Argo CD.

This demonstrates one of the strengths of the GitLab Helm chart: administrators can tailor a self-managed installation to the exact needs of their environment, enabling only the services required for a given workflow without compromising GitLab's core functionality.

