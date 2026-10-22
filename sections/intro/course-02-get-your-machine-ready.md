# Get Your Machine Ready

Every playground and lab in this course runs on your own machine, in a small Kubernetes cluster. A tool called `astrona` builds it for you, sets it up, grades your work and removes it again. This page gets your machine ready: first the tools you need, then the handful of `astrona` commands you will use every day, and last what to do when a start goes wrong.

## What you need

Every section needs the same set of tools. Install these before you start:

- **A container engine:** Docker or Podman. The cluster runs inside it.
- **`kind`:** runs Kubernetes inside the container engine.
- **`kubectl`:** talks to the cluster. Almost every command in this course is a `kubectl` command.
- **`helm`:** installs the Perses Operator. Each environment also installs Helm 3.22.1 for you.
- **`percli`:** the Perses command-line tool, used now and then to look at what the server holds. Each environment installs version 0.54.0.
- **`flux`:** the Flux command-line tool, for the GitOps and multi-tenancy sections. Those environments install version 2.9.6.
- **`git`:** you clone the course repository, commit and push from your own machine in the GitOps sections.
- **The astrona command-line tool.**
- **`jq`:** reads JSON, so you can pick out one field of a status or an API answer.
- **A web browser:** to open the Perses user interface through a port-forward.

The playgrounds and labs also need **outbound internet** while they start. They download Helm, `percli` and Flux from GitHub and other release sites, the operator chart, and the container images from Docker Hub, Quay and GitHub. Without outbound internet, those starts fail with errors that have nothing to do with Perses. Give your container engine about **4 GiB** of memory; the GitOps environments run Gitea and Flux next to the operator and the server.

## Reaching Perses and Gitea from your machine

The Perses server and the Git server run inside the cluster, so your machine reaches them through port-forwards. Pages that need one ask you to start it in a second terminal and leave it running:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000
```

The addresses are then `http://perses.localtest.me:8080` and `http://gitea.localtest.me:3000`. The names under `localtest.me` are public DNS names that point at `127.0.0.1`, your own machine, so the port-forwards answer them. Inside the cluster, the same names point at the two Services, so the cluster and you use the same addresses.

Some home routers block DNS answers that point at `127.0.0.1`. If a name does not resolve, add these lines to `/etc/hosts` on your machine:

```
127.0.0.1 perses.localtest.me
127.0.0.1 gitea.localtest.me
```

The Git server uses plain HTTP and the lab-only user `gitops` with the password `gitops-password`. A real Git server uses HTTPS or SSH and real credentials.

You do not have to check your tools by hand. Let `astrona` look at your machine for you:

```sh
astrona setup
```

`astrona setup` looks at what is missing, shows you each step it would take, and asks before it does anything. On macOS it can install `kind`, `kubectl` and Podman. Install `git` and `jq` yourself.

Later, you can check your machine at any time:

```sh
astrona check
```

## The commands you use every day

Once your machine is ready, you need only a handful of `astrona` commands. Each module page and lab page shows the exact command to copy, so you do not need to remember paths. This section walks through them in the order you meet them: sign in, start, pause, submit and clean up.

Labs from the course catalog are tied to your Astrona account, so you sign in first:

```sh
astrona login
```

Next you start a playground or a lab. Each module page and lab page shows the exact `astrona run` command for it. It looks like this:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS111.git -c sections/section-010/module-01/playground
```

When the cluster is ready, `kubectl` already points at it.

A chapter that sends you to a lab asks you to pause the playground first. Pausing frees your machine's memory but keeps everything you built:

```sh
astrona stop <name>
```

When the lab is done, start the playground again and carry on where you left off:

```sh
astrona start <name>
```

Inside a lab, you send your work for grading with `astrona submit`. The grader checks the live cluster. It reads the custom resources, their status conditions and the Perses API, so your fix has to actually work, not only make an error message go away. Each lab page shows the exact command:

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

You can submit as often as you like.

When you are done with a playground or a lab, remove it:

```sh
astrona destroy <name>
```

The name is the environment's name, printed by `astrona run` and shown on each page (for example `ats-111-playground-010-01`). It is not the folder path. To see what is on your machine, list it:

```sh
astrona list
```

> [!WARNING]
> **Run one environment at a time.** Each playground and lab is a whole cluster with its own operator and Perses server. Two running at once can use up your machine's memory, and it is easy to send a command to the wrong one. Pause or destroy the playground before you start the lab.

## When a start goes wrong

Sometimes a playground or lab does not start cleanly. Ask `astrona` what is wrong before you try anything else:

```sh
astrona doctor
```

It checks your machine, the lab's configuration and the running lab, and tells you how to fix what it finds.

If a start fails while it downloads something, check your network first. If the browser or `git` cannot reach a server, check that its port-forward is still running in your second terminal; a port-forward stops when the pod behind it restarts. Remember also that a lab that starts with a `Perses` resource or a dashboard that is not `Available` is often broken on purpose: the lab's task tells you when that is the case. With your machine ready and these commands at hand, you can start the first module.
