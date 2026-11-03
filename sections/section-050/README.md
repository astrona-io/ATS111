# Section 050: Operating Perses Day To Day

A platform that runs is not yet a platform that is operated. Sooner or later a server stops, someone deletes a project, or an upgrade is due. This section gives you the routines for that: seeing what the platform is doing, backing up data that has no source in Git, changing it without an outage, and finding the cause when something breaks.

This section comes last because it uses everything before it: the `Perses` resource, the dashboards and datasources, Flux and the limits on a shared server.

**Topic covered:** Operating Perses Day To Day

## What you will learn

- Reading the conditions, events and logs of the operator, the servers and the dashboards.
- Which data lives only in the Perses database, and how to export and restore it through the API.
- Changing a server through the `Perses` resource and what a rolling update does when a new pod fails.
- The order of an upgrade: backup, definitions, operator, one server, the rest.
- A troubleshooting playbook that follows the path of a request.

## The learning path

The module has a landing page, four short parts, a graded lab right after the part it tests, and a summary. The landing page starts the module's playground, with the operator, one Perses server and the namespaces `payments` and `catalog`.

### 1. Operate Perses Day To Day

1. See What The Platform Is Doing
2. Back Up And Restore Perses Data, followed by the lab **Restore A Lost Project From A Backup**
3. Change And Upgrade Safely
4. A Troubleshooting Playbook
5. Summary

## Section capstone: Recover A Broken Perses Platform

The capstone is one graded scenario that combines the whole section. A reporting server never becomes available, one dashboard never reaches it, and another is refused once it runs. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS111.git -c sections/section-050/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-050/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-111-capstone-050
```
