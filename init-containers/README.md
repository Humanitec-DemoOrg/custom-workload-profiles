```bash
export HUMANITEC_ORG=FIXME
export HUMANITEC_TOKEN=FIXME

WORKLOAD_PROFILE=init-containers
```

## Test locally the Helm chart

```bash
helm template ${WORKLOAD_PROFILE} -f ${WORKLOAD_PROFILE}/sample-init-containers.yaml --debug
```

## Register the Workload Profile

```bash
payload=$(cat ${WORKLOAD_PROFILE}/profile.json | \
  jq -rM '. + {"id": "'${WORKLOAD_PROFILE}'", "version": "1.0.0", "workload_profile_chart": { "id": "'${WORKLOAD_PROFILE}'", "version": "latest" } }')

humctl api post /orgs/${HUMANITEC_ORG}/workload-profiles \
  -d "$payload"
```

## Upload a new Helm chart version for this Workload Profile

```bash
PROFILE_VERSION=$(cat ${WORKLOAD_PROFILE}/Chart.yaml | grep "version:" | sed 's/version://g' | tr -d '[:space:]')

tar -czf \
    "${WORKLOAD_PROFILE}-${PROFILE_VERSION}.tgz" \
    ${WORKLOAD_PROFILE}

curl "https://api.humanitec.io/orgs/${HUMANITEC_ORG}/workload-profile-chart-versions" \
  -X POST \
  -F "file=@${WORKLOAD_PROFILE}-${PROFILE_VERSION}.tgz" \
  -H "Authorization: Bearer ${HUMANITEC_TOKEN}"
```

## Test the Workload Profile

Then, to use this custom workload profile, you'll need to use the `humanitec.score.yaml`:
```yaml
apiVersion: humanitec.org/v1b1
profile: ${HUMANITEC_ORG}/${WORKLOAD_PROFILE}
spec:
  containers:
    test2:
      isInitContainer: true
```
And this `score.yaml` file:
```yaml
apiVersion: score.dev/v1b1
metadata:
  name: test
containers:
  test:
    image: .
  test2:
    image: .
```

And then deploy your workload:
```bash
humctl score deploy -f score.yaml --extensions humanitec.score.yaml
```