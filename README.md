# Config-server - incorrect health status during network partitions.

We follow the config first approach where requests to config-server is resolved via a server-side load-balancer. The load-balancer monitors the health of config-server instances by invoking the /health endpoints. However the config-server responds with incorrect health status (`{"status":"UP"}`) during network partitions - i.e. when the remote repository is not accessible.

## Steps to recreate the issue
1. Start the config server
2. Invoke the `/health` endpoint for the firs time.
   - Config server clones the repository
   - Responds with correct status - `{"status":"UP"}`
3. Simulate a network partition so that the the remote repository is not accessible
4. Invoke the `/health` endpoint again
   - Responds with incorrect status - `{"status":"UP"}`

This is because, at step 4, a `org.eclipse.jgit.errors.TransportException` is thrown, however it's swallowed and not propagated in `JGitEnvironmentRepository#fetch()` and `JGitEnvironmentRepository#merge()` methods. (`SvnKitEnvironmentRepository#update()` as well).

Is it by design? When the remote repository is not accessible, ideally the config-server status should be `DOWN` since it cannot respond with updated configurations from remote repo. Otherwise load-balancer will continue to route `/refresh` requests from microservices to config-server instances having the network partition.

I have provided a script to recreate the issue.

```
git clone https://github.com/fahimfarookme/config-server-incorrect-health-issue.git
cd config-server-incorrect-health-issue/scripts
vim set_env.sh -- and set JAVA_HOME and remote repo details.
./2-nw-partition-after-first-health.sh
```
