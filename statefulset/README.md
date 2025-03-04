```bash
export HUMANITEC_ORG=FIXME

WORKLOAD_PROFILE=default-module
```

```bash
helm template ${WORKLOAD_PROFILE} -f ${WORKLOAD_PROFILE}/sample-new-schema.yaml --debug
```

```bash
payload=$(cat ${WORKLOAD_PROFILE}/profile.json | \
  jq -rM '. + {"id": "'${WORKLOAD_PROFILE}'", "version": "1.0.0", "workload_profile_chart": { "id": "'${WORKLOAD_PROFILE}'", "version": "latest" } }')

humctl api post /orgs/${HUMANITEC_ORG}/workload-profiles \
  -d "$payload"

PROFILE_VERSION=$(cat ${WORKLOAD_PROFILE}/Chart.yaml | grep "version:" | sed 's/version://g' | tr -d '[:space:]')

tar -czf \
    "${WORKLOAD_PROFILE}-${PROFILE_VERSION}.tgz" \
    ${WORKLOAD_PROFILE}

export HUMANITEC_TOKEN=FIXME

curl "https://api.humanitec.io/orgs/${HUMANITEC_ORG}/workload-profile-chart-versions" \
  -X POST \
  -F "file=@${WORKLOAD_PROFILE}-${PROFILE_VERSION}.tgz" \
  -H "Authorization: Bearer ${HUMANITEC_TOKEN}"
```

Then, to use this custom workload profile, you'll need to use the `humanitec.score.yaml`:
```yaml
apiVersion: humanitec.org/v1b1
profile: ${HUMANITEC_ORG}/${WORKLOAD_PROFILE}
```

And when deploying the Score file, you need to use the `--extensions` param:
```bash
humctl score deploy -f score.yaml --extensions humanitec.score.yaml
```