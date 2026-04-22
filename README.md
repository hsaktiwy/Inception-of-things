# Inception-of-things
42 project  (DevOp, K8s,K3s,Vagrant, etc)
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
