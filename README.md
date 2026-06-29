# 42-project:Inception of Thing  (DevOp, K8s, K3s, Vagrant, gitlab, helm, argocd)
---

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
